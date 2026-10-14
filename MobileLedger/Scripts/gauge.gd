## Ten-segment rune bar like the reference's success gauge.
## Drawn in code (no child nodes), so it previews in the editor; set `value`
## and `fill` in the Inspector, or call set_value() at runtime.
@tool
extends Control

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

const SEGMENTS := 10
const SEGMENT_GAP := 4.0
const FRAME := Color("#3A2816")
const TRACK := Color("#5E4A32")
const SEGMENT_OFF := Color("#7C6648")

## 0 = empty, 1 = full.
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
	draw_style_box(S.flat(FRAME, 10, 0), Rect2(0, 0, w, h))
	var inner := Rect2(10, 8, w - 20, h - 16)
	draw_style_box(S.flat(TRACK, 6, 0), inner)
	var seg_w := (inner.size.x - SEGMENT_GAP * (SEGMENTS - 1)) / SEGMENTS
	for i in SEGMENTS:
		var lit := (i + 1) / float(SEGMENTS) <= value + 0.0001
		var rect := Rect2(inner.position.x + i * (seg_w + SEGMENT_GAP), inner.position.y + 3, seg_w, inner.size.y - 6)
		draw_style_box(S.flat(fill if lit else SEGMENT_OFF, 4, 0), rect)
	# gold end caps
	for x in [4.0, w - 4.0]:
		var point := 8 if x < 10 else -8
		draw_colored_polygon(PackedVector2Array([Vector2(x, h / 2 - 12), Vector2(x + point, h / 2), Vector2(x, h / 2 + 12)]), S.GOLD)
