## Autoload "GuildUpgrades" — owns guild building levels, upgrade costs and
## the gold / standing wallet, and applies upgrade effects to
## the rest of the game:
##   - Armory   -> adds STRENGTH / DEFENSE to every hero in CharacterContainer
##   - Barracks -> sets CharacterContainer.max_characters
##   - Training Yard -> heroes in a training slot gain a stat each night
##   - Hospital -> injuries heal over the nights, faster for patients
##     (run_night() applies both; the MobileHall UI calls it at End Day)
## Other UI is kept in sync without editing it: hiring-page totals are refreshed
## after an upgrade, and character cards show boosted stats as "5 (+1)".
## It also wires itself to the "UpgrButton" on the nav bar at runtime, so no
## other scene has to be edited to open the upgrades page. The Characters tab
## ("CharButton") gets the same tab behaviour: it hides the quest list while
## open and is closed by the other nav tabs (the page has no close button).
extends Node

signal upgrades_changed
signal resources_changed
## Someone started / stopped training, was admitted / discharged, or the night ran.
signal home_changed

enum Building { OFFICE, TRAINING_YARD, HOSPITAL, ARMORY, BARRACKS }

enum UpgradeStatus { READY, STANDING_TOO_LOW, NOT_ENOUGH_GOLD, MAX_LEVEL, NOT_IMPLEMENTED }

const MAX_LEVEL := 5
const UPGRADES_PAGE_PATH := "res://Scenes/UI/Upgrades/upgrades_page.tscn"
const ARMORY_META := "armory_bonus_applied"
const HOOKED_META := "guild_upgrades_hooked"
const CHARACTER_PAGE_NAME := "Guild Character Page"

## Display info for each building. "implemented" = its effect actually does
## something in the game yet.
const BUILDING_INFO := {
	Building.OFFICE: { "name": "Office", "implemented": false, "color": Color(0.96, 0.73, 0.23) },
	Building.TRAINING_YARD: { "name": "Training Yard", "implemented": true, "color": Color(0.89, 0.38, 0.30) },
	Building.HOSPITAL: { "name": "Hospital", "implemented": true, "color": Color(0.94, 0.60, 0.24) },
	Building.ARMORY: { "name": "Armory", "implemented": true, "color": Color(0.31, 0.59, 0.85) },
	Building.BARRACKS: { "name": "Barracks", "implemented": true, "color": Color(0.44, 0.75, 0.29) },
}

# ---- Level tables (index 0 = level 1) — from the Guild Upgrade design doc ----
const OFFICE_QUESTS_PER_DAY := [3, 4, 5, 6, 7]
const OFFICE_REROLLS_PER_DAY := [0, 1, 1, 2, 3]
const OFFICE_HIGHEST_RANK := ["D", "C", "B", "A", "S"]
const TRAINING_SLOTS := [1, 2, 3, 4, 5]
const TRAINING_STAT_GAIN := [1, 1, 2, 2, 3]
const HOSPITAL_RECOVERY_REDUCTION := [2, 2, 3, 4, 4]
## x = STRENGTH (ATK) bonus, y = DEFENSE bonus
const ARMORY_BONUS := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2), Vector2i(3, 3)]
const BARRACKS_MAX_HEROES := [4, 6, 8, 10, 12]

# ---- Costs (PLACEHOLDER numbers — tune these) ----
## Gold to reach level N is UPGRADE_GOLD_COST[N - 1]. Level 1 is free (owned at start).
const UPGRADE_GOLD_COST := [0, 150, 300, 500, 800]
## Standing needed to buy level N.
const UPGRADE_STANDING_REQ := [0, 1, 2, 3, 4]

# ---- Economy: the wallet a new run starts with, and the standing floor for recruits ----
const STARTING_GOLD := 600
const STARTING_STANDING := 1
const MINIMUM_STANDING := -10

## Show the +gold / +standing test buttons on the upgrades page.
const SHOW_DEBUG_BUTTONS := true

# ---- Training Yard / Hospital tuning
## Nights at home to heal one injury level, indexed by GuildCharacter.InjuryLevel
## (Healthy, Sore, Hurt, Gravely hurt, Dead).
const HOME_HEAL_NIGHTS := [0, 2, 4, 6, 0]
## A Hospital bed never takes fewer nights than this per level.
const HOSPITAL_MIN_NIGHTS := 1
## Worst injury a hero can still train with.
const TRAINING_MAX_INJURY := GuildCharacter.InjuryLevel.SORE
## Hospital level that unlocks reviving, and how many revives a run gets.
const REVIVE_LEVEL := 5
const REVIVES_PER_RUN := 1
## Character metadata: Vector2i(injury level, nights spent healing it).
const RECOVERY_META := "recovery_nights"

