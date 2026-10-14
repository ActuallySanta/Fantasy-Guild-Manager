## A whole-row tappable area: a flat Button whose first child (the row's
## visible content) fills it. Keeps the button as tall as that content.
## Row scripts that should be tappable extend this script.
extends Button

## Never shorter than this, even if the content is.
@export var min_height := 0.0


func _ready() -> void:
	var content := get_child(0) as Control
	content.minimum_size_changed.connect(_fit_to_content)
	_fit_to_content()


func _fit_to_content() -> void:
	var content := get_child(0) as Control
	custom_minimum_size.y = maxf(min_height, content.get_combined_minimum_size().y)
