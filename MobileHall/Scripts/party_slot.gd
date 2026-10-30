## One seat in Assign Party's party: a pinned card with portrait, name, role and
## their value in the quest's favored stat (tap to take them out), or an empty
## seat waiting for someone.
## Scene: MobileHall/Scenes/Rows/party_slot.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

## Empty seats fade back.
const EMPTY_SEAT_OPACITY := 0.55

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_EMPTY := "Empty seat"
const TEXT_EMPTY_HINT := "pin someone below"

# ---- NODES
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %SlotName
@onready var _hint: Label = %SlotHint
@onready var _favored_chip = %FavChip         # chip.gd


## seated = the adventurer in this seat, or null for an empty seat.
func setup(hall: HallMain, entry: Dictionary, seated: GuildCharacter) -> void:
	var is_filled := seated != null
	_portrait.visible = is_filled
	_favored_chip.visible = is_filled
	if is_filled:
		_portrait.show_character(seated)
		_name.text = seated.name
		_hint.text = TEXT_ROLE % Style.role_name(seated)
		_favored_chip.set_stat(seated, Style.favored_stat_index(entry.quest), true)
		pressed.connect(hall.toggle_in_party.bind(seated))
	else:
		_name.text = TEXT_EMPTY
		_hint.text = TEXT_EMPTY_HINT
		Style.set_font_color(_name, Style.TEXT_SOFT)
		modulate = Color(1, 1, 1, EMPTY_SEAT_OPACITY)
