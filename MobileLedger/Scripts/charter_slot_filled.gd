## A chosen adventurer in the Mission Charter's party slots. Tap to remove.
extends "res://MobileLedger/Scripts/tap_area.gd"


func setup(screen, c: GuildCharacter) -> void:
	%Portrait.show_character(c)
	%CharName.text = c.name
	pressed.connect(screen.toggle.bind(c))
