## An empty party slot on a quest card ("+").
## Scene: MobileDeck/Scenes/Rows/slot_empty.tscn
extends PanelContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")


func setup(px: float) -> void:
	custom_minimum_size = Vector2(px, px)
	add_theme_stylebox_override("panel", S.flat(S.BOX_ALT, int(px * 0.18), 2, S.LINE))