var gold: int = STARTING_GOLD
var standing: int = STARTING_STANDING
var levels: Dictionary = { }
## Heroes in a training slot -> the GuildCharacter.StatType they drill.
var training: Dictionary = { }
## Heroes in a Hospital bed.
var patients: Array[GuildCharacter] = []
## Revives used this run (Hospital level 5).
var revives_used := 0

var _page: Control
var _character_page: Control
var _hidden_content: Array[CanvasItem] = []
var _last_character_count := -1


func _ready() -> void:
	for b in Building.values():
		levels[b] = 1

	# Hook nodes added later, and (deferred) everything already in the tree,
	# since the main scene may be in the tree before this autoload is ready.
	get_tree().node_added.connect(_on_node_added)
	_scan_tree.call_deferred(get_tree().root)
	CharacterContainer.on_character_added.connect(sync_characters)
	_apply_effects()


func _process(_delta: float) -> void:
	# Heroes can join without on_character_added firing (generate_new_character),
	# so also re-sync whenever the roster size changes.
	var count := CharacterContainer.active_characters.size()
	if count != _last_character_count:
		_last_character_count = count
		sync_characters()

# ---------------------------------------------------------------- queries


func get_level(building: int) -> int:
	return levels.get(building, 1)


func get_building_name(building: int) -> String:
	return BUILDING_INFO[building]["name"]


func get_building_color(building: int) -> Color:
	return BUILDING_INFO[building]["color"]


func is_implemented(building: int) -> bool:
	return BUILDING_INFO[building]["implemented"]


func is_max_level(building: int) -> bool:
	return get_level(building) >= MAX_LEVEL


func get_next_gold_cost(building: int) -> int:
	if is_max_level(building):
		return 0
	return UPGRADE_GOLD_COST[get_level(building)]


func get_next_standing_req(building: int) -> int:
	if is_max_level(building):
		return 0
	return UPGRADE_STANDING_REQ[get_level(building)]


func get_upgrade_status(building: int) -> UpgradeStatus:
	if not is_implemented(building):
		return UpgradeStatus.NOT_IMPLEMENTED
	if is_max_level(building):
		return UpgradeStatus.MAX_LEVEL
	# Standing first: more gold can't fix it.
	if standing < get_next_standing_req(building):
		return UpgradeStatus.STANDING_TOO_LOW
	if gold < get_next_gold_cost(building):
		return UpgradeStatus.NOT_ENOUGH_GOLD
	return UpgradeStatus.READY


## Short description of what a building does at a given level.
func get_effect_text(building: int, level: int) -> String:
	var i := clampi(level, 1, MAX_LEVEL) - 1
	match building:
		Building.OFFICE:
			var text := "%d quests/day, %d reroll(s), up to rank %s" % [OFFICE_QUESTS_PER_DAY[i], OFFICE_REROLLS_PER_DAY[i], OFFICE_HIGHEST_RANK[i]]
			if level >= MAX_LEVEL:
				text += " + Priority Quest"
			return text
		Building.TRAINING_YARD:
			return "%d training slots, +%d stat/day" % [TRAINING_SLOTS[i], TRAINING_STAT_GAIN[i]]
		Building.HOSPITAL:
			var text := "Injuries heal %d days faster" % HOSPITAL_RECOVERY_REDUCTION[i]
			if level >= MAX_LEVEL:
				text += " + revive 1 hero"
			return text
		Building.ARMORY:
			var bonus: Vector2i = ARMORY_BONUS[i]
			return "Every hero: Power +%d, Defense +%d" % [bonus.x, bonus.y]
		Building.BARRACKS:
			return "Room for %d heroes" % BARRACKS_MAX_HEROES[i]
	return ""


func get_armory_bonus() -> Vector2i:
	return ARMORY_BONUS[get_level(Building.ARMORY) - 1]


func get_max_heroes() -> int:
	return BARRACKS_MAX_HEROES[get_level(Building.BARRACKS) - 1]

