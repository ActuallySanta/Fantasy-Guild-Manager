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

