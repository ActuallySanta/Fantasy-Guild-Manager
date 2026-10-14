## One card in today's deck, shown as a dot (Scenes/Rows/progress_dot.tscn).
extends Panel

const S := preload("res://MobileDeck/Scripts/deck_style.gd")


func setup(color: Color, current: bool) -> void:
	var sz := 16 if current else 10
	custom_minimum_size = Vector2(sz, sz)
	add_theme_stylebox_override("panel", S.flat(color, sz, 0))
