## A guild member on the Characters tab (Scenes/Rows/roster_card.tscn). Tap for the codex.
extends "res://MobileLedger/Scripts/tap_area.gd"

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func setup(ui, c: GuildCharacter) -> void:
	%Portrait.show_character(c)
	%CharName.text = c.name
	%Role.text = "the %s" % S.role_name(c)
	var e: Dictionary = ui.entry_of(c)
	%Questing.visible = not e.is_empty()
	if not e.is_empty():
		%Questing.text = "Questing: %s" % e.quest.questTitle
	%Injury.set_injury(c.injury_level)
	%Stats.show_stats(c)
	pressed.connect(ui.open_codex.bind(c))
