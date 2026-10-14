## First-launch card explaining the three steps of each day.
## Scene: MobileFlow/Scenes/Overlays/overlay_intro.tscn
## All the wording is in the scene; this only wires the Start button.
extends ColorRect

const Main := preload("res://MobileFlow/Scripts/flow_main.gd")

@onready var _start_button: Button = %StartButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_start_button.pressed.connect(func(): ui.close_intro())


func refresh() -> void:
	pass
