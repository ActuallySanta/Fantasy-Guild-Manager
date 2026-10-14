## One quest in the End Day step's "Today's plan". Tap to revisit it.
## Scene: MobileFlow/Scenes/Rows/plan_row.tscn
extends VBoxContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")

# ---- TEXT
const TEXT_SENT := "%s, %d%%"
const TEXT_DENIED := "Denied"
const TEXT_UNDECIDED := "Not decided"

# ---- NODES
@onready var _tap: Button = %Tap
@onready var _quest_name: Label = %QuestName
@onready var _status = %Status
@onready var _line: Control = %Line


func setup(ui: Main, i: int, last: bool) -> void:
	var e: Dictionary = ui.entries[i]
	_quest_name.text = e.quest.questTitle
	match e.state:
		"ready":
			_status.set_chip(TEXT_SENT % [S.names(e.party), mini(ui.chance_for(e, e.party), 100)], S.GOOD_BG, S.GOOD)
		"denied":
			_status.set_chip(TEXT_DENIED, S.BAD_BG, S.BAD)
		_:
			_status.set_chip(TEXT_UNDECIDED, S.WARN_BG, S.WARN)
	_line.visible = not last
	_tap.pressed.connect(ui.show_quest.bind(i))
