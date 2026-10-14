## One adventurer in the Quests step's party picker (Rows/pick_row.tscn).
extends "res://MobileFlow/Scripts/tap_area.gd"

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


func setup(ui, e: Dictionary, c: GuildCharacter, n: int) -> void:
	var chosen: bool = ui.draft.has(c)
	var full: bool = not chosen and n > 1 and ui.draft.size() >= n
	var elsewhere: Dictionary = ui.entry_of(c)
	if not elsewhere.is_empty() and elsewhere == e:
		elsewhere = {}
	%Card.add_theme_stylebox_override("panel", S.flat(S.INFO_BG if chosen else S.BOX, 0, 1, S.INFO if chosen else S.LINE, Vector4(12, 10, 12, 10)))
	%Check.button_pressed = chosen
	%Portrait.show_character(c)
	%CharName.text = c.name
	%Injury.set_injury(c.injury_level)
	%Stats.show_stats(c, S.favored_index(e.quest), false)
	%Note.visible = not elsewhere.is_empty() or full
	if not elsewhere.is_empty():
		%Note.text = "Already on \"%s\". Picking moves them here." % elsewhere.quest.questTitle
		%Note.add_theme_color_override("font_color", S.INFO)
	elif full:
		%Note.text = "Party is full"
		%Note.add_theme_color_override("font_color", S.INK_SOFT)
	%Adds.text = "+%d%%" % ui.chance_for(e, [c])
	disabled = full
	if full:
		%Card.modulate = Color(1, 1, 1, 0.5)
	pressed.connect(ui.toggle_draft.bind(c))
