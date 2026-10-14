## One adventurer in the Mission Charter's roster (Scenes/Rows/charter_pick_row.tscn).
extends "res://MobileLedger/Scripts/tap_area.gd"

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func setup(screen, e: Dictionary, c: GuildCharacter, draft: Array, n: int) -> void:
	var ui = screen.ui
	var chosen := draft.has(c)
	var full := not chosen and n > 1 and draft.size() >= n
	var elsewhere: Dictionary = ui.entry_of(c)
	if not elsewhere.is_empty() and elsewhere == e:
		elsewhere = {}
	%Card.add_theme_stylebox_override("panel", S.panel_box("ready" if chosen else "card", Vector4(18, 14, 18, 14)))
	%Portrait.show_character(c)
	%CharName.text = c.name
	%Injury.set_injury(c.injury_level)
	var fav := S.favored_index(e.quest)
	for i in 4:
		var st: Dictionary = S.STATS[i]
		get_node("%%Stat%d" % i).set_icon_chip(st.icon, str(c.stats[i]), st.bg, st.color, -1, i == fav)
	%Note.visible = not elsewhere.is_empty() or full
	if not elsewhere.is_empty():
		%Note.text = "On \"%s\" · picking moves them" % elsewhere.quest.questTitle
		%Note.add_theme_color_override("font_color", S.BLUE_TEXT)
	elif full:
		%Note.text = "Party is full"
		%Note.add_theme_color_override("font_color", S.INK_SOFT)
	%Contribution.text = "+%d%%" % ui.chance_for(e, [c])
	%CheckBox.add_theme_stylebox_override("panel", S.flat(Color("#3F7A2E") if chosen else S.CREAM, 10, 3, S.INK, Vector4(6, 6, 6, 6)))
	%Check.visible = chosen
	disabled = full
	if full:
		%Card.modulate = Color(1, 1, 1, 0.55)
	pressed.connect(screen.toggle.bind(c))