# ---------------------------------------------------------------- actions


func try_upgrade(building: int) -> bool:
	if get_upgrade_status(building) != UpgradeStatus.READY:
		return false

	gold -= get_next_gold_cost(building)
	levels[building] = get_level(building) + 1
	_apply_effects()

	resources_changed.emit()
	upgrades_changed.emit()
	return true


func add_gold(amount: int) -> void:
	gold = maxi(gold + amount, 0)
	resources_changed.emit()


func add_standing(amount: int) -> void:
	standing += amount
	resources_changed.emit()


func reduce_standing(amount: int) -> void:
	standing -= amount
	resources_changed.emit()


## Back to a fresh guild (all level 1, starting wallet). Armory bonus is
## removed from heroes again by the re-sync.
func reset() -> void:
	for b in Building.values():
		levels[b] = 1
	gold = STARTING_GOLD
	standing = STARTING_STANDING
	training.clear()
	patients.clear()
	revives_used = 0
	_apply_effects()
	home_changed.emit()
	resources_changed.emit()
	upgrades_changed.emit()

# ---------------------------------------------------------------- training yard
# Heroes in a training slot stay home and drill one stat; it goes up by
# TRAINING_STAT_GAIN when the day ends (run_night). Slots stay filled day to
# day until the player changes them.


func get_training_slots() -> int:
	return TRAINING_SLOTS[get_level(Building.TRAINING_YARD) - 1]


func get_training_gain() -> int:
	return TRAINING_STAT_GAIN[get_level(Building.TRAINING_YARD) - 1]


func is_training(character: GuildCharacter) -> bool:
	return training.has(character)


## The GuildCharacter.StatType a hero is drilling, or -1 if they aren't training.
func get_training_stat(character: GuildCharacter) -> int:
	return training.get(character, -1)


func has_free_training_slot() -> bool:
	return training.size() < get_training_slots()


## Alive, no worse than Sore, and not in the Hospital.
func can_train(character: GuildCharacter) -> bool:
	return character.injury_level <= TRAINING_MAX_INJURY and not is_patient(character)


## Put a hero in a slot, or change the stat they drill.
## False when they can't train or every slot is taken.
func set_training(character: GuildCharacter, stat: int) -> bool:
	if not can_train(character):
		return false
	if not is_training(character) and not has_free_training_slot():
		return false
	training[character] = stat
	home_changed.emit()
	return true


func stop_training(character: GuildCharacter) -> void:
	if training.erase(character):
		home_changed.emit()

# ---------------------------------------------------------------- hospital
# Injuries heal one level at a time. At home a level takes HOME_HEAL_NIGHTS;
# in the Hospital it takes HOSPITAL_RECOVERY_REDUCTION fewer (never below
# HOSPITAL_MIN_NIGHTS). Patients can't go on quests. Healthy patients are sent
# home automatically. Progress on the current level is kept as metadata.


func get_hospital_reduction() -> int:
	return HOSPITAL_RECOVERY_REDUCTION[get_level(Building.HOSPITAL) - 1]


func is_patient(character: GuildCharacter) -> bool:
	return patients.has(character)


## Hurt but alive (Sore, Hurt or Gravely hurt).
func needs_care(character: GuildCharacter) -> bool:
	return character.injury_level > GuildCharacter.InjuryLevel.HEALTHY \
			and character.injury_level < GuildCharacter.InjuryLevel.DEAD


## Nights it takes to heal one level down from `level`.
func get_heal_nights(level: int, in_hospital: bool) -> int:
	var nights: int = HOME_HEAL_NIGHTS[clampi(level, 0, HOME_HEAL_NIGHTS.size() - 1)]
	if in_hospital and nights > 0:
		nights = maxi(nights - get_hospital_reduction(), HOSPITAL_MIN_NIGHTS)
	return nights


## Nights until a hero is Healthy again, counting progress already made.
func get_nights_until_healthy(character: GuildCharacter, in_hospital: bool) -> int:
	if not needs_care(character):
		return 0
	var total := 0
	for level in range(int(character.injury_level), 0, -1):
		total += get_heal_nights(level, in_hospital)
	return maxi(total - _recovery_progress(character), 1)


func admit(character: GuildCharacter) -> bool:
	if not needs_care(character) or is_patient(character):
		return false
	patients.append(character)
	training.erase(character)
	home_changed.emit()
	return true


