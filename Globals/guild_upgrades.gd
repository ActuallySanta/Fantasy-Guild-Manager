## Autoload "GuildUpgrades" — owns guild building levels, upgrade costs and
## the gold / standing wallet, and applies upgrade effects to
## the rest of the game:
##   - Armory   -> adds STRENGTH / DEFENSE to every hero in CharacterContainer
##   - Barracks -> sets CharacterContainer.max_characters
##   - Training Yard -> heroes in a training slot gain a stat each night
##   - Hospital -> injuries heal over the nights, faster for patients
##     (run_night() applies both; the MobileHall UI calls it at End Day)
extends Node

signal upgrades_changed
signal resources_changed
## Someone started / stopped training, was admitted / discharged, or the night ran.
signal home_changed

enum Building { OFFICE, TRAINING_YARD, HOSPITAL, ARMORY, BARRACKS }

enum UpgradeStatus { READY, STANDING_TOO_LOW, NOT_ENOUGH_GOLD, MAX_LEVEL, NOT_IMPLEMENTED }

const MAX_LEVEL := 5
const ARMORY_META := "armory_bonus_applied"

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
## Injury stages (Sore, Hurt, Gravely hurt) a patient heals each night.
## Level 3+ heals 2 stages a night, so Gravely hurt takes 2 nights.
const HOSPITAL_STAGES_PER_NIGHT := [1, 1, 2, 2, 2]
## x = STRENGTH (ATK) bonus, y = DEFENSE bonus
const ARMORY_BONUS := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2), Vector2i(3, 3)]
const BARRACKS_MAX_HEROES := [4, 6, 8, 10, 12]

# ---- Pacing: when buildings open and what they cost ----
## The day the Guild tab (building upgrades, Training Yard, Hospital) opens:
## the Bone Drake's day (HallMain.MILESTONE_DAY). Locked before this
## whether or not the tutorial is on (HallMain.is_tab_locked); Pip's Guild
## walkthrough runs on this day (OverlayTutorial).
const UNLOCK_DAY := 10
## Gold to reach level N is UPGRADE_GOLD_COST[N - 1]. Level 1 is free (owned at start).
## Tuned so an average run maxes every implemented building (4 of them; the
## Office isn't yet) around Day 40, and flawless play no sooner than about
## Day 30: 25,000 gold per building, 100,000 in all.
## Why gold sets the earliest day: the board holds at most 5 quests a day
## (HallRules.QUESTS_PER_DAY_LATE) and pay tops out at rank S, so income has a
## ceiling. Winning every quest on the board from Day 1 earns ~100k by the
## start of Day 30 (before hiring), so nobody can buy everything sooner.
## Income compounds: wins raise standing by their rank + 1, standing raises the
## quest rank (HallRules.standing_rank_for), and rank raises the gold. A lost
## quest pays no standing and only its bonus gold, so the win rate matters twice.
## Modelled (Nov 2026) for an average player who denies ~15% of quests and
## wins 80-85% of the rest: ~100-106k earned by Day 40 after ~150 gold a day on
## hires and gear, maxing out on Day 40-42. The old 45k total was maxed by
## Day 25-27 in the AI playtests (Docs/playtests/2026-11-20-run.md).
## Each level costs ~1.7-2x the last. If the Office gets implemented, the
## total rises by a quarter: retune.
const UPGRADE_GOLD_COST := [0, 2000, 4000, 7000, 12000]
## Standing needed to buy level N. Gold (about 100k in all) sets the pace; these
## gates must never be what holds an average run back. They were [0, 10, 40, 100,
## 200], but failures and denials now cost standing, and in playtest round 1
## (Docs/playtests, seed 4417) average and cautious players peaked at only 45-133
## standing, so buildings stalled at level 2-3 and the Barracks cap of 6 made the
## 8-slot Demon King impossible to field. Now low enough that a steady run clears
## each gate as soon as it can pay for the level.
const UPGRADE_STANDING_REQ := [0, 5, 15, 30, 50]

# ---- Economy: the wallet a new run starts with, and the standing floor for recruits ----
const STARTING_GOLD := 0
const STARTING_STANDING := 1
const MINIMUM_STANDING := -10

## Show the debug tools: the Menu's Debug tools button (overlay_debug.gd) and
## the old prototype upgrades page's +gold / +standing test buttons.
const SHOW_DEBUG_BUTTONS := true

# ---- Training Yard / Hospital tuning
## Nights at home to heal one injury level, indexed by GuildCharacter.InjuryLevel
## (Healthy, Sore, Hurt, Gravely hurt, Dead).
const HOME_HEAL_NIGHTS := [0, 2, 4, 6, 0]
## Worst injury a hero can still train with.
const TRAINING_MAX_INJURY := GuildCharacter.InjuryLevel.SORE
## Hospital level that unlocks reviving, and how many revives a run gets.
const REVIVE_LEVEL := 5
const REVIVES_PER_RUN := 1
## Gold a Hospital bed costs per night, multiplied by the guild's standing rank
## plus one (so 20 at rank F, 120 at rank S). Charged for every patient at End
## Day; discharging a hero beforehand stops the charge.
const HOSPITAL_FEE_PER_NIGHT := 20
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

