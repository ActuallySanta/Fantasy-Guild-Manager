extends MarginContainer

@onready var close_button: AnimatedButton = $"Close Button"


func _on_close_button_pressed() -> void:
	visible = false
	pass # Replace with function body.
