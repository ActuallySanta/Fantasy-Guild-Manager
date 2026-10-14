## Character portrait (Scenes/Components/portrait.tscn): the project's role art,
## clipped to a circle or rounded square on a soft painted ground, with an ink
## frame. Set the size with custom_minimum_size.
@tool
extends Panel

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

@export var circle := false:
	set(v):
		circle = v
		if is_node_ready():
			_shape()

var _ground := S.ROLE_GROUNDS[0]


func _ready() -> void:
	_shape()


func _radius() -> int:
	var size := custom_minimum_size.x
	return int(size / 2) if circle else int(size * 0.18)


func _shape() -> void:
	add_theme_stylebox_override("panel", S.flat(_ground, _radius(), 0))
	var fsb := S.flat(Color(0, 0, 0, 0), _radius(), 3, S.INK)
	fsb.draw_center = false
	$Frame.add_theme_stylebox_override("panel", fsb)
	$Art.offset_top = custom_minimum_size.x * 0.06


func show_character(c: GuildCharacter) -> void:
	var role: int = c.role if c else 0
	_ground = S.ROLE_GROUNDS[clampi(role, 0, 3)]
	_shape()
	$Art.texture = ExternalContentContainer.get_character_icon(role)
	$Art.modulate = Color(0.6, 0.55, 0.62) if c and c.injury_level >= GuildCharacter.InjuryLevel.DEAD else Color.WHITE
