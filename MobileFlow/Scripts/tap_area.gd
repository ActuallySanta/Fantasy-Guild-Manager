## A whole-row tappable area: a flat Button whose first child (the row's
## visible content) fills it. Keeps the button as tall as that content.
extends Button

@export var min_height := 0.0


func _ready() -> void:
	var child := get_child(0) as Control
	child.minimum_size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var child := get_child(0) as Control
	custom_minimum_size.y = maxf(min_height, child.get_combined_minimum_size().y)
