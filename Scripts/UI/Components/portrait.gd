## Character portrait: the character's own art clipped to an oval (or a
## circle) on a soft ground, inside an ink frame. The clipping is the
## portrait_mask shader (HallStyle.mask_to). Set the size on each
## instance with custom_minimum_size.
## Art: MobileHall/Art/Textures/portrait_<oval|round>_<mask|frame>.png
## Scene: MobileHall/Scenes/Components/portrait.tscn
extends Control


const ROUND_MASK := preload("uid://buv1wa6etd3u3")  # MobileHall/Art/Textures/portrait_round_mask.png
const ROUND_FRAME := preload("uid://cscfv0x0mk446")  # MobileHall/Art/Textures/portrait_round_frame.png
## Multiplied over the art so white backgrounds read as old paper.
const ART_TINT := Color("#F2EADB")
## Greys out the art of dead adventurers.
const DEAD_TINT := Color(0.6, 0.55, 0.62)

## Round portrait (true) or oval (false). Set per instance in the scenes.
@export var circle := false
## A red pin on top (pinned cards, applicant letters).
@export var pinned := false

# ---- NODES
@onready var _mask: TextureRect = $Mask
@onready var _art: TextureRect = $Mask/Art
@onready var _frame: TextureRect = $Frame
@onready var _pin: TextureRect = $Pin


func _ready() -> void:
	if circle:
		_mask.texture = ROUND_MASK
		_frame.texture = ROUND_FRAME
	_pin.visible = pinned
	# the art is much bigger than the mask (see the scene's anchors) and is
	# clipped by a shader, not clip_children (broken on iPhone Safari)
	_art.resized.connect(_update_mask)
	_update_mask()


## Point the art's mask shader at the mask's rect, in the art's own pixels.
func _update_mask() -> void:
	HallStyle.mask_to(_art, _mask.texture, Rect2(-_art.position, _mask.size))


func show_character(character: GuildCharacter) -> void:
	# ground colour by role, behind the art
	var role_index := clampi(character.role, 0, HallStyle.ROLE_PORTRAIT_BGS.size() - 1)
	HallStyle.tint_art(_mask, HallStyle.ROLE_PORTRAIT_BGS[role_index])
	# the character's own art (picked once when they were made)
	_art.texture = character.icon if character.icon else ExternalContentContainer.get_character_icon(character.role)
	_art.modulate = DEAD_TINT if HallStyle.is_dead(character) else ART_TINT
