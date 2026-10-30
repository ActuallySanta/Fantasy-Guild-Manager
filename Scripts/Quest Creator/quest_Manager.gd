extends Node

var thisQuest = CreatedQuest
var acceptedQuests: Array[CreatedQuest]
var acceptedQuestResults: Array[String]

var theWindsweptMeadows: Region = Region.new(0)
var theBoglands: Region = Region.new(1)
var theAshenWastes: Region = Region.new(2)
var theGlassMountains: Region = Region.new(3)

var world_regions := [theWindsweptMeadows, theBoglands, theAshenWastes, theGlassMountains]
var total_regions : int = 4

var dayNum = 0;

var testQuestNumber = 0:
	get:
		return testQuestNumber

#@onready var rich_text = $"../LogContents"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thisQuest = CreatedQuest.new()
	var adventurerArray : Array[GuildCharacter]
	var adventurerArrayAgain : Array[GuildCharacter]
	var questResults : String
		
	adventurerArray = thisQuest.generatePartyDuo()
	adventurerArrayAgain.append(adventurerArray[0])
	
	var successChance = thisQuest.calcSuccessChance(adventurerArray)
	print(successChance)
	print(thisQuest.questTitle)
	
	questResults = thisQuest.generateResults(adventurerArrayAgain, successChance)
	acceptedQuestResults.append(questResults)

	testQuestNumber = testQuestNumber + 1
	print(questResults, "\n")
	
	for int in range(10):
		print(theWindsweptMeadows.returnName(0))
		print(theWindsweptMeadows.returnName(1))
		print(theWindsweptMeadows.returnName(2))
		print(theWindsweptMeadows.returnName(3))


	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
