## One beat of a quest's story in the Day Report: icon + text.
## Scene: MobileLedger/Scenes/Rows/beat_row.tscn
extends HBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

@onready var _icon: TextureRect = $Icon
@onready var _text: RichTextLabel = $Text


func setup(icon_name: String, tint: Color, bbcode: String) -> void:
	_icon.texture = S.icon_tex(icon_name)
	_icon.modulate = tint
	_text.text = bbcode
