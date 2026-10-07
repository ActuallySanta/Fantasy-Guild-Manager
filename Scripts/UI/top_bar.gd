# Keeps the header's numbers in sync with GameState
extends PanelContainer
@export var day_label: Label

func _ready() -> void:
	GameState.day_started.connect(_on_day_started)
	_show_day(GameState.day)  # show "Day 1" right away
 
func _on_day_started(day: int) -> void:
	_show_day(day)
 
func _show_day(day: int) -> void:
	if day_label:
		day_label.text = "Day %d" % day
