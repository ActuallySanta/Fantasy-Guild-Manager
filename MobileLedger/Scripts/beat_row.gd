## One beat of a quest's story in the Day Report (Scenes/Rows/beat_row.tscn).
extends HBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func setup(icon_name: String, tint: Color, bbcode: String) -> void:
	$Icon.texture = S.icon_tex(icon_name)
	$Icon.modulate = tint
	$Text.text = bbcode
