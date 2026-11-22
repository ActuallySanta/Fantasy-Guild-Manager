extends TestCase
## Difficulty staircase: boss schedule, difficulty_scale, requirement_scale, and
## that build_day_quests applies the scale to requirements but not gold.
## Scene: tools/tests/difficulty_scale_test.tscn

const TOLERANCE := 0.0001


func _ready() -> void:
	_test_scale_values()
	_test_boss_schedule()
	_test_requirement_scale()
	_test_build_day_quests()
	_test_save_round_trip()
	finish()


func _test_scale_values() -> void:
	var expected := {4: 1.0, 5: 1.01, 9: 1.05, 10: 1.06, 11: 1.22, 21: 1.47, 31: 1.72, 41: 1.97, 49: 2.05}
	for day: int in expected:
		check_near(HallRules.difficulty_scale(day), expected[day], TOLERANCE, "difficulty_scale(%d)" % day)
	check_near(HallRules.difficulty_scale(50), HallRules.difficulty_scale(70), TOLERANCE, "scale frozen after day 50")


func _test_boss_schedule() -> void:
	check(HallRules.is_boss_day(10) and HallRules.is_boss_day(50), "10 and 50 are boss days")
	check(not HallRules.is_boss_day(11), "11 is not a boss day")
	check(HallRules.next_boss_day(11) == 20, "next_boss_day(11) == 20")
	check(HallRules.next_boss_day(50) == 50, "next_boss_day(50) == 50")
	check(HallRules.next_boss_day(51) == -1, "next_boss_day(51) == -1")
	check(HallRules.bosses_before(10) == 0, "bosses_before(10) == 0")
	check(HallRules.bosses_before(11) == 1, "bosses_before(11) == 1")


func _test_requirement_scale() -> void:
	check_near(HallRules.requirement_scale(10, true, false), 1.06 * 1.35, TOLERANCE, "day 10 boss")
	check_near(HallRules.requirement_scale(50, true, true), HallRules.difficulty_scale(50) * 1.15, TOLERANCE, "final boss")
	check_near(HallRules.requirement_scale(60, false, false), HallRules.difficulty_scale(50) * 1.2, TOLERANCE, "freeplay day 60")


func _test_build_day_quests() -> void:
	var saved_day := GameState.day
	GameState.day = 25
	var entries := HallRules.build_day_quests(25, 60, false)
	check(entries.size() > 0, "day 25 has quests")
	for entry: Dictionary in entries:
		var quest: CreatedQuest = entry.quest
		check_near(quest.requirement_multiplier, HallRules.difficulty_scale(25), TOLERANCE, "quest requirement_multiplier")
		var rank: int = quest.difficulty
		var valid := [100 + 125 * rank, 150 + 175 * rank, 200 + 225 * rank]
		check(quest.startingGoldReward in valid, "gold unscaled (%d at rank %d)" % [quest.startingGoldReward, rank])
		check(quest.goldReward == quest.startingGoldReward, "goldReward untouched")
	GameState.day = saved_day


func _test_save_round_trip() -> void:
	var quest := CreatedQuest.new(1, 3)
	quest.requirement_multiplier = 1.0
	var writer := HallSave.RefWriter.new()
	writer.encode(quest)
	var snapshot := {"characters": writer.characters, "items": writer.items, "quests": writer.quests}
	var reader := HallSave.RefReader.new(snapshot)
	check(reader.quests.size() == 1, "one quest restored")
	check_near(reader.quests[0].requirement_multiplier, 1.0, TOLERANCE, "requirement_multiplier 1.0 survives save")
