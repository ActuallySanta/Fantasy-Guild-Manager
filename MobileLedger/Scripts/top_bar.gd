## Back button + small banner title, shared by the full-screen pages.
## Scene: MobileLedger/Scenes/Components/top_bar.tscn
## Set `title` on each instance; listen to back_pressed.
@tool
extends MarginContainer

signal back_pressed

@export var title := "Mission Charter":
	set(v):
		title = v
		if is_node_ready():
			_title.text = v

@onready var _title: Label = %Title
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_title.text = title
	if not Engine.is_editor_hint():
		_back_button.pressed.connect(back_pressed.emit)
