extends Node

var thisQuest = CreatedQuest

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	thisQuest = CreatedQuest.new()
	var adventurerArray : Array[GuildCharacter]
	adventurerArray = thisQuest.generatePartyDuo()
	var questResults : String
	questResults = thisQuest.generateResults(adventurerArray, 80.0)
	print(questResults, "\n")
	
	thisQuest = CreatedQuest.new()
	adventurerArray = thisQuest.generatePartyDuo()
	questResults = thisQuest.generateResults(adventurerArray, 80.0)
	print(questResults, "\n")
	
	thisQuest = CreatedQuest.new()
	adventurerArray = thisQuest.generatePartyDuo()
	questResults = thisQuest.generateResults(adventurerArray, 80.0)
	print(questResults, "\n")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
