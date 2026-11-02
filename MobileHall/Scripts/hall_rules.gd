## Hall rules: building the day's quests and playing one out. No state and no
## nodes: every function is static and takes what it needs, so the rules can be
## read (and tested) apart from the UI. hall_main.gd owns the quest entries and
## the run's tallies, and calls in here.
##
## Quest entries (see hall_main.gd quest_entries) are built by new_entry().
class_name HallRules


# ============================================================ SETTINGS

## How many quests the board gets, by day: the first row whose `max_day` the
## day is at or under is used. Days past the last row get QUESTS_PER_DAY_LATE.
## (Same ramp as QuestList.quests_per_day.)
const QUESTS_PER_DAY_BY_DAY := [
	{"max_day": 1, "count": 1},
	{"max_day": 3, "count": 2},
	{"max_day": 5, "count": 3},
	{"max_day": 10, "count": 4},
]
const QUESTS_PER_DAY_LATE := 5
## Standing per quest rank: a guild at this much standing (or less) gets rank
## 0 (F) quests, up to twice this gets rank 1, and so on up to TOP_STANDING_RANK.
const STANDING_PER_RANK := 10
## The highest rank standing alone can center quests on.
const TOP_STANDING_RANK := 5
## At or under this much standing, every quest is rank 0 (a struggling guild
## only gets the easiest work).
const STARTER_STANDING := 5
## Pluck each party member gains for winning a quest, by the odds the party
## was sent at: the longer the odds, the more they grow from beating them.
## Checked top to bottom: the first row whose `min` chance (percent) the odds
## reach is used. The `min`s match HallStyle.ODDS_BANDS, so the gain lines up with
## the odds word on Assign Party (Strong odds / Fair odds / Risky / Long shot).
const PLUCK_GAIN_BY_ODDS := [
	{"min": 80, "gain": 1},
	{"min": 60, "gain": 2},
	{"min": 40, "gain": 3},
	{"min": 0, "gain": 4},
]


# ============================================================ QUESTS

## A new quest entry for hall_main's quest_entries:
##   {quest, state (HallStyle.QUEST_STATE_*), party: Array, milestone: bool}
static func new_entry(quest: CreatedQuest, is_milestone: bool) -> Dictionary:
	return {"quest": quest, "state": HallStyle.QUEST_STATE_OPEN, "party": [], "milestone": is_milestone}


## Today's quest entries. Mirrors QuestList.populate / _generate_quests:
## the milestone day has only the Bone Drake, every other day has quests_per_day(day).
## day: GameState.day; standing: GuildUpgrades.standing.
## Returns an Array of new_entry() Dictionaries, in board order.
static func build_day_quests(day: int, standing: int) -> Array:
	if day == HallMain.MILESTONE_DAY:
		return [new_entry(CreatedQuest.new(2, 10), true)]

	var standing_rank := standing_rank_for(standing)
	var entries := []
	for quest_number in quests_per_day(day):
		var rank: int = clampi(standing_rank + int(rand_bell_curve()), 0, CreatedQuest.QuestDifficulty.S)
		# a roll two ranks off the guild's standing is pulled one rank back toward it
		if rank - standing_rank == 2:
			rank -= 1
		elif rank - standing_rank == -2:
			rank += 1
		if standing <= STARTER_STANDING:
			rank = 0

		entries.append(new_entry(CreatedQuest.new(rank, 0), false))
	return entries


## How many quests the board gets on `day` (see QUESTS_PER_DAY_BY_DAY).
static func quests_per_day(day: int) -> int:
	for row in QUESTS_PER_DAY_BY_DAY:
		if day <= row.max_day:
			return row.count
	return QUESTS_PER_DAY_LATE


## The quest rank (0 = F .. TOP_STANDING_RANK) a guild with this much standing
## centers its quests on: one rank per STANDING_PER_RANK, rounded up, from 0.
static func standing_rank_for(standing: int) -> int:
	return clampi(ceili(float(standing) / STANDING_PER_RANK) - 1, 0, TOP_STANDING_RANK)


