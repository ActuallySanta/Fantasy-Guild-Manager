## A guild member on the Characters tab. Tap for their codex.
## Scene: MobileLedger/Scenes/Rows/roster_card.tscn
extends "res://MobileLedger/Scripts/tap_area.gd"

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

const TEXT_ROLE := "the %s"
const TEXT_QUESTING := "Questing: %s"

@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _role: Label = %Role
@onready var _questing: Label = %Questing
@onready var _injury = %Injury
@onready var _stats = %Stats


func setup(ui: Main, c: GuildCharacter) -> void:
	_portrait.show_character(c)
	_char_name.text = c.name
	_role.text = TEXT_ROLE % S.role_name(c)
	var e: Dictionary = ui.entry_of(c)
	_questing.visible = not e.is_empty()
	if not e.is_empty():
		_questing.text = TEXT_QUESTING % e.quest.questTitle
	_injury.set_injury(c.injury_level)
	_stats.show_stats(c)
	pressed.connect(ui.open_codex.bind(c))