func discharge(character: GuildCharacter) -> void:
	if patients.has(character):
		patients.erase(character)
		home_changed.emit()


## Hospital level 5: bring back one fallen hero per run (Gravely hurt, in a bed).
func can_revive() -> bool:
	return get_level(Building.HOSPITAL) >= REVIVE_LEVEL and revives_used < REVIVES_PER_RUN


func revive(character: GuildCharacter) -> bool:
	if not can_revive() or character.injury_level < GuildCharacter.InjuryLevel.DEAD:
		return false
	character.injury_level = GuildCharacter.InjuryLevel.GRAVELY_INJURED
	character.set_meta(RECOVERY_META, Vector2i(GuildCharacter.InjuryLevel.GRAVELY_INJURED, 0))
	revives_used += 1
	patients.append(character)
	home_changed.emit()
	return true

# ---------------------------------------------------------------- the night


## Tonight at home: heroes in training gain their stat and injured heroes heal.
## Call once when the day ends, before the quests are played out (so nobody
## heals the same night they get hurt). Returns what happened, for the report:
##   {trained: [{character, stat, gain}],
##    healed:  [{character, from, to, in_hospital}]}
func run_night() -> Dictionary:
	_forget_missing_heroes()

	var trained := []
	var gain := get_training_gain()
	for character: GuildCharacter in training:
		var stat: int = training[character]
		character.stats[stat] += gain
		character.total_points += gain
		trained.append({"character": character, "stat": stat, "gain": gain})

	var healed := []
	for character in CharacterContainer.active_characters:
		if character == null or not needs_care(character):
			continue
		var in_hospital := is_patient(character)
		var nights := _recovery_progress(character) + 1
		var level := int(character.injury_level)
		if nights >= get_heal_nights(level, in_hospital):
			character.injury_level = (level - 1) as GuildCharacter.InjuryLevel
			nights = 0
			healed.append({"character": character, "from": level, "to": level - 1, "in_hospital": in_hospital})
		character.set_meta(RECOVERY_META, Vector2i(int(character.injury_level), nights))

	# healed patients go home
	for character in patients.duplicate():
		if not needs_care(character):
			patients.erase(character)

	home_changed.emit()
	return {"trained": trained, "healed": healed}


## Nights already spent healing the hero's current level. Stored with the
## level it belongs to, so a new injury starts the count again.
func _recovery_progress(character: GuildCharacter) -> int:
	var progress: Vector2i = character.get_meta(RECOVERY_META, Vector2i(-1, 0))
	return progress.y if progress.x == int(character.injury_level) else 0


## Drop heroes who left the roster, died, or got too hurt for their slot.
func _forget_missing_heroes() -> void:
	var roster: Array = CharacterContainer.active_characters
	for character: GuildCharacter in training.keys():
		if not roster.has(character) or not can_train(character):
			training.erase(character)
	for character in patients.duplicate():
		if not roster.has(character) or not needs_care(character):
			patients.erase(character)

# ---------------------------------------------------------------- effects


func _apply_effects() -> void:
	CharacterContainer.max_characters = get_max_heroes()
	sync_characters()
	_refresh_other_ui()


## Re-runs other pages' own refresh functions that depend on upgrade effects,
## e.g. the hiring page's "TOTAL: x / max" label.
func _refresh_other_ui() -> void:
	if not is_inside_tree():
		return
	_call_on_tree(get_tree().root, "update_character_total")


func _call_on_tree(node: Node, method: StringName) -> void:
	if node != self and node.is_node_ready() and node.has_method(method):
		node.call(method)
	for child in node.get_children():
		_call_on_tree(child, method)


## Makes every hero's stats include exactly the current Armory bonus. The amount
## already given is stored as metadata on the character, so this is safe to
## call any number of times.
func sync_characters() -> void:
	var bonus := get_armory_bonus()
	for character in CharacterContainer.active_characters:
		if character == null:
			continue
		var applied: Vector2i = character.get_meta(ARMORY_META, Vector2i.ZERO)
		var delta := bonus - applied
		if delta == Vector2i.ZERO:
			continue
		character.stats[GuildCharacter.StatType.STRENGTH] += delta.x
		character.stats[GuildCharacter.StatType.DEFENSE] += delta.y
		character.set_meta(ARMORY_META, bonus)


