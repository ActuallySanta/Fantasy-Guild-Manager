class_name QuestInjuries
extends RefCounted
## Static rules for how often fights hurt heroes (design: Docs/hall_design.md,
## "Injuries"). The wear per hero depends only on the quest's odds, not on its
## rank or party size, so a solo hero is no likelier to be hurt than each
## member of a party.

## Fight injuries per hero per quest, by the quest's success odds. Each row is
## [odds percent, injuries per hero]. Rows run from the highest odds down, the
## value is interpolated linearly between rows and clamped past either end.
const INJURIES_BY_ODDS := [
	[130, 0.1], [100, 0.2], [90, 0.35], [80, 0.5], [70, 0.7], [60, 0.9], [50, 1.2]
]

## Combat encounters a quest of each rank runs on average, measured from
## CreatedQuest.generateResults' encounter loops (counting "ATTACKED" lines
## over 4,000 quests per rank). Keys are CreatedQuest.QuestDifficulty values:
## G is one fixed fight, S++ (6) is freeplay only. Re-measure these if the
## loops in generateResults change.
const EXPECTED_COMBATS_BY_RANK := {-1: 1.0, 0: 2.56, 1: 4.02, 2: 4.25, 3: 6.24, 4: 8.25, 5: 10.23, 6: 12.32}


## Target fight injuries per hero for a quest at these odds.
## [param odds]: success chance in percent (can be above 100).
## Returns injuries per hero per quest, 0.1 at 130+ up to 1.2 at 50 or less.
static func target_injuries_per_hero(odds: float) -> float:
	var first: Array = INJURIES_BY_ODDS[0]
	var last: Array = INJURIES_BY_ODDS[INJURIES_BY_ODDS.size() - 1]
	if odds >= first[0]:
		return first[1]
	if odds <= last[0]:
		return last[1]
	for row_index in range(INJURIES_BY_ODDS.size() - 1):
		var high: Array = INJURIES_BY_ODDS[row_index]
		var low: Array = INJURIES_BY_ODDS[row_index + 1]
		if odds <= high[0] and odds >= low[0]:
			var fraction: float = (high[0] - odds) / float(high[0] - low[0])
			return lerpf(high[1], low[1], fraction)
	return last[1]


## Chance that one combat encounter injures a hero, so the quest's total fight
## injuries average the odds' target per hero.
## [param odds]: success chance in percent.
## [param rank]: CreatedQuest.QuestDifficulty value (clamped to the measured ranks).
## [param party_size]: heroes on the quest (at least 1).
## Returns a chance from 0.0 to 1.0.
static func injury_chance_per_encounter(odds: float, rank: int, party_size: int) -> float:
	var clamped_rank := clampi(rank, -1, 6)
	var combats: float = EXPECTED_COMBATS_BY_RANK[clamped_rank]
	return clampf(target_injuries_per_hero(odds) * maxi(party_size, 1) / combats, 0.0, 1.0)
