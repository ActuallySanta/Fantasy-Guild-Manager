## One quest on the end-of-day card. Tap to go back and change it.
## Scene: MobileDeck/Scenes/Rows/plan_row.tscn
extends VBoxContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const Main := preload("res://MobileDeck/Scripts/deck_main.gd")

# ---- TEXT
const TEXT_SENT := "%s · %d%%"
const TEXT_DENIED := "Denied"
const TEXT_UNDECIDED := "Undecided"

@onready var _tap: Button = %Tap
@onready var _quest_name: Label = %QuestName
@onready var _status = %Status


func setup(ui: Main, e: Dictionary) -> void:
	_quest_name.text = e.quest.questTitle
	match e.state:
		"ready":
			_status.set_chip(TEXT_SENT % [S.names(e.party), mini(ui.chance_for(e, e.party), 100)], S.GOOD_BG, S.GOOD, -1, false)
		"denied":
			_status.set_chip(TEXT_DENIED, S.BAD_BG, S.BAD, -1, false)
		_:
			_status.set_chip(TEXT_UNDECIDED, S.WARN_BG, S.WARN, -1, false)
	_tap.pressed.connect(ui.jump_to_entry.bind(e))
