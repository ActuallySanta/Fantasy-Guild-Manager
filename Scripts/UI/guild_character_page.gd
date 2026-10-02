extends Control

@onready var drag_drop_grid: DragDropGrid = $"MarginContainer/VBoxContainer/ScrollContainer/Drag Drop Grid"
const CHARACTER_DISPLAY_BUTTON = preload("uid://byy6otbkss2ac")
const CHARACTER_HIRING_PAGE = preload("uid://bo10juj3x7m8u")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_load_characters_onto_page)
	_load_characters_onto_page()
	CharacterContainer.on_character_added.connect(_load_characters_onto_page)
	pass # Replace with function body.


func _load_characters_onto_page():
	for characters in CharacterContainer.active_characters:
		var _char_icon := CHARACTER_DISPLAY_BUTTON.instantiate()
		_char_icon.held_character = characters
		_char_icon.icon = ExternalContentContainer.get_character_icon(characters.role)
		_char_icon.text = characters.title
		drag_drop_grid.add_child(_char_icon)
		pass


func _on_close_button_pressed() -> void:
	queue_free()


func _on_hire_new_characters_button_pressed() -> void:
	var hiring_page := CHARACTER_HIRING_PAGE.instantiate()
	add_child(hiring_page)
