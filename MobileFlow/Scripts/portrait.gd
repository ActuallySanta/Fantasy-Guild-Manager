## Character portrait: the project's role headshot in a plain bordered square.
## Scene: MobileFlow/Scenes/Components/portrait.tscn
## Set the size on each instance with custom_minimum_size.
extends PanelContainer

## Dead adventurers are shown faded.
const DEAD_FADE := Color(1, 1, 1, 0.35)

@onready var _art: TextureRect = $Art


func show_character(c: GuildCharacter) -> void:
	_art.texture = ExternalContentContainer.get_character_icon(c.role)
	_art.modulate = DEAD_FADE if c.injury_level >= GuildCharacter.InjuryLevel.DEAD else Color.WHITE
