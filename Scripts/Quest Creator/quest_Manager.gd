extends Node

class_name QuestManager
static var instance: QuestManager

var thisQuest = CreatedQuest
var acceptedQuests: Array[CreatedQuest]
var acceptedQuestResults: Array[String]

var testQuestNumber = 0:
	get:
		return testQuestNumber

@onready var rich_text = $"../LogContents"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thisQuest = CreatedQuest.new()
	var adventurerArray : Array[GuildCharacter]
	var adventurerArrayAgain : Array[GuildCharacter]
	var questResults : String
		
	adventurerArray = thisQuest.generatePartyDuo()
	adventurerArrayAgain.append(adventurerArray[0])
	print(thisQuest.calcSuccessChance(adventurerArray))
	
	questResults = thisQuest.generateResults(adventurerArrayAgain, 80.0)
	acceptedQuestResults.append(questResults)

	testQuestNumber = testQuestNumber + 1
	print(questResults, "\n")
	
	thisQuest = CreatedQuest.new()
	adventurerArray = thisQuest.generatePartyDuo()
	print(thisQuest.calcSuccessChance(adventurerArray))
	
	questResults = thisQuest.generateResults(adventurerArray, 80.0)
	acceptedQuestResults.append(questResults)
	
	testQuestNumber = testQuestNumber + 1
	print(questResults, "\n")
	
	thisQuest = CreatedQuest.new()
	adventurerArray = thisQuest.generatePartyDuo()
	print(thisQuest.calcSuccessChance(adventurerArray))

	questResults = thisQuest.generateResults(adventurerArray, 80.0)
	acceptedQuestResults.append(questResults)
	
	print(questResults, "\n")
	
	if rich_text != null :
		rich_text.changeText(acceptedQuestResults)
	
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null
