extends TestCase
## Lead-up side quests (MinorVariables rows 9-21) appear on their days.
## Scene: tools/tests/lead_up_quests_test.tscn

## Day -> MinorVariables row of the day's first quest. The schedule is master's
## story-quest schedule (CreatedQuest._initMilestoneVars).
const DAY_TO_ROW := {
	23: 9, 26: 10, 28: 11, 32: 13, 34: 14, 37: 15, 43: 18, 45: 19, 48: 21,
}
## Days with extra lead-up quests after the first: day -> rows of the other entries.
const EXTRA_ROWS := {28: [12], 37: [16, 17], 45: [20]}


func _ready() -> void:
	var saved_day := GameState.day
	for day: int in DAY_TO_ROW:
		GameState.day = day
		var row: int = DAY_TO_ROW[day]
		var entries := HallRules.build_day_quests(day, 60, false)
		var tag := "day %d " % day
		check(not entries.is_empty(), tag + "has quests")
		if entries.is_empty():
			continue
		var first: CreatedQuest = entries[0].quest
		check(first.questTitle == ExternalContentContainer.get_Minor_Story_Variables(row, 6), tag + "title")
		check(first.styleOfQuest == 1, tag + "is a minor quest")
		check(first.questNum == ExternalContentContainer.get_Minor_Story_Variables(row, 2).to_int(), tag + "story row")
		check(not ExternalContentContainer.get_Minor_Story(first.questNum, 1).is_empty(), tag + "has story text")
		check_near(first.requirement_multiplier, HallRules.requirement_scale(day, false, false), 0.001,
				tag + "requirement scale")
		var extra: Array = EXTRA_ROWS.get(day, [])
		check(entries.size() >= 1 + extra.size(), tag + "has its extra lead-up quests")
		for i in range(1, entries.size()):
			if i <= extra.size():
				check(entries[i].quest.styleOfQuest == 1, tag + "#%d is a lead-up quest" % i)
				check(entries[i].quest.questTitle == ExternalContentContainer.get_Minor_Story_Variables(extra[i - 1], 6),
						tag + "#%d title" % i)
			else:
				check(entries[i].quest.styleOfQuest != 1, tag + "#%d is normal" % i)
	# every lead-up row loads with all six story columns (type|intro|mid x2|fail|success)
	for row in range(9, 22):
		check(ExternalContentContainer.minor_story[row].size() == 6, "story row %d has 6 columns" % row)
	GameState.day = 22
	for entry in HallRules.build_day_quests(22, 60, false):
		check(entry.quest.styleOfQuest != 1, "day 22 has no minor quest")
	GameState.day = saved_day
	finish()
