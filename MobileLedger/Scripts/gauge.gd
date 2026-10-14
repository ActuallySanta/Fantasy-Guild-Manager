## Ten-segment rune bar like the reference's success gauge. Drawn, so it
## previews in the editor.
@tool
extends Control

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

@export_range(0.0, 1.0) var value := 0.5:
	set(v):
		value = v
		queue_redraw()
@export var fill := Color("#6FD1A8"):
	set(v):
		fill = v
		queue_redraw()


func set_value(v: float, color: Color) -> void:
	value = v
	fill = color


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_style_box(S.flat(Color("#3A2816"), 10, 0), Rect2(0, 0, w, h))
	var inner := Rect2(10, 8, w - 20, h - 16)
	draw_style_box(S.flat(Color("#5E4A32"), 6, 0), inner)
	var segs := 10
	var gap := 4.0
	var sw := (inner.size.x - gap * (segs - 1)) / segs
	for i in segs:
		var on := (i + 1) / float(segs) <= value + 0.0001
		var rect := Rect2(inner.position.x + i * (sw + gap), inner.position.y + 3, sw, inner.size.y - 6)
		draw_style_box(S.flat(fill if on else Color("#7C6648"), 4, 0), rect)
	# gold end caps
	for x in [4.0, w - 4.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, h / 2 - 12), Vector2(x + (8 if x < 10 else -8), h / 2), Vector2(x, h / 2 + 12)]), S.GOLD)
