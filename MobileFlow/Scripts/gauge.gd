## Plain progress bar: grey track, coloured fill. Drawn, so it previews in the editor.
@tool
extends Control

const S := preload("res://MobileFlow/Scripts/flow_style.gd")

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
	draw_rect(Rect2(Vector2.ZERO, size), Color("#DDDDDD"))
	draw_rect(Rect2(0, 0, size.x * clampf(value, 0.0, 1.0), size.y), fill)
	draw_rect(Rect2(Vector2.ZERO, size), S.LINE, false, 1.0)
