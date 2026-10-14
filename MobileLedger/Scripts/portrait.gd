## Character portrait: the project's role art clipped to a circle or rounded
## square on a soft painted ground, with an ink frame.
## Scene: MobileLedger/Scenes/Components/portrait.tscn
## Set the size on each instance with custom_minimum_size, and tick `circle`
## for round ones.
@tool
extends Panel

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

## Corner radius of the rounded square, as a fraction of the size.
const ROUNDNESS := 0.18
## How far the art is nudged down inside the frame, as a fraction of the size.
const ART_DROP := 0.06
const DEAD_TINT := Color(0.6, 0.55, 0.62)

@export var circle := false:
	set(v):
		circle = v
		_shape()

var _ground: Color = S.ROLE_GROUNDS[0]

@onready var _art: TextureRect = $Art
@onready var _frame: Panel = $Frame


func _ready() -> void:
	_shape()


func show_character(c: GuildCharacter) -> void:
	_ground = S.ROLE_GROUNDS[clampi(c.role, 0, 3)]
	_shape()
	_art.texture = ExternalContentContainer.get_character_icon(c.role)
	_art.modulate = DEAD_TINT if c.injury_level >= GuildCharacter.InjuryLevel.DEAD else Color.WHITE


func _shape() -> void:
	if not is_node_ready():
		return
	var px := custom_minimum_size.x
	var radius := int(px / 2) if circle else int(px * ROUNDNESS)
	add_theme_stylebox_override("panel", S.flat(_ground, radius, 0))
	var frame := S.flat(Color(0, 0, 0, 0), radius, 3, S.INK)
	frame.draw_center = false
	_frame.add_theme_stylebox_override("panel", frame)
	_art.offset_top = px * ART_DROP
