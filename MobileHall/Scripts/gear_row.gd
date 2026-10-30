## One line in a hero's Gear section (screen_character.gd):
##   - an equipped item, with Take off
##   - an empty slot, with Equip (opens the pick list) / Cancel
##   - an owned item in the pick list, with Equip / Take (if someone else has it)
## Rarity tag on the left, name and what it does, one button on the right.
## Scene: MobileHall/Scenes/Rows/gear_row.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const EMPTY_TAG := "+"

# ---- LOOK
const PICK_BG := Color("#EAF2FA")

# ---- NODES
@onready var _tag: PanelContainer = %Tag
@onready var _tag_text: Label = %TagText
@onready var _name: Label = %ItemName
@onready var _effect: Label = %Effect
@onready var _button: Button = %ActionButton


## look: Style.item_look(item). button_text "" hides the button.
## is_choice: a row in the pick list (tinted blue).
func setup(look: Dictionary, button_text: String, button_kind: String, on_press: Callable, is_choice := false) -> void:
	Style.style_tag(_tag, _tag_text, look.tag, look.color)
	_name.text = look.name
	_effect.text = look.effect
	Style.set_font_color(_name, Style.TEXT_MAIN)
	if is_choice:
		Style.style_panel(self, PICK_BG, Style.BLUE_TEXT, 3)
	else:
		Style.style_panel(self, Style.CARD_BG, Style.BORDER, 3)
	_set_button(button_text, button_kind, on_press)


## An empty gear slot.
func setup_empty(label: String, hint: String, button_text: String, button_kind: String, on_press: Callable) -> void:
	Style.style_tag(_tag, _tag_text, EMPTY_TAG, Style.BORDER)
	_name.text = label
	_effect.text = hint
	Style.set_font_color(_name, Style.TEXT_SOFT)
	Style.style_panel(self, Style.EMPTY_SEAT_BG, Style.BORDER, 3)
	_set_button(button_text, button_kind, on_press)


func _set_button(button_text: String, button_kind: String, on_press: Callable) -> void:
	_button.visible = button_text != ""
	if button_text == "":
		return
	_button.text = button_text
	Style.style_button(_button, button_kind, 22)
	_button.pressed.connect(on_press)
