## Hall ledger: how the run stands (is it over, is it one death from over) and
## the numbers the Game Over ledger shows. No state and no
## nodes: every function is static and takes the roster and hall_main's
## run_stats as parameters. The run's state stays on HallMain, so a new run
## (which reloads the hall scene) starts from zero.
class_name HallLedger


# ============================================================ SETTINGS

## The header's "last hero standing" strip counts standing within this many
## points of GuildUpgrades.MINIMUM_STANDING as nearly too low for recruits.
const DANGER_STANDING_MARGIN := 3


# ============================================================ THE RUN

## True when the guild can never send anyone out again: nobody is alive
## (patients in the Hospital count as alive), nobody in today's For Hire is
## affordable, and no recruit ever will be (standing is too low for anyone to
## show up, or tomorrow's price is already more than the gold left, and the
## price never goes down). Never true on the free-recruit days.
static func is_run_over() -> bool:
	if CharacterContainer.living_count() > 0 or can_afford_a_recruit_today():
		return false
	if GameState.standing <= GuildUpgrades.MINIMUM_STANDING:
		return true
	return is_short_of_recruit_gold()


## True when one hero is left alive and losing them would (or nearly would)
## end the run: nobody in today's For Hire is affordable, and either tomorrow's
## recruit price is more than the gold left, or standing is within
## DANGER_STANDING_MARGIN of the floor where recruits stop showing up.
## Drives the header's warning strip. Never true on the free-recruit days.
static func is_one_death_from_falling() -> bool:
	if CharacterContainer.living_count() != 1 or can_afford_a_recruit_today():
		return false
	return is_short_of_recruit_gold() or is_standing_near_floor()


## The one living member of `roster` (Array of GuildCharacter), or null if
## there isn't exactly one.
static func last_living_hero(roster: Array) -> GuildCharacter:
	var living := roster.filter(func(character): return not HallStyle.is_dead(character))
	return living[0] if living.size() == 1 else null


## Someone in today's For Hire costs no more than the gold in hand.
static func can_afford_a_recruit_today() -> bool:
	for character in CharacterContainer.hireable_characters:
		if character.cost <= GameState.gold:
			return true
	return false


## Tomorrow's recruit price is more than the gold in hand (prices never drop).
static func is_short_of_recruit_gold() -> bool:
	return GameState.gold < GuildCharacter.recruit_cost_for_day(GameState.day + 1)


## Standing is within DANGER_STANDING_MARGIN of the floor where recruits stop showing up.
static func is_standing_near_floor() -> bool:
	return GameState.standing <= GuildUpgrades.MINIMUM_STANDING + DANGER_STANDING_MARGIN


# ============================================================ LEDGER

## Everything the Game Over ledger shows, read from the tallies and the roster.
## run_stats: hall_main's tallies; roster: CharacterContainer.active_characters.
## Returns:
##   days, gold_earned, quests_sent, quests_won, heroes_hired, fallen (int),
##   standing (int), drake_result (String),
##   roll_call: Array of GuildCharacter, the fallen first (earliest death first),
##              then the released, then anyone else still on the roster
##   released:  Array of GuildCharacter (to tell the released apart in the roll call)
static func build_run_over_stats(run_stats: Dictionary, roster: Array) -> Dictionary:
	var released: Array = run_stats.released.duplicate()
	var everyone: Array = roster.duplicate()
	for character in released:
		if not everyone.has(character):
			everyone.append(character)

	var fallen := everyone.filter(func(character): return HallStyle.is_dead(character))
	fallen.sort_custom(func(a, b): return a.died_on_day < b.died_on_day)
	var let_go := released.filter(func(character): return not HallStyle.is_dead(character))
	var others := everyone.filter(func(character):
		return not fallen.has(character) and not let_go.has(character))

	return {
		"days": GameState.day,
		"gold_earned": run_stats.gold_earned,
		"quests_sent": run_stats.quests_sent,
		"quests_won": run_stats.quests_won,
		"heroes_hired": run_stats.heroes_hired,
		"fallen": fallen.size(),
		"standing": GameState.standing,
		"drake_result": run_stats.drake_result,
		"roll_call": fallen + let_go + others,
		"released": released,
	}


# ============================================================ CREDITS

## The run's extra records for the final battle's credits roll.
## run_stats: hall_main's tallies; roster: CharacterContainer.active_characters.
## Returns:
##   gold_spent, items_found (int)
##   buildings: Array of {name: String, level: int}, working buildings only
##   longest_serving: the GuildCharacter who served the most days (null if
##                    nobody did), and longest_days (int) how many
## A hero's service runs from joined_on_day to the day they fell, or to today.
## Released heroes who are still alive aren't counted (their leaving day isn't kept).
static func build_run_records(run_stats: Dictionary, roster: Array) -> Dictionary:
	var buildings := []
	for building in HallStyle.buildings_in_order():
		if GuildUpgrades.is_implemented(building):
			buildings.append({"name": GuildUpgrades.get_building_name(building), "level": GuildUpgrades.get_level(building)})

	var longest_serving: GuildCharacter = null
	var longest_days := 0
	var everyone: Array = roster.duplicate()
	for character in run_stats.released:
		if HallStyle.is_dead(character) and not everyone.has(character):
			everyone.append(character)
	for character in everyone:
		var has_death_day: bool = HallStyle.is_dead(character) and character.died_on_day > 0
		var last_day: int = character.died_on_day if has_death_day else GameState.day
		var served: int = last_day - character.joined_on_day + 1
		if served > longest_days:
			longest_days = served
			longest_serving = character

	return {
		"gold_spent": run_stats.gold_spent,
		"items_found": run_stats.items_found,
		"buildings": buildings,
		"longest_serving": longest_serving,
		"longest_days": longest_days,
	}


## Everything the final battle's credits roll shows (overlay_credits.gd).
## result: the final quest's HallRules.play_quest result; run_stats, roster: as above.
## Returns:
##   won: bool (the victory roll with Begin Freeplay, or the defeat screen)
##   day: int
##   result: the final quest's result (story, party, died, ...)
##   stats: build_run_over_stats() (the screen leaves out the Bone Drake)
##   records: build_run_records()
static func build_credits(result: Dictionary, run_stats: Dictionary, roster: Array) -> Dictionary:
	return {
		"won": result.succeeded,
		"day": GameState.day,
		"result": result,
		"stats": build_run_over_stats(run_stats, roster),
		"records": build_run_records(run_stats, roster),
	}

