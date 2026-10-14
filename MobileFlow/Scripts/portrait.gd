## Character portrait (Components/portrait.tscn): the project's role headshot
## in a plain bordered square. Set the size with custom_minimum_size.
extends PanelContainer


func show_character(c: GuildCharacter) -> void:
	var role: int = c.role if c else 0
	$Art.texture = ExternalContentContainer.get_character_icon(role)
	$Art.modulate = Color(1, 1, 1, 0.35) if c and c.injury_level >= GuildCharacter.InjuryLevel.DEAD else Color.WHITE
