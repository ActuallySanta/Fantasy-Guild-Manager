## Autoload "GuildUpgrades" — owns guild building levels, upgrade costs and
## the (placeholder) gold / standing wallet, and applies upgrade effects to
## the rest of the game:
##   - Armory   -> adds STRENGTH / DEFENSE to every hero in CharacterContainer
##   - Barracks -> sets CharacterContainer.max_characters
## Other UI is kept in sync without editing it: hiring-page totals are refreshed
## after an upgrade, and character cards show boosted stats as "5 (+1)".
## It also wires itself to the "UpgrButton" on the nav bar at runtime, so no
## other scene has to be edited to open the upgrades page.
extends Node

signal upgrades_changed
signal resources_changed
signal building_upgraded(building: int, new_level: int)

enum Building { OFFICE, TRAINING_YARD, HOSPITAL, ARMORY, BARRACKS }

enum UpgradeStatus { READY, STANDING_TOO_LOW, NOT_ENOUGH_GOLD, MAX_LEVEL, NOT_IMPLEMENTED }

const MAX_LEVEL := 5
const UPGRADES_PAGE_PATH := "res://Scenes/UI/Upgrades/upgrades_page.tscn"
const ARMORY_META := "armory_bonus_applied"
const HOOKED_META := "guild_upgrades_hooked"

## Display info for each building. "implemented" = its effect actually does
## something in the game yet (prototype: Armory + Barracks only).
const BUILDING_INFO := {
	Building.OFFICE: { "name": "Office", "implemented": false, "color": Color(0.96, 0.73, 0.23) },
	Building.TRAINING_YARD: { "name": "Training Yard", "implemented": false, "color": Color(0.89, 0.38, 0.30) },
	Building.HOSPITAL: { "name": "Hospital", "implemented": false, "color": Color(0.94, 0.60, 0.24) },
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
const BARRACKS_RECRUITS_PER_DAY := [1, 1, 2, 2, 3]

# ---- Costs (PLACEHOLDER numbers — tune these) ----
## Gold to reach level N is UPGRADE_GOLD_COST[N - 1]. Level 1 is free (owned at start).
const UPGRADE_GOLD_COST := [0, 150, 300, 500, 800]
## Standing needed to buy level N.
const UPGRADE_STANDING_REQ := [0, 1, 2, 3, 4]

# ---- Placeholder economy (no gold/standing system exists yet) ----
const STARTING_GOLD := 600
const STARTING_STANDING := 1
## Write gold/standing into the top bar's GoldLabel / StanLabel.
const DRIVE_TOP_BAR_LABELS := true
## Show the +gold / +standing test buttons on the upgrades page.
const SHOW_DEBUG_BUTTONS := true

var gold: int = STARTING_GOLD
var standing: int = STARTING_STANDING
var levels: Dictionary = {}

var _page: Control
var _hidden_content: Array[CanvasItem] = []
var _gold_label: Label
var _standing_label: Label
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
			return "Every hero: Strength +%d, Defense +%d" % [bonus.x, bonus.y]
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

	building_upgraded.emit(building, levels[building])
	resources_changed.emit()
	upgrades_changed.emit()
	_update_top_bar()
	return true


func add_gold(amount: int) -> void:
	gold = maxi(gold + amount, 0)
	resources_changed.emit()
	_update_top_bar()


func add_standing(amount: int) -> void:
	standing = maxi(standing + amount, 0)
	resources_changed.emit()
	_update_top_bar()


## Back to a fresh guild (all level 1, starting wallet). Armory bonus is
## removed from heroes again by the re-sync.
func reset() -> void:
	for b in Building.values():
		levels[b] = 1
	gold = STARTING_GOLD
	standing = STARTING_STANDING
	_apply_effects()
	resources_changed.emit()
	upgrades_changed.emit()
	_update_top_bar()


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


## "Strength: 5 (+1)" — base stat with the upgrade bonus shown separately.
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
	card.strength_label.text = format_stat(character, GuildCharacter.StatType.STRENGTH, "Strength")
	card.defense_label.text = format_stat(character, GuildCharacter.StatType.DEFENSE, "Defense")


# ---------------------------------------------------------------- nav bar hookup

func _on_node_added(node: Node) -> void:
	if node is Button and _is_nav_button(node):
		if node.has_meta(HOOKED_META):
			return
		node.set_meta(HOOKED_META, true)
		if node.name == "UpgrButton":
			node.pressed.connect(open_page.bind(node))
		else:
			# Any other nav tab closes the upgrades page.
			node.pressed.connect(close_page)
	elif node is CharacterUICard:
		# Runs after the card's own _ready has filled in its labels.
		_patch_character_card.call_deferred(node)
	elif node is Label and DRIVE_TOP_BAR_LABELS:
		if node.name == "GoldLabel":
			_gold_label = node
			_update_top_bar.call_deferred()
		elif node.name == "StanLabel":
			_standing_label = node
			_update_top_bar.call_deferred()


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
	_hide_other_content()
	_page.move_to_front()
	_page.show()


## The page lives inside the home screen's "Content" panel (same spot as the
## Characters page) so the top bar and nav bar stay visible. Falls back to the
## scene root if no Content panel is found.
func _get_page_host(from_button: Node) -> Node:
	var root: Node = get_tree().current_scene
	if from_button != null and from_button.owner != null:
		root = from_button.owner
	var content: Node = root.find_child("Content", true, false)
	return content if content != null else root


func close_page() -> void:
	if _page != null and is_instance_valid(_page):
		_page.hide()
	_restore_other_content()


## The page has no background of its own (the Content panel's blue shows
## through), so hide whatever else is showing in the panel while it's open
## and bring it back when the page closes.
func _hide_other_content() -> void:
	var host := _page.get_parent()
	if host == null or host == get_tree().current_scene:
		return
	for child in host.get_children():
		if child != _page and child is CanvasItem and child.visible and not _hidden_content.has(child):
			_hidden_content.append(child)
			child.hide()


func _restore_other_content() -> void:
	for node in _hidden_content:
		if is_instance_valid(node):
			node.show()
	_hidden_content.clear()


func _update_top_bar() -> void:
	if not DRIVE_TOP_BAR_LABELS:
		return
	if _gold_label != null and is_instance_valid(_gold_label):
		_gold_label.text = "Gold: %d" % gold
	if _standing_label != null and is_instance_valid(_standing_label):
		_standing_label.text = "Standing: %d" % standing
