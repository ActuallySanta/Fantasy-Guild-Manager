## Plain progress bar: grey track, coloured fill.
## Drawn in code (no child nodes), so it previews in the editor; set `value`
## and `fill` in the Inspector, or call set_value() at runtime.
@tool
extends Control

const S := preload("res://MobileFlow/Scripts/flow_style.gd")

const TRACK := Color("#DDDDDD")

## 0 = empty, 1 = full.
@export_range(0.0, 1.0) var value := 0.5:
	set(v):
		value = v
		queue_redraw()
@export var fill := Color("#555555"):
	set(v):
		fill = v
		queue_redraw()


func set_value(v: float, color: Color) -> void:
	value = v
	fill = color


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), TRACK)
	draw_rect(Rect2(0, 0, size.x * clampf(value, 0.0, 1.0), size.y), fill)
	draw_rect(Rect2(Vector2.ZERO, size), S.LINE, false, 1.0)
