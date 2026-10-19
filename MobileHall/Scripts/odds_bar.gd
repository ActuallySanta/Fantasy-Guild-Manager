## Success-chance bar: a rounded track filled in the odds colour, with faint
## ticks at 25 / 50 / 75%. Drawn in code, no child nodes.
## Scene: MobileHall/Scenes/Components/odds_bar.tscn
extends Control

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

const TRACK_COLOR := Color("#DDDDDD")
const TICK_COLOR := Color(0, 0, 0, 0.15)
## Tick marks, as fractions of the bar's width.
const TICK_POSITIONS := [0.25, 0.5, 0.75]
## Gap between the track's edge and the fill (pixels).
const FILL_INSET := 3

## How full the bar is, 0..1.
var _fill_fraction := 0.0
var _fill_color := Color.WHITE


## chance = 0..100, or -1 for "no party yet" (empty bar).
func set_chance(chance: int) -> void:
	_fill_fraction = clampf(chance / 100.0, 0.0, 1.0) if chance >= 0 else 0.0
	_fill_color = Style.odds_look(chance).text_color
	queue_redraw()


func _draw() -> void:
	var corner_radius := int(size.y / 2)

	# track
	draw_style_box(Style.flat_box(TRACK_COLOR, corner_radius, 0), Rect2(Vector2.ZERO, size))

	# fill (never thinner than a circle, so low odds still show)
	if _fill_fraction > 0.0:
		var fill_width := maxf(size.y, (size.x - FILL_INSET * 2) * _fill_fraction)
		var fill_rect := Rect2(FILL_INSET, FILL_INSET, fill_width, size.y - FILL_INSET * 2)
		draw_style_box(Style.flat_box(_fill_color, corner_radius - FILL_INSET, 0), fill_rect)

	# ticks
	for tick_fraction in TICK_POSITIONS:
		var x: float = size.x * tick_fraction
		draw_line(Vector2(x, 6), Vector2(x, size.y - 6), TICK_COLOR, 2)
