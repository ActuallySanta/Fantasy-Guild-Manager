## One card of today's deck, shown as a dot above the card.
## Scene: MobileDeck/Scenes/Rows/progress_dot.tscn
extends Panel

const S := preload("res://MobileDeck/Scripts/deck_style.gd")

const SIZE := 10
const SIZE_CURRENT := 16


func setup(color: Color, current: bool) -> void:
	var sz := SIZE_CURRENT if current else SIZE
	custom_minimum_size = Vector2(sz, sz)
	add_theme_stylebox_override("panel", S.flat(color, sz, 0))
