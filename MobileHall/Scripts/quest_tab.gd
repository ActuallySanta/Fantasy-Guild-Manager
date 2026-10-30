## One quest in Assign Party's strip: a little scroll with the quest number on
## a band in its type colour (green = sent, red = denied), and the type tag
## (or SENT / NO) under it. The quest showing now has a parchment band.
## Scene: MobileHall/Scenes/Rows/quest_tab.tscn
extends VBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

## Band colour on the quest showing now.
const CURRENT_BAND := Color("#F0E7D2")

# ---- TEXT
const TEXT_NUMBER := "%d"
const TAG_SENT := "SENT"
const TAG_DENIED := "NO"

# ---- NODES
@onready var _tab: Button = %Tab
@onready var _band: Panel = %Band
@onready var _number: Label = %Mark
@onready var _tag: Label = %Tag


func setup(hall: HallMain, quest_index: int, is_current: bool) -> void:
	var entry: Dictionary = hall.quest_entries[quest_index]
	_tab.pressed.connect(hall.open_assign.bind(quest_index))
	_number.text = TEXT_NUMBER % (quest_index + 1)

	# tag text and band colour by state
	var type_info := Style.quest_type_info(entry)
	var band_color: Color = type_info.color
	_tag.text = type_info.tag
	match entry.state:
		Style.QUEST_STATE_SENT:
			_tag.text = TAG_SENT
			band_color = Style.GREEN_TEXT
		Style.QUEST_STATE_DENIED:
			_tag.text = TAG_DENIED
			band_color = Style.RED
	Style.tint_art(_band, CURRENT_BAND if is_current else band_color)
	Style.set_font_color(_number, Style.TEXT_MAIN if is_current else Style.CREAM)
	Style.set_font_color(_tag, Style.CREAM if is_current else Style.CREAM_SOFT)
