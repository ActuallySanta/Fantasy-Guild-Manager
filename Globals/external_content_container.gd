extends Node

@export var character_m_names_file_path: String = "res://External Content/Character Names/Character Names - Male Names.csv"
@export var character_f_names_file_path: String = "res://External Content/Character Names/Character Names - Female Names.csv"
@export var character_a_names_file_path: String = "res://External Content/Character Names/Character Names - Androgynous Names.csv"
@export var location_names_file_path: String

#Character Names
var male_character_names: Array[String]
var female_character_names: Array[String]
var andro_character_names: Array[String]

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
	pass


func _get_character_icon(_role: GuildCharacter.CharacterRole) -> Texture2D:
	return character_icons[_role]


func _get_role_backstory(role: GuildCharacter.CharacterRole) -> String:
	return ""


func _get_random_backstory(_lines: int) -> String:
	return ""
