extends Control

@onready var guild_character_page: Control = $"Popup Pages/Guild Character Page"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_char_button_pressed() -> void:
	guild_character_page.show()
	pass # Replace with function body.
