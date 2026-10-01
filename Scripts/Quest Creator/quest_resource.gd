extends Resource

class_name CreatedQuest

enum QuestDifficulty{
	F = 0,
	D = 1,
	C = 2,
	B = 3,
	A = 4,
	S = 5
}

enum QuestType{
	#skip 0 for now
	DungeonClear = 1,
	Escort = 2,
}

enum FavoredStat{
	Attack = 0,
	Defense = 1,
	Wisdom = 2,
	Sleaze = 3,
	Pluck = 4
}

#enum for modifiers if we ever choose to do them

#might hardcode these we will see based on scope and gdscript and whatnot
var start: String
var middle: String
var end: String

var goldReward: int;
#var for statReward if applicable

var location: String
#var/vars for other flavors (characters/items/etc)

var difficulty: QuestDifficulty
var type: QuestType
var favStat: FavoredStat
#var for modifier(s) if we ever choose to do that

var monsters: Array[String] #temp array for monsters for early testing

var questTitle: String:
	get:
		return questTitle
		
var questSummary: String = "":
	get:
		return questSummary
		
#need to pull a bunch of stuff out of spreadsheet somehow at some time
#start, middle, end, location, and flavors all need to be pulled out, probably
#at generation - monsters can be pulled out later but only if that's realistic

#don't know yet if this needs to be sent somewhere either, but I assume we want this as void regardless
func _init() -> void:
	#hard coding variables for intial testing
	difficulty = 0;
	type = 0;
	favStat = 0;
	
	location = ExternalContentContainer.get_Dungeon_Name()
	goldReward = 200;
	
	#set here for early testing only
	monsters.append("Hydra")
	monsters.append("Gorgon")
	monsters.append("Medusa")
	monsters.append("Dragon")
	monsters.append("Skeleton Warrior")
	monsters.append("Nathaniel Klubek")
	
	questTitle = str("Raid the ", location)
	
	print("")
	
	#set variables
	#generate description -> I don't know if that will be held here or not
	pass
	
func calcSuccessChance(_questingAdventurers: Array[GuildCharacter]) -> float:
	#calc this
	return 0.0

#this is the main root method for deciding and generating results I'll have
#methods branch off to decide certain parts of the results
func generateResults(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var returnString = ""
	
	var party : Array[GuildCharacter]
	party = generatePartyDuo()
	
	returnString = str(returnString, "[b]", _questingAdventurers[0].name, "[/b] and [b]", _questingAdventurers[1].name, 
	"[/b] raided the [b]", location, "[/b].\n")
	
	var loopbreaker = 12
	while randi_range(-1, 10) < loopbreaker:
		match randi_range(0, 1):
			0:
				returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
			1:
				returnString = str(returnString, _search(_questingAdventurers, _successChance))
		loopbreaker = loopbreaker - 1;
	
	var successDetermination = randi_range(0, 100)
	match true:
		_ when successDetermination >= _successChance:
			returnString = str(returnString, "[b]", _questingAdventurers[0].name, "[/b] and [b]", _questingAdventurers[1].name, 
	" [color=red]DID NOT[/color][/b] manage to reach the bottom of the ", location, ".\n")
			returnString = str(returnString, "Summary: The quest was [color=red][b]NOT SUCCESSFUL[/b][/color]. Your guild failed to obtain the reward.\n")
			questSummary = str(questSummary, "Summary: The quest was NOT SUCCESSFUL. Your guild failed to obtain the reward.\n")
			
			if(goldReward > 200):
				returnString = str(returnString, "However, your adventurers did bring back [color=gold][b]", goldReward - 200, " gold[/b][/color].\n")
				questSummary = str(questSummary, "However, your adventurers did bring back ", goldReward - 200, " gold")
		_:
			returnString = str(returnString, "[b]", _questingAdventurers[0].name, "[/b] and [b]", _questingAdventurers[1].name, 
	"[/b] [color=green][b]REACHED[/b][/color] the bottom of the ", location, ".\n")
			returnString = str(returnString, "Summary: The quest was [color=green][b]SUCCESSFUL[/b][/color]. Your guild gained [color=gold][b]", goldReward," gold[/b][/color].\n")
			questSummary = str(questSummary, "Summary: The quest was SUCCESSFUL. Your guild gained ", goldReward," gold.")
	
	#loop with size based on difficulty -> higher difficulty more loops 
	#sends combat or search to its own methods
	
	#once the loop moves on you put the middle if the quest has one and
	#then the loop begins again (again, only if the quest has a middle)
	
	#once the loop moves on we are done here
	#put in end text
	return returnString
		
func _combatEncounter(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	#gotta be a better way of doing this but I'm tired
	var combatChance = _successChance / 100
	combatChance = combatChance * combatChance
	combatChance *= 100
	if(combatChance > 90):
		combatChance = 90
	
	var returnString = ""
	var successDetermination = randi_range(0, 100)
	match true:
		_ when combatChance >= successDetermination:
			print(QuestManager.instance.testQuestNumber)
			returnString = str(returnString, "[b]The Party[/b] was ATTACKED by a group of ", ExternalContentContainer.get_Monster_Name(QuestManager.instance.testQuestNumber),
			"s, but defeated them [color=green][b]without sustaining any injuries[/b][/color].\n")
		_:
			returnString = str(returnString, "[b]", _questingAdventurers[0].name, "[/b] was ATTACKED by a ", ExternalContentContainer.get_Monster_Name(QuestManager.instance.testQuestNumber),
			". They managed to fight the monster off but was [color=red][b]INJURED[/b][/color] in the process.\n")
	return returnString
		
func _search(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	#gotta be a better way of doing this but I'm tired
	var searchChance = _successChance / 100
	searchChance = searchChance * searchChance
	searchChance *= 100
	if(searchChance > 90):
		searchChance = 90
	
	var returnString = ""
	var successDetermination = randi_range(0, 100)
	match true:
		_ when searchChance >= successDetermination:
			var extraGold = randi_range(11, 29)
			goldReward += extraGold
			returnString = str(returnString, "[b]The Party[/b] discovered an old chest containing [color=gold][b]", extraGold, " gold[/b][/color].\n")
		_ :
			returnString = str(returnString, "[b]", _questingAdventurers[1].name, "[/b] tripped on a rock and gained [color=red][b]1 INJURY[/b][/color].\n")
	return returnString

func generatePartyDuo() -> Array[GuildCharacter]:
	var party : Array[GuildCharacter]
	
	var firstAdventurer = GuildCharacter.new()
	var secondAdventurer = GuildCharacter.new()
	
	party.append(firstAdventurer)
	party.append(secondAdventurer)
	
	return party
