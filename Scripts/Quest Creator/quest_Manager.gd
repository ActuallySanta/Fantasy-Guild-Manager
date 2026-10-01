extends Node

var thisQuest = CreatedQuest
var acceptedQuests: Array[CreatedQuest]
var acceptedQuestResults: Array[String]

@onready var rich_text = $"../LogContents"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	print("My node: ", name)
	print("My parent: ", get_parent().name)
	print("Children of parent: ", get_parent().get_children())
	
	thisQuest = CreatedQuest.new()
	var adventurerArray : Array[GuildCharacter]
	adventurerArray = thisQuest.generatePartyDuo()
	var questResults : String
	questResults = thisQuest.generateResults(adventurerArray, 80.0)
	
	acceptedQuestResults.append(questResults)
	
	print(thisQuest.questTitle)
	print(questResults, "\n")
	print(thisQuest.questSummary)
	
	thisQuest = CreatedQuest.new()
	adventurerArray = thisQuest.generatePartyDuo()
	questResults = thisQuest.generateResults(adventurerArray, 80.0)
	
	acceptedQuestResults.append(questResults)
	
	print(thisQuest.questTitle)
	print(questResults, "\n")
	print(thisQuest.questSummary)
	
	thisQuest = CreatedQuest.new()
	adventurerArray = thisQuest.generatePartyDuo()
	questResults = thisQuest.generateResults(adventurerArray, 80.0)
	
	acceptedQuestResults.append(questResults)
	
	print(thisQuest.questTitle)
	print(questResults, "\n")
	print(thisQuest.questSummary)
	
	if rich_text != null :
		rich_text.changeText(acceptedQuestResults)
	
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
