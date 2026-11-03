## A panel you can tap, that still lets its ScrollContainer scroll when you
## drag across it. Rows that open something extend this script and connect
## to `pressed` (quest_row, pick_row, party_slot, member_card, today_item).
class_name TapPanel
extends PanelContainer

## Emitted on a tap: press and release without moving more than TAP_MOVE_LIMIT.
signal pressed

## A press that moves further than this (pixels) is a scroll, not a tap.
const TAP_MOVE_LIMIT := 24.0

## True between a left press on this panel and its release.
var _is_pressing := false
## Where that press started (global coordinates).
var _press_position := Vector2.ZERO


func _init() -> void:
	# PASS (not STOP) so a drag still reaches the parent ScrollContainer
	mouse_filter = MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	# only left mouse button / touch presses matter
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		_is_pressing = true
		_press_position = mouse_event.global_position
	elif _is_pressing:
		_is_pressing = false
		var moved_distance := mouse_event.global_position.distance_to(_press_position)
		if moved_distance < TAP_MOVE_LIMIT:
			pressed.emit()
