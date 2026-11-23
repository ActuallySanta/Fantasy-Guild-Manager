extends TestCase
## Requirement scales with party size: statHitNum *= slots / 2.
## Scene: tools/tests/slot_factor_test.tscn

## Rank (difficulty) the test quests are built at.
const RANK := 3
## Chances the OLD formula (1 slot /2, 2 slots x1, 3 slots x1.5) gave for the
## fixed party below at rank 3: party total 180 over a base of 120 -> hit numbers 60,
## 120 and 180. Hard-coded, computed before the change.
const OLD_CHANCE_1_SLOT := 300.0
const OLD_CHANCE_2_SLOTS := 150.0
const OLD_CHANCE_3_SLOTS := 100.0


func _ready() -> void:
	var party := _make_party()
	var c1 := _chance(1, party)
	var c2 := _chance(2, party)
	var c3 := _chance(3, party)
	var c5 := _chance(5, party)
	var c8 := _chance(8, party)
	print("chances 1/2/3/5/8: ", c1, " ", c2, " ", c3, " ", c5, " ", c8)
	check_near(c1, OLD_CHANCE_1_SLOT, 1.0, "1 slot matches the old formula")
	check_near(c2, OLD_CHANCE_2_SLOTS, 1.0, "2 slots match the old formula")
	check_near(c3, OLD_CHANCE_3_SLOTS, 1.0, "3 slots match the old formula")
	check_near(c5, c2 / 2.5, 1.0, "5 slots need 2.5x the 2-slot requirement")
	check_near(c8, c2 / 4.0, 1.0, "8 slots need 4x the 2-slot requirement")

	# An 8-slot quest with a 3-hero party still plays out to a clear result.
	var big := _make_quest(8)
	var typed_party: Array[GuildCharacter] = []
	typed_party.assign(party)
	var chance := big.calcSuccessChance(typed_party)
	check(chance > 0, "8-slot quest with 3 heroes has a chance above 0")
	var story := big.generateResults(typed_party, chance)
	check(story.contains("SUCCESSFUL") or story.contains(QuestScoring.FAIL_MARKER),
			"8-slot quest with 3 heroes returns a result")
	finish()


## A quest at RANK with the given slot count and no freeplay scaling.
func _make_quest(slots: int) -> CreatedQuest:
	var quest := CreatedQuest.new(RANK, 0)
	quest.maxAdventurers = slots
	quest.requirement_multiplier = 1.0
	quest.regionNum = 0
	quest.favStat = 0
	return quest


func _chance(slots: int, party: Array) -> float:
	return _make_quest(slots).calcSuccessChance(party)


## Three fixed heroes: no pluck, no gear, healthy, set stats.
func _make_party() -> Array:
	var party: Array = []
	var stat_sets := [[10, 10, 10, 10], [12, 8, 10, 10], [8, 12, 10, 10]]
	for stat_set in stat_sets:
		var hero := GuildCharacter.new()
		hero.pluck = 0
		hero.injury_level = GuildCharacter.InjuryLevel.HEALTHY
		hero.equipped_items.clear()
		for i in 4:
			hero.stats[i] = stat_set[i]
		party.append(hero)
	return party
