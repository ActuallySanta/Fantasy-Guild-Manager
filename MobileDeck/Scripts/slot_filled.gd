## A filled party slot on a quest card. Tap to remove that adventurer.
## Scene: MobileDeck/Scenes/Rows/slot_filled.tscn
extends Button

const Main := preload("res://MobileDeck/Scripts/deck_main.gd")

const TEXT_NAME := "%s  x"

@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName


func setup(ui: Main, c: GuildCharacter, px: float) -> void:
	custom_minimum_size = Vector2(px, px + 30)
	_portrait.custom_minimum_size = Vector2(px, px)
	_portrait.show_character(c)
	_char_name.text = TEXT_NAME % c.name
	pressed.connect(ui.toggle_draft.bind(c))
