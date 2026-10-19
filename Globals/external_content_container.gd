extends Node

@export var character_m_names_file_path: String = "res://External Content/Character Names/Character Names - Male Names.csv"
@export var character_f_names_file_path: String = "res://External Content/Character Names/Character Names - Female Names.csv"
@export var character_a_names_file_path: String = "res://External Content/Character Names/Character Names - Androgynous Names.csv"
@export var location_names_file_path: String

@export var knight_backstories_file_path: String = "res://External Content/Character Backstories/Backstories - Knight Backstories.csv"
@export var priest_backstories_file_path: String = "res://External Content/Character Backstories/Backstories - Priest Backstories.csv"
@export var pathfinder_backstories_file_path: String = "res://External Content/Character Backstories/Backstories - Pathfinder Backstories.csv"
@export var mage_backstories_file_path: String = "res://External Content/Character Backstories/Backstories - Mage Backstories.csv"
@export var random_backstories_file_path: String = "res://External Content/Character Backstories/Backstories - Random Backstories.csv"

@export var dunegon_locations_test_path: String = "res://External Content/Quest Stuff (Test)/Dungeon Names (Locations).txt" #test path for locations
@export var monsters_2D_test_path: String = "res://External Content/Quest Stuff (Test)/2D Monster Test.txt" #test path for monstrs
@export var quest_story_test_path: String = "res://External Content/Quest Stuff (Test)/Story Parts.txt" #test path
@export var milestone_story_path: String = "res://External Content/Quest Stuff (Test)/Milestone Story Parts.txt"

#Character Names
var male_character_names: Array[String]
var female_character_names: Array[String]
var andro_character_names: Array[String]

#Backstories
var knight_backstories: Array[String]
var mage_backstories: Array[String]
var pathfinder_backstories: Array[String]
var priest_backstories: Array[String]
var random_backstories: Array[String]

var monster_test_names = [] #test array for monsters
var location_names = [] #test array for locations
var quest_story = []
var milestone_story = []

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

#Replace these with the actual UID of the icon
var character_icons: Dictionary[GuildCharacter.CharacterRole, Texture2D] = {
	GuildCharacter.CharacterRole.KNIGHT: preload("uid://0nieya7vg7ir"),
	GuildCharacter.CharacterRole.PRIEST: preload("uid://dwkwfcgs6qeya"),
	GuildCharacter.CharacterRole.PATHFINDER: preload("uid://dqfofkh0uu3x3"),
	GuildCharacter.CharacterRole.MAGE: preload("uid://bw0opsv6knijq"),
}

var knight_icons: Array[Texture2D] = [
	preload("uid://0nieya7vg7ir"),
	preload("uid://cuuceb25ns6i2"),
]

var priest_icons: Array[Texture2D] = [
	preload("uid://dwkwfcgs6qeya"),
	preload("uid://blln7mdskhtgk"),
]

var pathfinder_icons: Array[Texture2D] = [
	preload("uid://dqfofkh0uu3x3"),
	preload("uid://bf0c247tg34tw"),
]

var mage_icons: Array[Texture2D] = [
	preload("uid://bw0opsv6knijq"),
	preload("uid://bo8xpib0s758d"),
]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	male_character_names = ProceduralContentLoader._load_info_from_file(character_m_names_file_path, 1)
	female_character_names = ProceduralContentLoader._load_info_from_file(character_f_names_file_path, 1)
	andro_character_names = ProceduralContentLoader._load_info_from_file(character_a_names_file_path, 1)

	random_backstories = ProceduralContentLoader._load_info_from_file(random_backstories_file_path, 1)

	knight_backstories = ProceduralContentLoader._load_info_from_file(knight_backstories_file_path, 1)
	priest_backstories = ProceduralContentLoader._load_info_from_file(priest_backstories_file_path, 1)
	pathfinder_backstories = ProceduralContentLoader._load_info_from_file(pathfinder_backstories_file_path, 1)
	mage_backstories = ProceduralContentLoader._load_info_from_file(mage_backstories_file_path, 1)

	monster_test_names.append(MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, 0)) #2D test
	monster_test_names.append(MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, 1))
	monster_test_names.append(MultiColumnLoader._load_info_from_file(monsters_2D_test_path, 1, 2))

	for i in range(8):
		quest_story.append(MultiColumnLoader._load_info_from_rows(quest_story_test_path, i))

	for i in range(1):
		milestone_story.append(MultiColumnLoader._load_info_from_rows(milestone_story_path, i))

	for i in range(4):
		location_names.append(MultiColumnLoader._load_info_from_file(dunegon_locations_test_path, 1, i))
	pass # Replace with function body.


## Get a random name from the array based on the gender
func get_character_name(gender: GuildCharacter.CharacterGender) -> String:
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
func get_Monster_Name(col_idx: int) -> String:
	var randMon = randi_range(0, 5)
	return monster_test_names[col_idx][randMon]


func get_Location_Name(col_idx: int) -> String:
	var randLoc = randi_range(0, 5)
	return location_names[col_idx][randLoc]


func get_Quest_Story(quest_idx: int, story_part: int) -> String:
	return quest_story[quest_idx][story_part]


func get_Milestone_story(quest_idx: int, story_part: int) -> String:
	return milestone_story[quest_idx][story_part]


func get_character_icon(_role: GuildCharacter.CharacterRole) -> Texture2D:
	match _role:
		GuildCharacter.CharacterRole.KNIGHT:
			return knight_icons.pick_random()
		GuildCharacter.CharacterRole.PRIEST:
			return priest_icons.pick_random()
		GuildCharacter.CharacterRole.PATHFINDER:
			return pathfinder_icons.pick_random()
		GuildCharacter.CharacterRole.MAGE:
			return mage_icons.pick_random()
		_:
			return null


func get_role_backstory(_char: GuildCharacter) -> String:
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
	_backstory = replace_standins(_backstory, _char)

	return _backstory


#Pick a random backstory, sanitize it, and return it, based on the character
func get_random_backstory(_char: GuildCharacter) -> String:
	var _backstory = random_backstories.pick_random()
	_backstory = replace_standins(_backstory, _char)
	return _backstory


func replace_standins(_backstory: String, _char: GuildCharacter) -> String:
	#Replace all the stand-ins
	_backstory = _backstory.replace("[NAME]", _char.name)
	_backstory = _backstory.replace("[GENDER_CHILD]", child_gender[_char.gender])
	_backstory = _backstory.replace("[PRONOUN_OBJ]", pronoun_object[_char.gender])
	_backstory = _backstory.replace("[PRONOUN_POS]", pronoun_possesive[_char.gender])
	_backstory = _backstory.replace("[PRONOUN_PERS_OBJ]", pronoun_personal_object[_char.gender])

	return _backstory
