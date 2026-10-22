## Character portrait: the character's own art clipped to an oval (or circle)
## on a soft ground, inside an ink frame. Set the size on each instance with
## custom_minimum_size; `round` = circle instead of oval, `pinned` = red pin on top.
## Art: MobileHall/Art/Textures/portrait_<oval|round>_<mask|frame>.png
## Scene: MobileHall/Scenes/Components/portrait.tscn
extends Control

const S := preload("res://MobileHall/Scripts/hall_style.gd")

const ROUND_MASK := preload("res://MobileHall/Art/Textures/portrait_round_mask.png")
const ROUND_FRAME := preload("res://MobileHall/Art/Textures/portrait_round_frame.png")
## Multiplied over the art so white backgrounds read as old paper.
const ART_TINT := Color("#F2EADB")
const DEAD_TINT := Color(0.6, 0.55, 0.62)

@export var round := false
@export var pinned := false

@onready var _mask: TextureRect = $Mask
@onready var _art: TextureRect = $Mask/Art
@onready var _frame: TextureRect = $Frame
@onready var _pin: TextureRect = $Pin


func _ready() -> void:
	if round:
		_mask.texture = ROUND_MASK
		_frame.texture = ROUND_FRAME
	_pin.visible = pinned


func show_character(c: GuildCharacter) -> void:
	S.tint(_mask, S.ROLE_GROUNDS[clampi(c.role, 0, 3)])
	_art.texture = c.icon if c.icon else ExternalContentContainer.get_character_icon(c.role)
	_art.modulate = DEAD_TINT if S.is_dead(c) else ART_TINT
