## A filled party slot on the Quests step: portrait + name.
## Scene: MobileFlow/Scenes/Rows/slot_filled.tscn
extends VBoxContainer

@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName


func show_character(c: GuildCharacter) -> void:
	_portrait.show_character(c)
	_char_name.text = c.name
