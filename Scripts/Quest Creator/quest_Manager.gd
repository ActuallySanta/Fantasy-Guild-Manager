extends Node

var thisQuest = CreatedQuest
var acceptedQuests: Array[CreatedQuest]
var acceptedQuestResults: Array[String]

@export var monsters_2D_test_path: String = "res://External Content/Quest Stuff (Test)/QuestMonsters.txt"

var theWindsweptMeadows: Region = Region.new(0)
var theBoglands: Region = Region.new(1)
var theAshenWastes: Region = Region.new(2)
var theGlassMountains: Region = Region.new(3)
var theCapitalCity: Region = Region.new(4)

var world_regions := [theWindsweptMeadows, theBoglands, theAshenWastes, theGlassMountains, theCapitalCity]
var total_regions : int = 4

var dayNum = 0;

var testQuestNumber = 0:
	get:
		return testQuestNumber

var questMonsters = [MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, 0), MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, 1), 
MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, 2), MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, 3)]
	
	
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
	
	questResults = thisQuest.generateResults(adventurerArrayAgain, successChance)
	acceptedQuestResults.append(questResults)

	testQuestNumber = testQuestNumber + 1
	pass

func _returnQuestMonster(col_idx: int) -> String:
	print(col_idx)
	return questMonsters[col_idx][randi_range(0, 1)]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
