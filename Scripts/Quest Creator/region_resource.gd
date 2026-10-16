extends Resource

class_name Region

@export var dunegon_locations_test_path: String = "res://External Content/Quest Stuff (Test)/Dungeon Names (Locations).txt" #test path for locations

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

func _init(regionNum := 0) -> void:
	regionNumber = regionNum
	dungeonNames = (MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, 0))
	escortLocations = (MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, 1))
	explorationAreas = (MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, 2))
	intelTargets = (MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, 3))

func returnName(questType: int) -> String:
	var location = ""
	var searchArray = dungeonNames
	match questType:
			0:
				searchArray = dungeonNames
			1:
				searchArray = escortLocations
			2:
				searchArray = explorationAreas
			3:
				searchArray = intelTargets
	
	location = searchArray[randi_range(0, searchArray.size() - 1)]
	return location
