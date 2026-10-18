## One line of a quest's story in the Day Report: icon + text.
## Scene: MobileHall/Scenes/Rows/beat_row.tscn
extends HBoxContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

@onready var _icon: TextureRect = $Icon
@onready var _text: RichTextLabel = $Text


func setup(icon_name: String, tint: Color, bbcode: String) -> void:
	_icon.texture = S.icon_tex(icon_name)
	_icon.modulate = tint
	_text.text = bbcode
