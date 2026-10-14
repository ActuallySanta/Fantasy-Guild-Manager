## A guild member in the Guild sheet's roster. Tap for their details.
## Scene: MobileFlow/Scenes/Rows/member_row.tscn
extends "res://MobileFlow/Scripts/tap_area.gd"

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")

# ---- TEXT
const TEXT_ON_QUEST := "On quest: %s"

# ---- NODES
@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _role: Label = %Role
@onready var _injury = %Injury
@onready var _stats = %Stats
@onready var _on_quest: Label = %OnQuest


func setup(ui: Main, c: GuildCharacter) -> void:
	_portrait.show_character(c)
	_char_name.text = c.name
	_role.text = S.role_name(c)
	_injury.set_injury(c.injury_level)
	_stats.show_stats(c)
	var e: Dictionary = ui.entry_of(c)
	_on_quest.visible = not e.is_empty()
	if not e.is_empty():
		_on_quest.text = TEXT_ON_QUEST % e.quest.questTitle
	pressed.connect(ui.open_character.bind(c))
