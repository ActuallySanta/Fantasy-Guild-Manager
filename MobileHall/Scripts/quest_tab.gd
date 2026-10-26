## One quest in Assign Party's strip: its number and type tag, coloured by state
## (white = open, blue = party picked, green SENT = sent, red NO = denied,
## thick dark outline = the quest showing now).
## Scene: MobileHall/Scenes/Rows/quest_tab.tscn
extends Button

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

## Border width for the quest showing now vs. the others.
const CURRENT_BORDER_WIDTH := 5
const OTHER_BORDER_WIDTH := 2

# ---- TEXT
const TEXT_NUMBER := "%d"
const TAG_SENT := "SENT"
const TAG_DENIED := "NO"

# ---- NODES
@onready var _tag: Label = %Tag
@onready var _number: Label = %Mark


func setup(hall: HallMain, quest_index: int, is_current: bool) -> void:
	var entry: Dictionary = hall.quest_entries[quest_index]
	pressed.connect(hall.open_assign.bind(quest_index))
	_number.text = TEXT_NUMBER % (quest_index + 1)

	# tag text and colours by state
	var fill := Style.CARD_BG
	var edge_color := Style.BLUE_TEXT
	match entry.state:
		Style.QUEST_STATE_SENT:
			_tag.text = TAG_SENT
			fill = Style.GREEN_BG
			edge_color = Style.GREEN
		Style.QUEST_STATE_DENIED:
			_tag.text = TAG_DENIED
			fill = Style.RED_BG
			edge_color = Style.RED
		_:
			_tag.text = Style.quest_type_info(entry).tag
			if not entry.party.is_empty():
				fill = Style.BLUE_BG
	Style.set_font_color(_number, edge_color)
	Style.set_font_color(_tag, edge_color)

	# the current quest gets a lighter fill and a thick dark border
	if is_current:
		fill = fill.lightened(0.3)
	var border_width := CURRENT_BORDER_WIDTH if is_current else OTHER_BORDER_WIDTH
	var border_color := Style.TEXT_MAIN if is_current else edge_color
	var box := Style.flat_box(fill, 14, border_width, border_color, Vector4(4, 4, 4, 4))
	for box_state in Style.BUTTON_BOX_STATES:
		add_theme_stylebox_override(box_state, box)
