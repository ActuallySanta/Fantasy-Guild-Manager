## A filled party slot on the Quests step: portrait + name (Rows/slot_filled.tscn).
extends VBoxContainer


func show_character(c: GuildCharacter) -> void:
	%Portrait.show_character(c)
	%CharName.text = c.name
