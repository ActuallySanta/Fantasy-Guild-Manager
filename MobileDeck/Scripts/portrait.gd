## Character portrait: the project's role headshot clipped to a rounded square.
## Scene: MobileDeck/Scenes/Components/portrait.tscn
## Set the size on each instance with custom_minimum_size; corners follow it.
@tool
extends Panel

const S := preload("res://MobileDeck/Scripts/deck_style.gd")

const GROUND := Color("#C9CBD6")
## Corner radius as a fraction of the size.
const ROUNDNESS := 0.18
## Dead adventurers are shown faded.
const DEAD_FADE := Color(1, 1, 1, 0.3)

@onready var _art: TextureRect = $Art


func _ready() -> void:
	_round_corners()
	resized.connect(_round_corners)


func show_character(c: GuildCharacter) -> void:
	_art.texture = ExternalContentContainer.get_character_icon(c.role)
	_art.modulate = DEAD_FADE if c.injury_level >= GuildCharacter.InjuryLevel.DEAD else Color.WHITE


func _round_corners() -> void:
	add_theme_stylebox_override("panel", S.flat(GROUND, int(custom_minimum_size.x * ROUNDNESS), 0))