## How much of a hero's stat comes from upgrades (currently just the Armory).
func get_stat_bonus(character: GuildCharacter, stat: GuildCharacter.StatType) -> int:
	var applied: Vector2i = character.get_meta(ARMORY_META, Vector2i.ZERO)
	match stat:
		GuildCharacter.StatType.STRENGTH:
			return applied.x
		GuildCharacter.StatType.DEFENSE:
			return applied.y
	return 0


## "Power: 5 (+1)" — base stat with the upgrade bonus shown separately.
## character.stats already includes the bonus, so quests use the boosted value.
func format_stat(character: GuildCharacter, stat: GuildCharacter.StatType, label: String) -> String:
	var total: int = character.stats[stat]
	var bonus := get_stat_bonus(character, stat)
	if bonus == 0:
		return "%s: %d" % [label, total]
	return "%s: %d (+%d)" % [label, total - bonus, bonus]


func _patch_character_card(card: Node) -> void:
	if not is_instance_valid(card) or card.loaded_character == null:
		return
	var character: GuildCharacter = card.loaded_character
	sync_characters()
	card.strength_label.text = format_stat(character, GuildCharacter.StatType.STRENGTH, "Power")
	card.defense_label.text = format_stat(character, GuildCharacter.StatType.DEFENSE, "Defense")

# ---------------------------------------------------------------- nav bar hookup


func _on_node_added(node: Node) -> void:
	if node is Button and _is_nav_button(node):
		if node.has_meta(HOOKED_META):
			return
		node.set_meta(HOOKED_META, true)
		if node.name == "UpgrButton":
			node.pressed.connect(open_page.bind(node))
		elif node.name == "CharButton":
			node.pressed.connect(open_character_page.bind(node))
		else:
			# Any other nav tab closes the upgrades / characters pages.
			node.pressed.connect(close_page)
	elif node is CharacterUICard:
		# Runs after the card's own _ready has filled in its labels.
		_patch_character_card.call_deferred(node)


func _scan_tree(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_scan_tree(child)


func _is_nav_button(node: Node) -> bool:
	var parent := node.get_parent()
	return parent != null and parent.get_parent() != null and parent.get_parent().name == "NavBar"


func open_page(from_button: Node = null) -> void:
	if _page == null or not is_instance_valid(_page):
		_page = load(UPGRADES_PAGE_PATH).instantiate()
		_get_page_host(from_button).add_child(_page)
	_show_tab(_page)


## The page lives inside the home screen's "Content" panel (same spot as the
## Characters page) so the top bar and nav bar stay visible. Falls back to the
## scene root if no Content panel is found.
func _get_page_host(from_button: Node) -> Node:
	var root: Node = get_tree().current_scene
	if from_button != null and from_button.owner != null:
		root = from_button.owner
	var content: Node = root.find_child("Content", true, false)
	return content if content != null else root


## Characters tab. The home screen's own CharButton handler also shows the
## page; this just makes it behave like a tab (hides the quest list / upgrades).
func open_character_page(from_button: Node = null) -> void:
	if _character_page == null or not is_instance_valid(_character_page):
		var root: Node = get_tree().current_scene
		if from_button != null and from_button.owner != null:
			root = from_button.owner
		_character_page = root.find_child(CHARACTER_PAGE_NAME, true, false) as Control
	if _character_page != null:
		_show_tab(_character_page)


func close_page() -> void:
	for tab in [_page, _character_page]:
		if tab != null and is_instance_valid(tab):
			tab.hide()
	_restore_other_content()


func _is_tab_page(node: Node) -> bool:
	return node != null and (node == _page or node == _character_page)


## Tab pages have no background of their own (the Content panel's blue shows
## through), so hide whatever else is showing in the panel while one is open
## and bring it back when the tabs close. Other tab pages are just hidden,
## not remembered, so switching tabs never brings the old one back.
func _show_tab(tab: Control) -> void:
	var host := tab.get_parent()
	if host != null and host != get_tree().current_scene:
		for child in host.get_children():
			if child == tab or not (child is CanvasItem) or not child.visible:
				continue
			if _is_tab_page(child):
				child.hide()
			elif not _hidden_content.has(child):
				_hidden_content.append(child)
				child.hide()
	tab.move_to_front()
	tab.show()


func _restore_other_content() -> void:
	for node in _hidden_content:
		if is_instance_valid(node):
			node.show()
	_hidden_content.clear()
