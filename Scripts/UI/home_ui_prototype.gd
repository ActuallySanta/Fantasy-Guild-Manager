extends Control

const GUILD_CHARACTER_PAGE = preload("uid://daweenf55s77m")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_char_button_pressed() -> void:
	var _char_page := GUILD_CHARACTER_PAGE.instantiate()
	add_child(_char_page)
	pass # Replace with function body.
