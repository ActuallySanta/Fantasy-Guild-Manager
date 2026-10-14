## Back button + small banner title, shared by the full-screen pages
## (Scenes/Components/top_bar.tscn).
@tool
extends MarginContainer

signal back_pressed

@export var title := "Mission Charter":
	set(v):
		title = v
		if is_node_ready():
			%Title.text = v


func _ready() -> void:
	%Title.text = title
	if not Engine.is_editor_hint():
		%BackButton.pressed.connect(back_pressed.emit)
