extends Resource

class_name CreatedQuest

enum QuestDifficulty{
	F = 0,
	D = 2,
	C = 3,
	B = 4,
	A = 5,
	S = 5
}

enum QuestType{
	DungeonClear = 0,
	#skip 1 for now
	Escort = 2,
}

#enum for preferred stat, link directly to QuestType

#enum for modifiers if we ever choose to do them

var start: String
var middle: String
var end: String

var goldReward: int;
#var for statReward if applicable

var location: String
#var/vars for flavor (characters/items/etc)

var difficulty: QuestDifficulty
var type: QuestType
#var for preffered stat I spelled that wrong
#var for modifier(s) if we ever choose to do that

#need to pull a bunch of stuff out of spreadsheet somehow at some time
#start, middle, end, location, and flavors all need to be pulled out, probably
#at generation - monsters can be pulled out later but only if that's realistic

#don't know yet if this needs to be sent somewhere either, but I assume we want
#this as void regardless
func _init() -> void:
	#set variables
	#generate description -> I don't know if that will be held here or not
	pass

#I assume this should be sending something somewhere but until we figure out
#what & where I'm leaving it on void
#this is the main root method for deciding and generating results I'll have
#methods branch off to decide certain parts of the results
func generateResults(_questingAdventurers: Array[GuildCharacter], 
_successChance: float) -> String:
	#generate characters for now
	
	#put in start text
	
	#loop with size based on difficulty -> higher difficulty more loops
	#each iteration picks combat, search, or to move on faster (starts as very
	#small chance but gets larger each iteration) than the original cut off
	#sends combat or search to its own methods
	
	#once the loop moves on you put the middle if the quest has one and
	#then the loop begins again (again, only if the quest has a middle)
	
	#once the loop moves on we are done here
	#put in end text
	return ""
	
	#FUNCTION FOR SUCCESS CHANCE
		
func _combatEncounter(_fightingAdventurers: Array[GuildCharacter], 
_successChance: float) -> String:
	#generate value, influenced by _successChance and difficulty
	#deals with any changes to the characters based on value, high value means
	#more success, stat ups, etc, low value is worse, injuries or death
	#then it adds to a string and returns the string to the main method
	return ""
		
func _search(_fightingAdventurers: Array[GuildCharacter], 
_successChance: float) -> String:
	#generate value, influenced by _successChance and difficulty
	#deals with any changes to the characters based on value, high value means
	#more success, gold, etc, low value is worse, injuries or death
	#then it adds to a string and returns the string to the main method
	return ""

func generatePartyDuo() -> Array[GuildCharacter]:
	var party : Array[GuildCharacter]
	
	var firstAdventurer = GuildCharacter.new()
	var secondAdventurer = GuildCharacter.new()
	
	party.append(firstAdventurer)
	party.append(secondAdventurer)
	
	return party
