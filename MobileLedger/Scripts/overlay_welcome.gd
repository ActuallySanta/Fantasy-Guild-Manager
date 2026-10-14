## Welcome card: the intro blurb, split into four short steps.
## Scene: MobileLedger/Scenes/Overlays/overlay_welcome.tscn
## All the wording is in the scene; this only wires the button.
extends ColorRect

const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

@onready var _open_button: Button = %OpenButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_open_button.pressed.connect(func(): ui.close_welcome())


func refresh() -> void:
	pass
