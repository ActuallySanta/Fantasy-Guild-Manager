## Welcome card: how the day works, pointing at the three tabs and the big
## button. Closing it lands on the Board. The text lives in the scene.
## Scene: MobileHall/Scenes/Overlays/overlay_welcome.tscn
extends Control

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

# ---- NODES
@onready var _start_button: Button = %StartButton

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_start_button.pressed.connect(hall.close_welcome)
	Style.style_button(_start_button, "green", 32)


## Nothing changes while it's open; hall_main calls this on every overlay.
func refresh() -> void:
	pass
