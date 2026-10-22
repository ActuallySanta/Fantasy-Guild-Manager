## One quest in Assign Party's strip: a little scroll with the quest number on
## a band in its type colour (green = sent, red = denied), and the type tag
## (or SENT / NO) under it. The quest being shown has a parchment band.
## Scene: MobileHall/Scenes/Rows/quest_tab.tscn
extends VBoxContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

## Band colour on the quest being shown.
const CURRENT_BAND := Color("#F0E7D2")

# ---- TEXT
const MARK := "%d"
const TAG_SENT := "SENT"
const TAG_DENIED := "NO"

# ---- NODES
@onready var _tab: Button = %Tab
@onready var _band: Panel = %Band
@onready var _mark: Label = %Mark
@onready var _tag: Label = %Tag


func setup(main, index: int, current: bool) -> void:
	var e: Dictionary = main.entries[index]
	_tab.pressed.connect(main.open_assign.bind(index))
	_mark.text = MARK % (index + 1)
	var info := S.type_info(e)
	var band: Color = info.color
	_tag.text = info.tag
	match e.state:
		"ready":
			_tag.text = TAG_SENT
			band = S.GREEN_TEXT
		"denied":
			_tag.text = TAG_DENIED
			band = S.WAX
	S.tint(_band, CURRENT_BAND if current else band)
	S.color(_mark, S.INK if current else S.CREAM)
	S.color(_tag, S.CREAM if current else S.CREAM_SOFT)
