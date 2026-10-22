## Welcome card: how the day works, pointing at the three tabs and the big
## button. Closing it lands on the Board. The text lives in the scene.
## Scene: MobileHall/Scenes/Overlays/overlay_welcome.tscn
extends Control

const S := preload("res://MobileHall/Scripts/hall_style.gd")

@onready var _start_button: Button = %StartButton

var ui


func setup(main) -> void:
	ui = main
	_start_button.pressed.connect(ui.close_welcome)
	S.style_button(_start_button, "gold")


func refresh() -> void:
	pass
