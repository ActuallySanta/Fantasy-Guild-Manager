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


func _init(diff := 0, dayNum := 0) -> void:
	if (dayNum == 10):
		_initMilestoneVars(dayNum)
		return

	difficulty = diff
	maxAdventurers = randi_range(1, 2)

	questNum = randi_range(0, 7)
	type = ExternalContentContainer.get_Quest_Story(questNum, 0).to_int()
	location = QuestManager.newRegion.returnName(type)
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
	if (maxAdventurers == 1):
		statHitNum = (statHitNum / 2)
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
				returnString = str(returnString, "[b]", _questingAdventurers[0].name, " ", ExternalContentContainer.get_Quest_Story(questNum, 3).c_unescape().format(data))
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
			returnString = str(returnString, "[b]Summary[/b]: The quest was [color=red][b]NOT SUCCESSFUL[/b][/color]. Your guild failed to obtain the reward.\n")
			questSummary = str(questSummary, "[b]Summary[/b]: The quest was NOT SUCCESSFUL. Your guild failed to obtain the reward.\n")

			if (goldReward > 200):
				returnString = str(returnString, "However, your adventurers did bring back [color=FFE700][b]", goldReward - 200, " gold[/b][/color].\n")
				questSummary = str(questSummary, "However, your adventurers did bring back ", goldReward - 200, " gold")
		_:
			if (numAdventurers == 1):
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name, " ",
					ExternalContentContainer.get_Quest_Story(questNum, 4).c_unescape().format(data),
				)
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name, " ",
					ExternalContentContainer.get_Quest_Story(questNum, 4).c_unescape().format(data),
				)
			returnString = str(returnString, "[b]Summary[/b]: The quest was [color=green][b]SUCCESSFUL[/b][/color]. Your guild gained [color=FFE700][b]", goldReward, " gold[/b][/color].\n")
			questSummary = str(questSummary, "[b]Summary[/b]: The quest was SUCCESSFUL. Your guild gained ", goldReward, " gold.")

	#loop with size based on difficulty -> higher difficulty more loops 
	#sends combat or search to its own methods

	#once the loop moves on you put the middle if the quest has one and
	#then the loop begins again (again, only if the quest has a middle)

	#once the loop moves on we are done here
	return returnString

func _combatEncounter(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var combatChance = _successChance / 100.0
	combatChance *= combatChance
	combatChance *= 100.0

	if combatChance > 90:
		combatChance = 90

	var returnString = ""
	var successDetermination = randi_range(0, 100)

	if combatChance >= successDetermination:
		var succComDet = randi_range(1, 100)
		if(1 <= succComDet && succComDet <= 25):
				returnString = str(
					"[b]The Party[/b] was ATTACKED by a group of ",
					QuestManager.newRegion.returnMonster(),
					"s, but defeated them [color=green][b]without sustaining any injuries[/b][/color].\n"
				)
		elif (26 <= succComDet && succComDet <= 50):
				var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
				returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ",
					QuestManager.newRegion.returnMonster(),
					", but defeated it [color=green][b]without sustaining any injuries[/b][/color].\n"
					)
		elif (51 <= succComDet && succComDet <= 75):
				returnString = str(
					"[b]The Party[/b] was ATTACKED by a group of ",
					QuestManager.newRegion.returnMonster(),
					". They defeated them [color=green][b]without sustaining any injuries[/b][/color], and also obtained [EQUIP_NOT_IMPLEMENTED].\n"
					)
		elif (76 <= succComDet && succComDet <= 90):
				var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
				var extraGold = randi_range(11, 29)
				goldReward += extraGold
				returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ",
					QuestManager.newRegion.returnMonster(),
					", and defeated it, finding [color=FFE700][b] ", extraGold," gold [/b][/color]on its corpse.\n"
					)
		elif (91 <= succComDet && succComDet <= 100):
				var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
				var extraGold = randi_range(11, 29)
				goldReward += extraGold
				returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ",
					QuestManager.newRegion.returnMonster(), ", and defeated it, finding [color=FFE700][b] ", extraGold, 
					" gold [/b][/color]on its corpse. However, they were [color=FD0000][b]INJURED[/b][/color] in the process.\n"
					)
				attackedAdventurer.injure_character()

	else:
		var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
		var succComDet = randi_range(1, 100)
		
		if(1 <= succComDet && succComDet <= 25):
			returnString = str(
			"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ", QuestManager.newRegion.returnMonster(),
			". They managed to fight the monster off but were [color=FD0000][b]INJURED[/b][/color] in the process.\n"
			)
			attackedAdventurer.injure_character()
		elif (26 <= succComDet && succComDet <= 50):
			returnString = str(
					"[b]The Party[/b] was ATTACKED by a group of ", QuestManager.newRegion.returnMonster(),
					"s. They managed to defeat them, but not before [color=FD0000][b]", attackedAdventurer.name, " was INJURED[/b][/color] in the process.\n"
					)
			attackedAdventurer.injure_character()
		elif (51 <= succComDet && succComDet <= 75):
			returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ", QuestManager.newRegion.returnMonster(), 
					", and defeated it, obtaining a(n) [EQUIP_NOT_IMPLEMENTED] on its corpse. However, they were [color=FD0000][b]INJURED[/b][/color] in the process.\n"
					)
			attackedAdventurer.injure_character()
		elif (76 <= succComDet && succComDet <= 90):
			returnString = str(
					"[b]The Party[/b] was ATTACKED by a group of ",
					QuestManager.newRegion.returnMonster(),
					"s, but defeated them [color=green][b]without sustaining any injuries[/b][/color].\n"
				)
		elif (91 <= succComDet && succComDet <= 100):
				returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ",
					QuestManager.newRegion.returnMonster(),
					", but defeated it [color=green][b]without sustaining any injuries[/b][/color].\n"
					)

	return returnString

