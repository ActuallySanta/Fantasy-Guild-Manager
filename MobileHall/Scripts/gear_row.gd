## One line in a hero's Gear section (screen_character.gd):
##   - an equipped item, with Take off
##   - an empty slot, with Equip (opens the pick list) / Cancel
##   - an owned item in the pick list, with Equip / Take (if someone else has it)
## Rarity tag on the left, name and what it does, one button on the right.
## Scene: MobileHall/Scenes/Rows/gear_row.tscn
extends PanelContainer


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


## look: HallStyle.item_look(item). button_text "" hides the button.
## is_choice: a row in the pick list (tinted blue).
func setup(look: Dictionary, button_text: String, button_kind: String, on_press: Callable, is_choice := false) -> void:
	HallStyle.style_tag(_tag, _tag_text, look.tag, look.color)
	_name.text = look.name
	_effect.text = look.effect
	HallStyle.set_font_color(_name, HallStyle.TEXT_MAIN)
	if is_choice:
		HallStyle.style_panel(self, PICK_BG, HallStyle.BLUE_TEXT, 3)
	else:
		HallStyle.style_panel(self, HallStyle.CARD_BG, HallStyle.BORDER, 3)
	_set_button(button_text, button_kind, on_press)


## An empty gear slot.
func setup_empty(label: String, hint: String, button_text: String, button_kind: String, on_press: Callable) -> void:
	HallStyle.style_tag(_tag, _tag_text, EMPTY_TAG, HallStyle.BORDER)
	_name.text = label
	_effect.text = hint
	HallStyle.set_font_color(_name, HallStyle.TEXT_SOFT)
	HallStyle.style_panel(self, HallStyle.EMPTY_SEAT_BG, HallStyle.BORDER, 3)
	_set_button(button_text, button_kind, on_press)


func _set_button(button_text: String, button_kind: String, on_press: Callable) -> void:
	_button.visible = button_text != ""
	if button_text == "":
		return
	_button.text = button_text
	HallStyle.style_button(_button, button_kind, 24)
	_button.pressed.connect(on_press)
