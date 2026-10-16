extends Node

class_name QuestManager
static var instance: QuestManager

var thisQuest = CreatedQuest
var acceptedQuests: Array[CreatedQuest]
var acceptedQuestResults: Array[String]

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
	
	var newRegion = Region.new(0)
	var dungeonNames = newRegion.dungeonNames
	var escortLocations = newRegion.escortLocations
	var explorationAreas = newRegion.explorationAreas
	var intelTargets = newRegion.intelTargets
	
	for int in range(10):
		print(newRegion.returnName(0))
		print(newRegion.returnName(1))
		print(newRegion.returnName(2))
		print(newRegion.returnName(3))


	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null
