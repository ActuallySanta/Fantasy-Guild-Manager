## Character portrait: the project's role art on a soft coloured background,
## with a dark frame. Set the size on each instance with custom_minimum_size.
## Scene: MobileHall/Scenes/Components/portrait.tscn
extends Panel

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

## Corner radius as a fraction of the width when `circle` is off.
const SQUARE_CORNER_FRACTION := 0.22
const FRAME_WIDTH := 3
## Greys out the art of dead adventurers.
const DEAD_TINT := Color(0.6, 0.55, 0.62)

## Round portrait (true) or rounded square (false). Set per instance in the scenes.
@export var circle := true

# ---- NODES
@onready var _art: TextureRect = $Art
@onready var _frame: Panel = $Frame


func show_character(character: GuildCharacter) -> void:
	var width := custom_minimum_size.x
	var corner_radius := int(width / 2) if circle else int(width * SQUARE_CORNER_FRACTION)

	# background colour by role
	var role_index := clampi(character.role, 0, Style.ROLE_PORTRAIT_BGS.size() - 1)
	add_theme_stylebox_override("panel", Style.flat_box(Style.ROLE_PORTRAIT_BGS[role_index], corner_radius, 0))

	# frame on top: border only, no fill
	var frame_box := Style.flat_box(Color(0, 0, 0, 0),corner_radius, FRAME_WIDTH, Style.TEXT_MAIN)
	frame_box.draw_center = false
	_frame.add_theme_stylebox_override("panel", frame_box)

	# role art
	_art.texture = character.icon
	_art.modulate = DEAD_TINT if Style.is_dead(character) else Color.WHITE
