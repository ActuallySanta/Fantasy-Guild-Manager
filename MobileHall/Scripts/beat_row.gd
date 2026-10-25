## One line of a quest's story in the Day Report: icon + text.
## Scene: MobileHall/Scenes/Rows/beat_row.tscn
extends HBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- NODES
@onready var _icon: TextureRect = $Icon
@onready var _text: RichTextLabel = $Text


## icon_name = a name from hall_style ICON_FILES; bbcode = the story line.
func setup(icon_name: String, icon_tint: Color, bbcode: String) -> void:
	_icon.texture = Style.icon_texture(icon_name)
	_icon.modulate = icon_tint
	_text.text = bbcode
