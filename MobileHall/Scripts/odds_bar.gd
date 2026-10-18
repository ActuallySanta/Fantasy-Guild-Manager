## Success-chance bar: a rounded track filled in the odds colour.
## Drawn in code, no child nodes.
## Scene: MobileHall/Scenes/Components/odds_bar.tscn
extends Control

const S := preload("res://MobileHall/Scripts/hall_style.gd")

const TRACK := Color("#DDDDDD")
const TICK := Color(0, 0, 0, 0.15)

var _value := 0.0
var _fill := Color.WHITE


## chance = 0..100, or -1 for "no party yet".
func set_chance(chance: int) -> void:
	_value = clampf(chance / 100.0, 0.0, 1.0) if chance >= 0 else 0.0
	_fill = S.odds(chance)[1]
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var radius := int(size.y / 2)
	draw_style_box(S.flat(TRACK, radius, 0), r)
	if _value > 0.0:
		var w := maxf(size.y, (size.x - 6) * _value)
		draw_style_box(S.flat(_fill, radius - 3, 0), Rect2(3, 3, w, size.y - 6))
	for k in [0.25, 0.5, 0.75]:
		var x: float = size.x * k
		draw_line(Vector2(x, 6), Vector2(x, size.y - 6), TICK, 2)
