## One adventurer in the roster tray (Scenes/Rows/tray_tile.tscn).
## On a quest card, tap to add / remove them; otherwise tap for details.
extends Button

const S := preload("res://MobileDeck/Scripts/deck_style.gd")


func setup(ui, ch: GuildCharacter) -> void:
	var chosen: bool = ui.draft.has(ch)
	var busy: Dictionary = ui.entry_of(ch)
	var sb := S.flat(S.INFO_BG if chosen else S.BOX, 16, 1, S.INFO if chosen else S.LINE, Vector4(6, 6, 6, 6))
	sb.set_border_width_all(3 if chosen else 1)
	for s in ["normal", "hover", "pressed", "hover_pressed"]:
		add_theme_stylebox_override(s, sb)
	%Portrait.show_character(ch)
	%CharName.text = ch.name
	var inj: Array = S.INJURY[clampi(ch.injury_level, 0, 4)]
	var free: bool = busy.is_empty() or chosen
	%Status.text = inj[0] if free else "On a quest"
	%Status.add_theme_color_override("font_color", inj[2] if free else S.INFO)
	pressed.connect(ui.toggle_draft.bind(ch))
