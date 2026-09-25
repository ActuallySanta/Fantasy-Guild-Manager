extends Node2D

var characters : Array[GuildCharacter]
func _ready() -> void:
	characters.resize(5)
	for character in characters:
		character = GuildCharacter.new()
