## One quest in Assign Party's strip: its number and type tag, coloured by state
## (white = open, blue = party picked, green SENT = sent, red NO = denied,
## thick dark outline = showing).
## Scene: MobileHall/Scenes/Rows/quest_tab.tscn
extends Button

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const MARK := "%d"
const TAG_SENT := "SENT"
const TAG_DENIED := "NO"

# ---- NODES
@onready var _tag: Label = %Tag
@onready var _mark: Label = %Mark


func setup(main, index: int, current: bool) -> void:
	var e: Dictionary = main.entries[index]
	pressed.connect(main.open_assign.bind(index))
	_tag.text = S.type_info(e).tag
	_mark.text = MARK % (index + 1)
	var fill := S.CREAM
	var edge := S.BLUE_TEXT
	match e.state:
		"ready":
			_tag.text = TAG_SENT
			fill = S.GREEN_BG
			edge = S.GREEN
		"denied":
			_tag.text = TAG_DENIED
			fill = S.WAX_BG
			edge = S.WAX
		_:
			if not e.party.is_empty():
				fill = S.BLUE_BG
	S.color(_mark, edge)
	S.color(_tag, edge)
	var border := 5 if current else 2
	var sb := S.flat(fill if not current else fill.lightened(0.3), 14, border, edge if not current else S.INK, Vector4(4, 4, 4, 4))
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		add_theme_stylebox_override(st, sb)
