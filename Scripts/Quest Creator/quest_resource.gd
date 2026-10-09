extends Resource

class_name CreatedQuest

enum QuestDifficulty {
	F = 0,
	D = 1,
	C = 2,
	B = 3,
	A = 4,
	S = 5,
}

enum QuestType {
	#skip 0 for now
	DungeonClear = 1,
	Escort = 2,
	ScoutTerrain = 3,
	GatherIntel = 4,
}

enum FavoredStat {
	Attack = 0,
	Defense = 1,
	Wisdom = 2,
	Sleaze = 3,
	Pluck = 4,
}

#enum for modifiers if we ever choose to do them

var numAdventurers: int
var maxAdventurers: int
var goldReward: int
#var for statReward if applicable

var location: String
#var/vars for other flavors (characters/items/etc)

var difficulty: QuestDifficulty
var type: QuestType
var favStat: FavoredStat
#var for modifier(s) if we ever choose to do that

var questTitle: String:
	get:
		return questTitle

var questSummary: String = "":
	get:
		return questSummary

var questNum: int:
	get:
		return questNum


func _init(dayNum := 0) -> void:
	if (dayNum == 10):
		_initMilestoneVars(dayNum)
		return

	difficulty = 0
	#hard code
	maxAdventurers = randi_range(1,2)

	questNum = randi_range(0, 7)
	type = ExternalContentContainer.get_Quest_Story(questNum, 0).to_int()
	location = ExternalContentContainer.get_Location_Name(type - 1)
	goldReward = 200 + (150 * difficulty)

	match type:
		1:
			favStat = FavoredStat.Attack
			questTitle = str("Raid the ", location)
		2:
			favStat = FavoredStat.Defense
			questTitle = str("Escort someone to ", location)
		3:
			favStat = FavoredStat.Wisdom
			questTitle = str("Explore ", location)
		4:
			favStat = FavoredStat.Sleaze
			questTitle = str("Gather information on ", location)

	print("")
	pass


func calcSuccessChance(_questingAdventurers: Array) -> int:
	var statHitNum = 60.0 + (20 * difficulty)
	var statTotal = 0.0

	for adventurer in _questingAdventurers:
		statTotal += adventurer.stats[0] + adventurer.stats[1] + adventurer.stats[2] + adventurer.stats[3]
		match favStat:
			0:
				statTotal += adventurer.stats[0]
			1:
				statTotal += adventurer.stats[1]
			2:
				statTotal += adventurer.stats[2]
			3:
				statTotal += adventurer.stats[3]

	return (snapped((statTotal / statHitNum), 0.01) * 100)


#this is the main root method for deciding and generating results I'll have
#methods branch off to decide certain parts of the results
func generateResults(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var returnString = ""

	numAdventurers = _questingAdventurers.size()
	#print(numAdventurers)

	var data = { "location": location }
	if (numAdventurers == 1):
		returnString = str(
			returnString,
			"[b]",
			_questingAdventurers[0].name,
			"[/b] ",
			ExternalContentContainer.get_Quest_Story(questNum, 1).c_unescape().format(data),
		)
	else:
		returnString = str(
			returnString,
			"[b]",
			_questingAdventurers[0].name,
			"[/b] and [b]",
			_questingAdventurers[1].name,
			"[/b] ",
			ExternalContentContainer.get_Quest_Story(questNum, 1).c_unescape().format(data),
		)

	var loopbreaker = 12 + (3 * difficulty)
	while randi_range(-1, 10) < loopbreaker:
		match randi_range(0, 1):
			0:
				returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
			1:
				returnString = str(returnString, _search(_questingAdventurers, _successChance))
		loopbreaker = loopbreaker - 1

	var successDetermination = randi_range(0, 100)
	match true:
		_ when successDetermination >= _successChance:
			if (numAdventurers == 1):
				returnString = str(returnString, "[b]", _questingAdventurers[0].name, ExternalContentContainer.get_Quest_Story(questNum, 3).c_unescape().format(data))
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name,
					" ",
					ExternalContentContainer.get_Quest_Story(questNum, 3).c_unescape().format(data),
				)
			returnString = str(returnString, "Summary: The quest was [color=red][b]NOT SUCCESSFUL[/b][/color]. Your guild failed to obtain the reward.\n")
			questSummary = str(questSummary, "Summary: The quest was NOT SUCCESSFUL. Your guild failed to obtain the reward.\n")

			if (goldReward > 200):
				returnString = str(returnString, "However, your adventurers did bring back [color=FFE700][b]", goldReward - 200, " gold[/b][/color].\n")
				questSummary = str(questSummary, "However, your adventurers did bring back ", goldReward - 200, " gold")
		_:
			if (numAdventurers == 1):
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					ExternalContentContainer.get_Quest_Story(questNum, 4).c_unescape().format(data),
				)
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name,
					ExternalContentContainer.get_Quest_Story(questNum, 4).c_unescape().format(data),
				)
			returnString = str(returnString, "Summary: The quest was [color=green][b]SUCCESSFUL[/b][/color]. Your guild gained [color=FFE700][b]", goldReward, " gold[/b][/color].\n")
			questSummary = str(questSummary, "Summary: The quest was SUCCESSFUL. Your guild gained ", goldReward, " gold.")

	#loop with size based on difficulty -> higher difficulty more loops 
	#sends combat or search to its own methods

	#once the loop moves on you put the middle if the quest has one and
	#then the loop begins again (again, only if the quest has a middle)

	#once the loop moves on we are done here
	return returnString


