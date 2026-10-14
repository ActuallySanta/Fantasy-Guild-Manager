## A recruit for hire (Rows/recruit_card.tscn): portrait, stats, Details + Hire.
extends PanelContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


func setup(ui, c: GuildCharacter, full: bool) -> void:
	%Portrait.show_character(c)
	%CharName.text = c.name
	%Role.text = S.role_name(c)
	%Stats.show_stats(c)
	%DetailsButton.pressed.connect(ui.open_character.bind(c))
	%HireButton.text = "Guild full" if full else "Hire (free)"
	%HireButton.disabled = full
	%HireButton.pressed.connect(ui.hire.bind(c))