func _search(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var searchChance = _successChance / 100
	searchChance = searchChance * searchChance
	searchChance *= 100
	if (searchChance > 90):
		searchChance = 90

	var returnString = ""
	var successDetermination = randi_range(0, 100)
	var searchingAdventurer: GuildCharacter = _questingAdventurers.pick_random()
	if(searchChance >= successDetermination):
		var succSearDet = randi_range(1, 100)
		if(1 <= succSearDet && succSearDet <= 13):
			var extraGold = randi_range(11, 29)
			goldReward += extraGold
			returnString = str(returnString, "[b]The Party[/b] discovered an old chest containing [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		elif(14 <= succSearDet && succSearDet <= 25):
			var extraGold = randi_range(11, 29)
			goldReward += extraGold
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] found an old chest containing [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		elif(26 <= succSearDet && succSearDet <= 38):
			var extraGold = randi_range(3, 15)
			goldReward += extraGold
			returnString = str(returnString, "[b]The Party[/b] unearthed a lockbox that contained [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		elif(38 <= succSearDet && succSearDet <= 50):
			var extraGold = randi_range(3, 15)
			goldReward += extraGold
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] found someone's lost wallet on the ground, which still had [color=FFE700][b]", extraGold, " gold[/b][/color] in it.\n")
		elif(51 <= succSearDet && succSearDet <= 62):
			var extraGold = randi_range(25, 59)
			goldReward += extraGold
			returnString = str(returnString, "[b]The Party[/b] discovered a secret room filled with treasure, including [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		elif(63 <= succSearDet && succSearDet <= 75):
			var extraGold = randi_range(24, 59)
			goldReward += extraGold
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] unearthed a rather gaudy looking artifact, which turned out to be worth [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
	else:
		var succSearDet = randi_range(1, 100)
		if(1 <= succSearDet && succSearDet <= 15):
			returnString = str(returnString, "[b]", searchingAdventurer.name, "[/b] tripped on a rock and gained [color=FD0000][b]1 INJURY[/b][/color].\n")
		elif(16 <= succSearDet && succSearDet <= 45):
			returnString = str(returnString, "[b]The Party[/b] discovered a hidden room containing multiple chests, but [color=FD0000][b]NOTHING OF VALUE[/b][/color] was inside.\n")
		elif(46 <= succSearDet && succSearDet <= 75):
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] went off alone to search for treasure, but returned with [color=FD0000][b]NOTHING[/b][/color].\n")
		elif(76 <= succSearDet && succSearDet <= 90):
			var extraGold = randi_range(3, 15)
			goldReward += extraGold
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] found an old chest containing [color=FFE700][b]", extraGold, " gold[/b][/color]. However, the chest was trapped and [b]", searchingAdventurer, 
			"[/b] was [color=FD0000][b]INJURED 1 TIME[/b][/color].]\n")
		elif(91 <= succSearDet && succSearDet <= 100):
			goldReward += 1
			returnString = str(returnString, "[b]The Party[/b] unearthed a lockbox that contained [color=FFE700][b]1 gold[/b][/color].\n")
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
			questTitle = str("A Bone Drake is ATTACKING ", location, "! Save the town before it is DESTROYED!")

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
