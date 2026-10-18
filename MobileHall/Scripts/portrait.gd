## Character portrait: the project's role art on a soft painted ground, with an
## ink frame. Set the size on each instance with custom_minimum_size.
## Scene: MobileHall/Scenes/Components/portrait.tscn
extends Panel

const S := preload("res://MobileHall/Scripts/hall_style.gd")

const ROUNDNESS := 0.22
const DEAD_TINT := Color(0.6, 0.55, 0.62)

@export var circle := true

@onready var _art: TextureRect = $Art
@onready var _frame: Panel = $Frame


func show_character(c: GuildCharacter) -> void:
	var px := custom_minimum_size.x
	var radius := int(px / 2) if circle else int(px * ROUNDNESS)
	add_theme_stylebox_override("panel", S.flat(S.ROLE_GROUNDS[clampi(c.role, 0, 3)], radius, 0))
	var frame := S.flat(Color(0, 0, 0, 0), radius, 3, S.INK)
	frame.draw_center = false
	_frame.add_theme_stylebox_override("panel", frame)
	_art.texture = ExternalContentContainer.get_character_icon(c.role)
	_art.modulate = DEAD_TINT if S.is_dead(c) else Color.WHITE
