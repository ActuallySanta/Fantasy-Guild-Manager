# Keeps the header's numbers in sync with GameState
extends PanelContainer
@export var day_label: Label
@export var gold_label: Label
@export var standing_label: Label

func _ready() -> void:
	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(_refresh_resources)
	
	# show starting values right away
	_on_day_started(GameState.day)
	_refresh_resources()
 
func _on_day_started(day: int) -> void:
	if day_label:
		day_label.text = "Day %d " % day
 
func _refresh_resources() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % GameState.gold
	if standing_label:
		standing_label.text = "Standing: %d" % GameState.standing
