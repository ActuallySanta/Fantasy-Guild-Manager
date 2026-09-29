extends AnimatedButton
class_name CharacterDisplayButton

const CHARACTER_UI_CARD = preload("res://Scenes/Characters/character_ui_card.tscn")

var held_character : GuildCharacter




func _on_pressed() -> void:
	var display_card:= CHARACTER_UI_CARD.instantiate() as CharacterUICard
	display_card.loaded_character = held_character
	get_tree().current_scene.add_child(display_card)
