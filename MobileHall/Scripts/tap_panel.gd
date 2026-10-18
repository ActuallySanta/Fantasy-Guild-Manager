## A panel you can tap, that still lets its ScrollContainer scroll when you
## drag across it. Rows that open something extend this script.
extends PanelContainer

signal pressed

## A press that moves further than this (pixels) is a scroll, not a tap.
const MOVE_LIMIT := 24.0

var _down := false
var _down_pos := Vector2.ZERO


func _init() -> void:
	mouse_filter = MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
			_down_pos = event.global_position
		elif _down:
			_down = false
			if event.global_position.distance_to(_down_pos) < MOVE_LIMIT:
				pressed.emit()
