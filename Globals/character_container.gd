extends Node2D

@export var max_characters: int = 5
@export var active_characters: Array[GuildCharacter]

## How many characters will be shown at the character hiring screen
@export var max_hireable_characters: int = 3

signal on_character_added


func _ready() -> void:
	#for i in max_characters:
	#generate_new_character()
	pass


func generate_new_character() -> void:
	if (active_characters.size() == max_characters):
		return

	var _new_char := GuildCharacter.new()
	active_characters.append(_new_char)
	print("NEW CHARACTER GENERATED: " + _new_char.name)
	pass


func add_character_to_guild(_character: GuildCharacter) -> bool:
	if (active_characters.size() == max_characters):
		return false

	active_characters.append(_character)
	print(_character.name + " HAS JOINED THE GUILD")
	on_character_added.emit()
	return true
