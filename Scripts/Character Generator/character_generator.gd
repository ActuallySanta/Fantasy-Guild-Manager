extends Node2D

const CHARACTER_UI_CARD = preload("uid://dc26k5nacd1ik")

var characters : Array[GuildCharacter]
func _ready() -> void:
	characters.resize(5)
	for character in characters:
		character = GuildCharacter.new()
		

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("Spawn Card")):
		var ui_card = CHARACTER_UI_CARD.instantiate()
		add_child(ui_card)
