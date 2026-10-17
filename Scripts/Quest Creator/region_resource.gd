extends Resource

class_name Region

@export var dunegon_locations_test_path: String = "res://External Content/Quest Stuff (Test)/Dungeon Names (Locations).txt" #test path for locations
@export var monsters_2D_test_path: String = "res://External Content/Quest Stuff (Test)/2D Monster Test.txt" #test path for monstrs

enum RegionType {
	OG = 0,
	noNamesWhatWeDoin = 1,
}

var dungeonNames: Array[String]:
	get:
		return dungeonNames
var escortLocations: Array[String]:
	get:
		return escortLocations
var explorationAreas: Array[String]:
	get:
		return explorationAreas
var intelTargets: Array[String]:
	get:
		return intelTargets

var regionNumber: RegionType
var regionMonsters: Array[String]:
	get:
		return regionMonsters

func _init(regionNum := 0) -> void:
	regionNumber = regionNum
	dungeonNames = (MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, 0))
	escortLocations = (MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, 1))
	explorationAreas = (MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, 2))
	intelTargets = (MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, 3))
	regionMonsters = MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, regionNum)

func returnName(questType: int) -> String:
	var location = ""
	var searchArray = dungeonNames
	match questType:
			1:
				searchArray = dungeonNames
			2:
				searchArray = escortLocations
			3:
				searchArray = explorationAreas
			4:
				searchArray = intelTargets
	
	location = searchArray[randi_range(0, searchArray.size() - 1)]
	return location

func returnMonster() -> String:
	return regionMonsters[randi_range(0, regionMonsters.size() - 1)]
	
