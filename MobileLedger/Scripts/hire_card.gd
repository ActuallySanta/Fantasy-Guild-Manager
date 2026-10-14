## A recruit on the Characters tab's For Hire half (Scenes/Rows/hire_card.tscn).
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func setup(ui, c: GuildCharacter, full: bool) -> void:
	%Portrait.show_character(c)
	%CharName.text = c.name
	var total: int = c.stats[0] + c.stats[1] + c.stats[2] + c.stats[3]
	%Sub.text = "the %s · stat total %d" % [S.role_name(c), total]
	%CodexButton.pressed.connect(ui.open_codex.bind(c))
	%Stats.show_stats(c)
	%Blurb.text = c.description.strip_edges().split("\n")[0]
	%HireButton.text = "Guild full · upgrade Barracks" if full else "Hire %s (free)" % c.name
	%HireButton.disabled = full
	%HireButton.pressed.connect(ui.hire.bind(c))
