## A chosen adventurer in the Mission Charter's round slots. Tap to remove them.
## Scene: MobileLedger/Scenes/Rows/charter_slot_filled.tscn
extends "res://MobileLedger/Scripts/tap_area.gd"

const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName


func setup(ui: Main, c: GuildCharacter) -> void:
	_portrait.show_character(c)
	_char_name.text = c.name
	pressed.connect(ui.toggle_charter_pick.bind(c))
