## One adventurer on the Home tab's health list (Scenes/Rows/health_row.tscn).
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func setup(ui, c: GuildCharacter, last: bool) -> void:
	%Portrait.show_character(c)
	%CharName.text = c.name
	%Sub.text = "%s · %s" % [S.role_name(c), "no injuries yet" if c.injury_count == 0 else "%d injur%s" % [c.injury_count, "y" if c.injury_count == 1 else "ies"]]
	%Injury.set_injury(c.injury_level)
	%Line.visible = not last
	%Tap.pressed.connect(ui.open_codex.bind(c))