func _combatEncounter(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var combatChance = _successChance / 100
	combatChance = combatChance * combatChance
	combatChance *= 100
	if (combatChance > 90):
		combatChance = 90

	var returnString = ""
	var successDetermination = randi_range(0, 100)
	match true:
		_ when combatChance >= successDetermination:
			returnString = str(
				returnString,
				"[b]The Party[/b] was ATTACKED by a group of ",
				ExternalContentContainer.get_Monster_Name(QuestManager.instance.testQuestNumber),
				"s, but defeated them [color=green][b]without sustaining any injuries[/b][/color].\n",
			)
		_:
			var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
			returnString = str(
				returnString,
				"[b]",
				attackedAdventurer.name,
				"[/b] was ATTACKED by a ",
				ExternalContentContainer.get_Monster_Name(QuestManager.instance.testQuestNumber),
				". They managed to fight the monster off but were [color=FD0000][b]INJURED[/b][/color] in the process.\n",
			)
			attackedAdventurer.injure_character()
	return returnString


func _search(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var searchChance = _successChance / 100
	searchChance = searchChance * searchChance
	searchChance *= 100
	if (searchChance > 90):
		searchChance = 90

	var returnString = ""
	var successDetermination = randi_range(0, 100)
	match true:
		_ when searchChance >= successDetermination:
			var extraGold = randi_range(11, 29)
			goldReward += extraGold
			returnString = str(returnString, "[b]The Party[/b] discovered an old chest containing [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		_:
			returnString = str(returnString, "[b]", _questingAdventurers[randi_range(0, numAdventurers - 1)].name, "[/b] tripped on a rock and gained [color=FD0000][b]1 INJURY[/b][/color].\n")
	return returnString


func _initMilestoneVars(dayNum: int):
	match dayNum:
		10:
			difficulty = 2
			maxAdventurers = 2
			questNum = 0
			type = ExternalContentContainer.get_Milestone_story(questNum, 0).to_int()
			location = ExternalContentContainer.get_Location_Name(1)
			goldReward = 300 + (150 * difficulty)
			favStat = FavoredStat.Attack
			questTitle = str("A Bone Drake is ATTACHING ", location, "! Save the town before it is DESTROYED!")

	print("")
	pass


func generateMilestoneResults(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var returnString = ""
	numAdventurers = _questingAdventurers.size()

	var data = { "location": location }
	if (numAdventurers == 1):
		returnString = str(
			returnString,
			"[b]",
			_questingAdventurers[0].name,
			"[/b] ",
			ExternalContentContainer.get_Milestone_story(questNum, 1).c_unescape().format(data),
		)
	else:
		returnString = str(
			returnString,
			"[b]",
			_questingAdventurers[0].name,
			"[/b] and [b]",
			_questingAdventurers[1].name,
			"[/b] ",
			ExternalContentContainer.get_Milestone_story(questNum, 1).c_unescape().format(data),
		)

	var loopbreaker = 12 + (3 * difficulty)
	while randi_range(-1, 10) < loopbreaker:
		match randi_range(0, 1):
			0:
				returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
			1:
				returnString = str(returnString, _search(_questingAdventurers, _successChance))
		loopbreaker = loopbreaker - 1

	var successDetermination = randi_range(0, 100)
	match true:
		_ when successDetermination >= _successChance:
			if (numAdventurers == 1):
				returnString = str(returnString, "[b]", _questingAdventurers[0].name, "[/b] ", ExternalContentContainer.get_Milestone_story(questNum, 3).c_unescape().format(data))
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name,
					" ",
					ExternalContentContainer.get_Milestone_story(questNum, 3).c_unescape().format(data),
				)
			returnString = str(returnString, "Summary: The quest was [color=red][b]NOT SUCCESSFUL[/b][/color]. Your guild failed to obtain the reward.\n")
			questSummary = str(questSummary, "Summary: The quest was NOT SUCCESSFUL. Your guild failed to obtain the reward.\n")

			if (goldReward > 200):
				returnString = str(returnString, "However, your adventurers did bring back [color=gold][b]", goldReward - 200, " gold[/b][/color].\n")
				questSummary = str(questSummary, "However, your adventurers did bring back ", goldReward - 200, " gold")
		_:
			if (numAdventurers == 1):
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] ",
					ExternalContentContainer.get_Milestone_story(questNum, 4).c_unescape().format(data),
				)
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name,
					ExternalContentContainer.get_Milestone_story(questNum, 4).c_unescape().format(data),
				)
			returnString = str(returnString, "Summary: The quest was [color=green][b]SUCCESSFUL[/b][/color]. Your guild gained [color=gold][b]", goldReward, " gold[/b][/color].\n")
			questSummary = str(questSummary, "Summary: The quest was SUCCESSFUL. Your guild gained ", goldReward, " gold.")

	return returnString


func generatePartyDuo() -> Array[GuildCharacter]:
	var party: Array[GuildCharacter]

	var firstAdventurer = GuildCharacter.new()
	var secondAdventurer = GuildCharacter.new()

	party.append(firstAdventurer)
	party.append(secondAdventurer)

	return party
