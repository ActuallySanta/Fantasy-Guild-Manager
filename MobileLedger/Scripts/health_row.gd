## One adventurer in the Home tab's health list. Tap for their codex.
## Scene: MobileLedger/Scenes/Rows/health_row.tscn
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

const TEXT_SUB := "%s · %s"

@onready var _tap: Button = %Tap
@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _sub: Label = %Sub
@onready var _injury = %Injury
@onready var _line: Control = %Line


func setup(ui: Main, c: GuildCharacter, last: bool) -> void:
	_portrait.show_character(c)
	_char_name.text = c.name
	_sub.text = TEXT_SUB % [S.role_name(c), S.injury_count(c)]
	_injury.set_injury(c.injury_level)
	_line.visible = not last
	_tap.pressed.connect(ui.open_codex.bind(c))
