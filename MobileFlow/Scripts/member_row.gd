## A guild member in the Guild sheet's roster (Rows/member_row.tscn). Tap for details.
extends "res://MobileFlow/Scripts/tap_area.gd"

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


func setup(ui, c: GuildCharacter) -> void:
	%Portrait.show_character(c)
	%CharName.text = c.name
	%Role.text = S.role_name(c)
	%Injury.set_injury(c.injury_level)
	%Stats.show_stats(c)
	var e: Dictionary = ui.entry_of(c)
	%OnQuest.visible = not e.is_empty()
	if not e.is_empty():
		%OnQuest.text = "On quest: %s" % e.quest.questTitle
	pressed.connect(ui.open_character.bind(c))
