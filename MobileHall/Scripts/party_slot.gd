## One seat in Assign Party's party: portrait + name (tap to take them out),
## or an empty seat.
## Scene: MobileHall/Scenes/Rows/party_slot.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

const SEAT_PADDING := Vector4(8, 8, 8, 8)

# ---- TEXT
const TEXT_EMPTY := "Empty"
const TEXT_TAP_TO_REMOVE := "tap to remove"

# ---- NODES
@onready var _portrait = %Portrait            # portrait.gd
@onready var _empty_mark: Label = %EmptyMark
@onready var _name: Label = %SlotName
@onready var _hint: Label = %SlotHint


## seated = the adventurer in this seat, or null for an empty seat.
func setup(hall: HallMain, seated: GuildCharacter) -> void:
	var is_filled := seated != null
	_portrait.visible = is_filled
	_empty_mark.visible = not is_filled
	if is_filled:
		_portrait.show_character(seated)
		_name.text = seated.name
		_hint.text = TEXT_TAP_TO_REMOVE
		pressed.connect(hall.toggle_in_party.bind(seated))
		add_theme_stylebox_override("panel", Style.flat_box(Style.CARD_BG, 16, 3, Style.BLUE_TEXT, SEAT_PADDING))
	else:
		_name.text = TEXT_EMPTY
		_hint.text = ""
		add_theme_stylebox_override("panel", Style.flat_box(Style.EMPTY_SEAT_BG, 16, 3, Style.BORDER, SEAT_PADDING))
