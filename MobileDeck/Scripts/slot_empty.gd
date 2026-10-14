## An empty party slot on a quest card (Scenes/Rows/slot_empty.tscn).
extends PanelContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")


func setup(size: float) -> void:
	custom_minimum_size = Vector2(size, size)
	add_theme_stylebox_override("panel", S.flat(S.BOX_ALT, int(size * 0.18), 2, S.LINE))
