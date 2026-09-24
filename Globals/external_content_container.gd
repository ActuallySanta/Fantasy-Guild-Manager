extends Node
@export var character_m_names_file_path : String
@export var character_f_names_file_path : String
@export var character_a_names_file_path : String
@export var location_names_file_path : String

#Character Names
var male_character_names :Array[String]
var female_character_names :Array[String]
var andro_character_names : Array[String]


var location_names : Array[String]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	male_character_names = ProceduralContentLoader._load_info_from_file(character_m_names_file_path)
	female_character_names = ProceduralContentLoader._load_info_from_file(character_f_names_file_path)
	andro_character_names = ProceduralContentLoader._load_info_from_file(character_m_names_file_path)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
