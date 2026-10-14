## Rounded progress bar.
## Drawn in code (no child nodes), so it previews in the editor; set `value`
## and `fill` in the Inspector, or call set_value() at runtime.
@tool
extends Control

const S := preload("res://MobileDeck/Scripts/deck_style.gd")

## 0 = empty, 1 = full.
@export_range(0.0, 1.0) var value := 0.5:
	set(v):
		value = v
		queue_redraw()
@export var fill := Color("#42A5F5"):
	set(v):
		fill = v
		queue_redraw()


func set_value(v: float, color: Color) -> void:
	value = v
	fill = color


func _draw() -> void:
	var radius := int(size.y / 2)
	draw_style_box(S.flat(S.BOX_ALT, radius, 0), Rect2(Vector2.ZERO, size))
	var w := size.x * clampf(value, 0.0, 1.0)
	if w > 1.0:
		draw_style_box(S.flat(fill, radius, 0), Rect2(0, 0, maxf(w, size.y), size.y))
