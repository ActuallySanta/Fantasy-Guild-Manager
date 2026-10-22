## One seat in Assign Party's party: a pinned card with portrait, name, role and
## their value in the quest's favored stat (tap to take them out), or an empty
## seat waiting for someone.
## Scene: MobileHall/Scenes/Rows/party_slot.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const S := preload("res://MobileHall/Scripts/hall_style.gd")

const EMPTY_FADE := Color(1, 1, 1, 0.55)

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_EMPTY := "Empty seat"
const TEXT_EMPTY_HINT := "pin someone below"

# ---- NODES
@onready var _portrait = %Portrait
@onready var _name: Label = %SlotName
@onready var _hint: Label = %SlotHint
@onready var _fav = %FavChip


func setup(main, e: Dictionary, c: GuildCharacter) -> void:
	var filled := c != null
	_portrait.visible = filled
	_fav.visible = filled
	if filled:
		_portrait.show_character(c)
		_name.text = c.name
		_hint.text = TEXT_ROLE % S.role_name(c)
		_fav.set_stat(c, S.favored_index(e.quest), true)
		pressed.connect(main.toggle_pick.bind(c))
	else:
		_name.text = TEXT_EMPTY
		_hint.text = TEXT_EMPTY_HINT
		S.color(_name, S.INK_SOFT)
		modulate = EMPTY_FADE
