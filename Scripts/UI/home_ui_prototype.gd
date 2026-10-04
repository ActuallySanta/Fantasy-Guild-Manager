extends Control

@onready var guild_character_page: Control = $"MarginContainer/VBoxContainer/Content/Guild Character Page"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_char_button_pressed() -> void:
	guild_character_page.show()
	pass # Replace with function body.
