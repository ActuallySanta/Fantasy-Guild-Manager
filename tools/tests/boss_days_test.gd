extends TestCase
## Boss days 10/20/30/40/50 build the written boss quests.
## Scene: tools/tests/boss_days_test.tscn

const F := CreatedQuest.FavoredStat

## Per boss day: [slots, rank, favored stat, region index, quest (story row)] per entry.
const EXPECTED := {
	10: [[3, 2, F.Defense, 1, 0]],
	20: [[3, 3, F.Power, 2, 1], [3, 3, F.Wisdom, 3, 2]],
	30: [[5, 3, F.Sleaze, 2, 3]],
	40: [[4, 4, F.PowerAndDefense, 1, 4], [5, 4, F.WisdomAndSleaze, 3, 5]],
	50: [[8, 5, F.Pluck, 0, 6]],
}


func _ready() -> void:
	var saved_day := GameState.day
	for day: int in EXPECTED:
		GameState.day = day
		var entries := HallRules.build_day_quests(day, 60, false)
		var expected: Array = EXPECTED[day]
		check(entries.size() == expected.size(), "day %d entry count" % day)
		if entries.size() != expected.size():
			continue
		for i in entries.size():
			var quest: CreatedQuest = entries[i].quest
			var row: Array = expected[i]
			var tag := "day %d #%d " % [day, i]
			check(quest.maxAdventurers == row[0], tag + "slots")
			check(quest.difficulty == row[1], tag + "rank")
			check(quest.favStat == row[2], tag + "favored stat")
			check(quest.regionNum == row[3], tag + "region")
			check(quest.questNum == row[4], tag + "story row")
			check(entries[i].milestone == true, tag + "milestone")
			check(entries[i].final == (day == 50), tag + "final flag")
			check_near(quest.requirement_multiplier,
					HallRules.requirement_scale(day, true, day == HallMain.FINAL_DAY), 0.001,
					tag + "requirement scale")
			check(quest.goldReward == 300 + 150 * quest.difficulty, tag + "gold")
	GameState.day = 18
	check(HallRules.build_day_quests(18, 60, false).size() == 2, "day 18 keeps two minor quests")
	GameState.day = saved_day
	check(not ExternalContentContainer.get_Milestone_story(6, 5).contains("She warns"),
			"Demon King row has the victory line")
	check(ExternalContentContainer.get_Milestone_story(6, 5).contains("WON"), "victory line says WON")
	finish()
