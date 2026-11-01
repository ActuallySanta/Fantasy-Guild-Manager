## One hero on the Game Over ledger's roll call: an icon for their fate
## (skull = fell, arrow = released, heart = still on the roster), their name
## and role, and a line saying what became of them.
## Scene: MobileHall/Scenes/Rows/roll_call_row.tscn
extends HBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_NAME := "%s · %s"
const TEXT_FELL := "Fell at %s, Day %d"
## A fallen hero whose quest wasn't recorded (e.g. a playtest scenario's roster).
const TEXT_FELL_UNKNOWN := "Fell in service"
const TEXT_RELEASED := "Released from the guild"
const TEXT_REMAINS := "Still with the guild (%s)"

# ---- NODES
@onready var _icon: TextureRect = %Icon
@onready var _name: Label = %Name
@onready var _fate: Label = %Fate


## character = the hero, was_released = they were let go this run (living or not).
func setup(character: GuildCharacter, was_released: bool) -> void:
	_name.text = TEXT_NAME % [character.name, Style.role_name(character)]

	var icon_name := "heart"
	var ink := Style.GREEN_TEXT
	if Style.is_dead(character):
		icon_name = "skull"
		ink = Style.INJURY_LOOKS[GuildCharacter.InjuryLevel.DEAD].text
		if character.died_on_quest != "" and character.died_on_day >= 0:
			_fate.text = TEXT_FELL % [character.died_on_quest, character.died_on_day]
		else:
			_fate.text = TEXT_FELL_UNKNOWN
	elif was_released:
		icon_name = "back"
		ink = Style.TEXT_SOFT
		_fate.text = TEXT_RELEASED
	else:
		_fate.text = TEXT_REMAINS % Style.injury_look(character).label.to_lower()

	_icon.texture = Style.icon_texture(icon_name)
	_icon.modulate = ink
	Style.set_font_color(_name, ink)
