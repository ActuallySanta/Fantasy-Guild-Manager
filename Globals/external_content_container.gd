extends Node

@export var character_m_names_file_path: String = "res://External Content/Character Names/Character Names - Male Names.csv"
@export var character_f_names_file_path: String = "res://External Content/Character Names/Character Names - Female Names.csv"
@export var character_a_names_file_path: String = "res://External Content/Character Names/Character Names - Androgynous Names.csv"
@export var location_names_file_path: String

@export var knight_backstories_file_path : String = "res://External Content/Character Backstories/Backstories - Knight Backstories.csv"
@export var priest_backstories_file_path : String = "res://External Content/Character Backstories/Backstories - Priest Backstories.csv"
@export var pathfinder_backstories_file_path : String = "res://External Content/Character Backstories/Backstories - Pathfinder Backstories.csv"
@export var mage_backstories_file_path : String = "res://External Content/Character Backstories/Backstories - Mage Backstories.csv"

@export var random_backstories_file_path:String = "res://External Content/Character Backstories/Backstories - Random Backstories.csv"
@export var monsters_test_file_path: String = "res://External Content/Quest Stuff (Test)/Monsters - Sea.txt" #test path for monsters
@export var dunegon_locations_test_path: String = "res://External Content/Quest Stuff (Test)/Dungeon Names (Locations).txt" #test path for locations

#Character Names
var male_character_names: Array[String]
var female_character_names: Array[String]
var andro_character_names: Array[String]

#Backstories
var knight_backstories:Array[String]
var mage_backstories:Array[String]
var pathfinder_backstories : Array[String]
var priest_backstories:Array[String]
var random_backstories:Array[String]

var random_backstories:Array[String]
var monster_test_names: Array[String] #test array for monsters
var dungeon_locations: Array[String] #test array for locations

#Used for text replacement
var child_gender: Array[String] = [
	"daughter",
	"son",
	"child",
]

var pronoun_possesive: Array[String] = [
	"hers",
	"his",
	"theirs",
]

var pronoun_object: Array[String] = [
	"her",
	"him",
	"them",
]

var pronoun_personal_object: Array[String] = [
	"she",
	"he",
	"they",
]

var location_names: Array[String]

#Replace these with the actual UID of the icon
var character_icons: Dictionary[GuildCharacter.CharacterRole, Texture2D] = {
	GuildCharacter.CharacterRole.KNIGHT: preload("uid://deis7oxw14qbl"),
	GuildCharacter.CharacterRole.PRIEST: preload("uid://deis7oxw14qbl"),
	GuildCharacter.CharacterRole.PATHFINDER: preload("uid://deis7oxw14qbl"),
	GuildCharacter.CharacterRole.MAGE: preload("uid://deis7oxw14qbl"),
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	male_character_names = ProceduralContentLoader._load_info_from_file(character_m_names_file_path, 1)
	female_character_names = ProceduralContentLoader._load_info_from_file(character_f_names_file_path, 1)
	andro_character_names = ProceduralContentLoader._load_info_from_file(character_a_names_file_path, 1)
	
	random_backstories = ProceduralContentLoader._load_info_from_file(random_backstories_file_path,1)
	
	knight_backstories = ProceduralContentLoader._load_info_from_file(knight_backstories_file_path,1)	
	priest_backstories = ProceduralContentLoader._load_info_from_file(priest_backstories_file_path,1)
	pathfinder_backstories = ProceduralContentLoader._load_info_from_file(pathfinder_backstories_file_path,1)
	mage_backstories = ProceduralContentLoader._load_info_from_file(mage_backstories_file_path,1)
	monster_test_names = ProceduralContentLoader._load_info_from_file(monsters_test_file_path, 1) #test using monsters
	location_names = ProceduralContentLoader._load_info_from_file(dunegon_locations_test_path, 1) #test using locations
	pass # Replace with function body.


## Get a random name from the array based on the gender
func _get_character_name(gender: GuildCharacter.CharacterGender) -> String:
	match gender:
		GuildCharacter.CharacterGender.MALE:
			return male_character_names[randi_range(0, male_character_names.size() - 1)]
		GuildCharacter.CharacterGender.FEMALE:
			return female_character_names[randi_range(0, female_character_names.size() - 1)]
		GuildCharacter.CharacterGender.ANDROGYNOUS:
			return andro_character_names[randi_range(0, andro_character_names.size() - 1)]
		_:
			return ""

#test functions for quest stuff
func get_Monster_Name() -> String:
	var randMon = randi_range(0, 3)
	return monster_test_names[randMon]
	
func get_Dungeon_Name() -> String:
	var randDungeon = randi_range(0, 5)
	return location_names[randDungeon]


func _get_character_icon(_role: GuildCharacter.CharacterRole) -> Texture2D:
	return character_icons[_role]


func _get_role_backstory(_char:GuildCharacter) -> String:
	var _backstory = ""
	
	#Pick a random background template
	match _char.role:
		GuildCharacter.CharacterRole.KNIGHT:
			_backstory = knight_backstories.pick_random()
		GuildCharacter.CharacterRole.PRIEST:
			_backstory = priest_backstories.pick_random()
		GuildCharacter.CharacterRole.PATHFINDER:
			_backstory = pathfinder_backstories.pick_random()
		GuildCharacter.CharacterRole.MAGE:
			_backstory = mage_backstories.pick_random()
	
	#Replace all the stand-ins
	_backstory = _replace_standins(_backstory,_char)
	
	return _backstory

#Pick a random backstory, sanitize it, and return it, based on the character
func _get_random_backstory(_char:GuildCharacter) -> String:
	var _backstory= random_backstories.pick_random()
	_backstory = _replace_standins(_backstory,_char)
	return _backstory

func _replace_standins(_backstory:String,_char:GuildCharacter)->String:
		#Replace all the stand-ins
	_backstory = _backstory.replace("[NAME]",_char.name)
	_backstory = _backstory.replace("[GENDER_CHILD]",child_gender[_char.gender])
	_backstory = _backstory.replace("[PRONOUN_OBJ]",pronoun_object[_char.gender])
	_backstory = _backstory.replace("[PRONOUN_POS]",pronoun_possesive[_char.gender])
	_backstory = _backstory.replace("[PRONOUN_PERS_OBJ]",pronoun_personal_object[_char.gender])
	
	
	
	return _backstory
