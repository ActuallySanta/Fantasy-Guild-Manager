## Recruit card face (Scenes/Cards/card_hire.tscn): swipe right to hire, left to pass.
extends VBoxContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")

var ui


func setup(main) -> void:
	ui = main


func refresh() -> void:
	var c: GuildCharacter = ui.current().character
	%Portrait.show_character(c)
	%CharName.text = c.name
	%Role.text = "the %s" % S.role_name(c)
	%Stats.show_stats(c)
	var lines := c.description.strip_edges().split("\n")
	%Story.text = lines[0] if lines.size() > 0 else ""
	%Hint.visible = ui.room() > 0
	%FullNote.visible = ui.room() <= 0
	%Hint.text = "Swipe right to hire, left to pass.\nRoom for %d more in your guild." % ui.room()
