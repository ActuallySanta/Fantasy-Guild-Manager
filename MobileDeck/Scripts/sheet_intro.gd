## How-to-play card.
## Scene: MobileDeck/Scenes/Sheets/sheet_intro.tscn
## All the wording is in the scene; this only wires the Start button.
extends ColorRect

const Main := preload("res://MobileDeck/Scripts/deck_main.gd")

@onready var _start_button: Button = %StartButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_start_button.pressed.connect(func(): ui.close_sheet())


func refresh() -> void:
	pass