var _last_character_count := -1


func _ready() -> void:
	for b in Building.values():
		levels[b] = 1

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
			var stages: int = HOSPITAL_STAGES_PER_NIGHT[i]
			var text := "Heals %d injury stage%s per night" % [stages, "" if stages == 1 else "s"]
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


## Debug tools (HallDebug.max_buildings): every implemented building jumps to
## MAX_LEVEL for free, and its effects (Barracks beds, Armory gear) apply now.
func max_all_buildings() -> void:
	for building in Building.values():
		if is_implemented(building):
			levels[building] = MAX_LEVEL
	_apply_effects()
	resources_changed.emit()
	upgrades_changed.emit()


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
# At home injuries heal one level at a time, each taking HOME_HEAL_NIGHTS
# (progress on the current level is kept as metadata). In the Hospital a
# patient heals HOSPITAL_STAGES_PER_NIGHT stages every night instead.
# Patients can't go on quests. Healthy patients are sent home automatically.


## Injury stages a patient heals tonight at the Hospital's current level.
func get_hospital_stages() -> int:
	return HOSPITAL_STAGES_PER_NIGHT[get_level(Building.HOSPITAL) - 1]


func is_patient(character: GuildCharacter) -> bool:
	return patients.has(character)


## Hurt but alive (Sore, Hurt or Gravely hurt).
func needs_care(character: GuildCharacter) -> bool:
	return character.injury_level > GuildCharacter.InjuryLevel.HEALTHY \
			and character.injury_level < GuildCharacter.InjuryLevel.DEAD


## Nights at home to heal one level down from `level`.
func get_heal_nights(level: int) -> int:
	return HOME_HEAL_NIGHTS[clampi(level, 0, HOME_HEAL_NIGHTS.size() - 1)]


## Nights until a hero is Healthy again, counting progress already made.
func get_nights_until_healthy(character: GuildCharacter, in_hospital: bool) -> int:
	if not needs_care(character):
		return 0
	if in_hospital:
		return ceili(float(character.injury_level) / get_hospital_stages())
	var total := 0
	for level in range(int(character.injury_level), 0, -1):
		total += get_heal_nights(level)
	return maxi(total - _recovery_progress(character), 1)


## Gold one Hospital bed costs tonight, per patient: HOSPITAL_FEE_PER_NIGHT
## times (standing rank + 1).
func nightly_fee() -> int:
	return HOSPITAL_FEE_PER_NIGHT * (HallRules.standing_rank_for(standing) + 1)


## Puts a hurt hero in a bed. Returns false if they don't need care, are
## already a patient, or the guild couldn't pay tonight's fee.
func admit(character: GuildCharacter) -> bool:
	if not needs_care(character) or is_patient(character) or gold < nightly_fee():
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
	# the dead don't take a bed, so coming back needs a free one
	if not CharacterContainer.has_free_bed():
		return false
	# the revived hero takes a bed, which is paid for tonight like any other
	if gold < nightly_fee():
		return false
	character.injury_level = GuildCharacter.InjuryLevel.GRAVELY_INJURED
	character.died_on_day = -1
	character.died_on_quest = ""
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
##    healed:  [{character, from, to, in_hospital}],
##    hospital_bill: gold paid for beds tonight,
##    sent_home_unpaid: [GuildCharacter] patients sent home because gold ran out}
## Beds are paid in the order patients were admitted; once gold can't cover
## another bed, that patient and everyone admitted after them go home to heal
## there (gold never goes negative).
func run_night() -> Dictionary:
	_forget_missing_heroes()

	var hospital_bill := 0
	var sent_home_unpaid: Array[GuildCharacter] = []
	var fee := nightly_fee()
	for character in patients.duplicate():
		if gold >= fee:
			add_gold(-fee)
			hospital_bill += fee
		else:
			patients.erase(character)
			sent_home_unpaid.append(character)

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
		var level := int(character.injury_level)
		if is_patient(character):
			# a bed heals whole stages every night
			var healed_to := maxi(level - get_hospital_stages(), int(GuildCharacter.InjuryLevel.HEALTHY))
			character.injury_level = healed_to as GuildCharacter.InjuryLevel
			character.set_meta(RECOVERY_META, Vector2i(healed_to, 0))
			healed.append({"character": character, "from": level, "to": healed_to, "in_hospital": true})
			continue
		var nights := _recovery_progress(character) + 1
		if nights >= get_heal_nights(level):
			character.injury_level = (level - 1) as GuildCharacter.InjuryLevel
			nights = 0
			healed.append({"character": character, "from": level, "to": level - 1, "in_hospital": false})
		character.set_meta(RECOVERY_META, Vector2i(int(character.injury_level), nights))

	# healed patients go home
	for character in patients.duplicate():
		if not needs_care(character):
			patients.erase(character)

	home_changed.emit()
	return {
		"trained": trained,
		"healed": healed,
		"hospital_bill": hospital_bill,
		"sent_home_unpaid": sent_home_unpaid,
	}


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
