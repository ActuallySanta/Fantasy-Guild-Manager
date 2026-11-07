extends Resource

class_name Region

# These stay res:// paths: plain-text data files have no UID (UIDs are only
# for Godot resources), and FileAccess.open needs a real path. If you move a
# file in External Content, update its path here.
@export var dunegon_locations_test_path: String = "res://External Content/Quest Stuff (Test)/Dungeon Names (Locations).txt" #test path for locations
@export var monsters_2D_test_path: String = "res://External Content/Quest Stuff (Test)/2D Monster Test.txt" #test path for monstrs

@export var meadows_location_path: String = "res://External Content/Quest Stuff (Test)/The Windswept Meadows (Locations).txt"
@export var boglands_location_path: String = "res://External Content/Quest Stuff (Test)/The Boglands (Locations).txt"
@export var wastes_location_path: String = "res://External Content/Quest Stuff (Test)/The Ashen Wastes (Locations).txt"
@export var mountains_location_path: String = "res://External Content/Quest Stuff (Test)/The Glass Mountains (Locations).txt"
@export var city_locations_path: String = "res://External Content/Quest Stuff (Test)/The Capital City (Locations).txt"

enum RegionType {
	theWindsweptMeadows = 0,
	theBoglands = 1,
	theAshenWastes = 2,
	theGlassMountains = 3,
	theCapitalCity = 4,
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
	
	print(regionNum)
	match(regionNum):
		0:
			dungeonNames = (MultiColumnLoader._load_info_from_file(meadows_location_path, 1, 0))
			escortLocations = (MultiColumnLoader._load_info_from_file(meadows_location_path, 1, 1))
			explorationAreas = (MultiColumnLoader._load_info_from_file(meadows_location_path, 1, 2))
			intelTargets = (MultiColumnLoader._load_info_from_file(meadows_location_path, 1, 3))
		1:
			dungeonNames = (MultiColumnLoader._load_info_from_file(boglands_location_path, 1, 0))
			escortLocations = (MultiColumnLoader._load_info_from_file(boglands_location_path, 1, 1))
			explorationAreas = (MultiColumnLoader._load_info_from_file(boglands_location_path, 1, 2))
			intelTargets = (MultiColumnLoader._load_info_from_file(boglands_location_path, 1, 3))
		2:
			dungeonNames = (MultiColumnLoader._load_info_from_file(wastes_location_path, 1, 0))
			escortLocations = (MultiColumnLoader._load_info_from_file(wastes_location_path, 1, 1))
			explorationAreas = (MultiColumnLoader._load_info_from_file(wastes_location_path, 1, 2))
			intelTargets = (MultiColumnLoader._load_info_from_file(wastes_location_path, 1, 3))
		3:
			dungeonNames = (MultiColumnLoader._load_info_from_file(mountains_location_path, 1, 0))
			escortLocations = (MultiColumnLoader._load_info_from_file(mountains_location_path, 1, 1))
			explorationAreas = (MultiColumnLoader._load_info_from_file(mountains_location_path, 1, 2))
			intelTargets = (MultiColumnLoader._load_info_from_file(mountains_location_path, 1, 3))
		4:
			dungeonNames = (MultiColumnLoader._load_info_from_file(city_locations_path, 1, 0))
			escortLocations = (MultiColumnLoader._load_info_from_file(city_locations_path, 1, 1))
			explorationAreas = (MultiColumnLoader._load_info_from_file(city_locations_path, 1, 2))
			intelTargets = (MultiColumnLoader._load_info_from_file(city_locations_path, 1, 3))
	
	if(regionNum >= 0):
		regionMonsters = MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, regionNum)
	else:
		regionMonsters = MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, 0)

func returnName(questType: int) -> String:
	var location = ""
	var searchArray = dungeonNames
	match questType:
			1, 5:
				searchArray = dungeonNames
			2, 6, 8:
				searchArray = escortLocations
			3, 7:
				searchArray = explorationAreas
			4:
				searchArray = intelTargets
	
	location = searchArray[randi_range(0, searchArray.size() - 1)]
	return location

func returnMonster() -> String:
	return regionMonsters[randi_range(0, regionMonsters.size() - 1)]
	
