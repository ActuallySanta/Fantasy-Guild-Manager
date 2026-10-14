## Character portrait (Scenes/Components/portrait.tscn): the project's role
## headshot clipped to a rounded square. Set the size with custom_minimum_size;
## the corner radius follows it.
@tool
extends Panel

const S := preload("res://MobileDeck/Scripts/deck_style.gd")


func _ready() -> void:
	_round()
	resized.connect(_round)


func _round() -> void:
	add_theme_stylebox_override("panel", S.flat(Color("#C9CBD6"), int(custom_minimum_size.x * 0.18), 0))


func show_character(c: GuildCharacter) -> void:
	var role: int = c.role if c else 0
	$Art.texture = ExternalContentContainer.get_character_icon(role)
	$Art.modulate = Color(1, 1, 1, 0.3) if c and c.injury_level >= GuildCharacter.InjuryLevel.DEAD else Color.WHITE
