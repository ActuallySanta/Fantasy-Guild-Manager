## One seat in Assign Party's party: portrait + name (tap to take them out),
## or an empty dashed seat.
## Scene: MobileHall/Scenes/Rows/party_slot.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_EMPTY := "Empty"
const TEXT_REMOVE := "tap to remove"

# ---- NODES
@onready var _portrait = %Portrait
@onready var _empty: Label = %EmptyMark
@onready var _name: Label = %SlotName
@onready var _hint: Label = %SlotHint


func setup(main, c: GuildCharacter) -> void:
	var filled := c != null
	_portrait.visible = filled
	_empty.visible = not filled
	if filled:
		_portrait.show_character(c)
		_name.text = c.name
		_hint.text = TEXT_REMOVE
		pressed.connect(main.toggle_pick.bind(c))
		var sb := S.flat(S.CREAM, 16, 3, S.BLUE_TEXT, Vector4(8, 8, 8, 8))
		add_theme_stylebox_override("panel", sb)
	else:
		_name.text = TEXT_EMPTY
		_hint.text = ""
		var sb := S.flat(Color("#F5F5F5"), 16, 3, S.LINE, Vector4(8, 8, 8, 8))
		add_theme_stylebox_override("panel", sb)