## A normally distributed random number (Box-Muller transform).
## mean: the center; standard_deviation: the spread. Returns the sample.
static func rand_bell_curve(mean: float = 0.0, standard_deviation: float = 1.0) -> float:
	var u1: float = randf()
	var u2: float = randf()
	# avoid log(0), which is undefined
	if u1 == 0.0:
		u1 = 0.0001
	var standard_normal: float = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	# scale by the standard deviation and shift by the mean
	return (standard_normal * standard_deviation) + mean


## Pluck each party member gains for winning a quest sent at `chance` percent
## (see PLUCK_GAIN_BY_ODDS). A party with no chance yet (-1) counts as a long shot.
static func pluck_gain_for(chance: float) -> int:
	for row in PLUCK_GAIN_BY_ODDS:
		if chance >= row.min:
			return row.gain
	return PLUCK_GAIN_BY_ODDS[-1].gain


# ============================================================ PLAYING A QUEST

## Play out one quest with DayBar's helpers and pay its gold and standing into
## GameState. Party members gain Pluck on a win, found equipment goes into the
## pack, and the fallen remember where they fell. The run's tallies are left to
## the caller (hall_main.gd _tally_quest).
## entry: a quest entry (see new_entry); day: GameState.day.
## Returns one result for the Day Report:
##   {quest, party, story, succeeded, chance, gold, standing, pluck, injured, died, items, milestone}
## (pluck = what each party member gained, 0 on a failure)
## (injured = the party members whose injury level went up on this quest but
## who survived; died = the party members who died on it; items = the
## equipment found while searching, already added to the pack)
static func play_quest(entry: Dictionary, day: int) -> Dictionary:
	var party: Array[GuildCharacter] = []
	party.assign(entry.party)

	# remember health before, to see who got hurt
	var injury_before := {}
	for character in party:
		injury_before[character] = character.injury_level

	# play it out
	var chance: float = DayBar._get_success_chance(entry.quest, party)
	# only play the quest out once, or its loot and injuries would be rolled twice
	var story: String
	if day == HallMain.MILESTONE_DAY:
		story = entry.quest.generateMilestoneResults(party, chance)
	else:
		story = entry.quest.generateResults(party, chance)
	var succeeded: bool = DayBar._did_succeed(story)
	var gold_earned: int = DayBar._get_gold_earned(entry.quest, succeeded)
	var standing_earned: int = entry.quest.difficulty + 1 if succeeded else 0
	GameState.add_gold(gold_earned)
	GameState.add_standing(standing_earned)

	# equipment found while searching goes to the pack, even if the quest failed
	var found_items: Array[StandardItem] = entry.quest.found_items.duplicate()
	if not found_items.is_empty():
		ItemContainer.owned_items.append_array(found_items)
		# refresh gear rows and unworn counts
		ItemShop.gear_changed.emit()

	# a win raises everyone's Pluck, more for winning against worse odds
	var pluck_gained := pluck_gain_for(chance) if succeeded else 0
	for character in party:
		character.pluck += pluck_gained

	# the dead are listed apart from the hurt, and remember where they fell
	var injured := []
	var died := []
	for character in party:
		if HallStyle.is_dead(character) and injury_before[character] < GuildCharacter.InjuryLevel.DEAD:
			died.append(character)
			character.died_on_day = day
			character.died_on_quest = entry.quest.questTitle
		elif character.injury_level > injury_before[character]:
			injured.append(character)

	return {
		"quest": entry.quest,
		"party": entry.party.duplicate(),
		"story": story,
		"succeeded": succeeded,
		"chance": chance,
		"gold": gold_earned,
		"standing": standing_earned,
		"pluck": pluck_gained,
		"injured": injured,
		"died": died,
		"items": found_items,
		"milestone": entry.milestone,
	}
