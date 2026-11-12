## Header popup: a parchment card that drops from a header counter (the gold
## coin or the standing shield), with a little point aiming at it. Tapping
## anywhere outside the card closes it. It only reads the game; it never
## changes it. popup_gold.gd and popup_standing.gd extend this and fill the
## card in refresh().
##
## The scene needs, as unique names: Catch (a full-screen Control that eats
## taps outside the card), Pointer (a Panel drawn before the card, so the card
## covers its lower half), Layout (a full-screen MarginContainer; its top margin
## puts the card under the counter, and it sizes the card to its wrapped text)
## and Card (a PanelContainer in Layout). The root is top_level so the header's
## VBox doesn't lay it out, and z_index 10 like the overlays.
class_name HeaderPopup
extends Control


# ============================================================ SETTINGS

## Gap between the card and the screen's left / right edges (design px).
const SIDE_MARGIN := 28.0
## Gap between the bottom of the counter and the top of the card (design px).
const DROP_GAP := 22.0
## Side of the square turned 45° into the point above the card (design px).
const POINTER_SIZE := 30.0
## Seconds the card takes to fade and drop in (none with reduced motion).
const OPEN_SECONDS := 0.15
## How far above its resting place the card starts its drop (design px).
const DROP_DISTANCE := 16.0


# ============================================================ STATE

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The header counter the card drops from (null while closed).
var _anchor: Control


# ============================================================ NODES

@onready var _catch: Control = %Catch
@onready var _layout: MarginContainer = %Layout
@onready var _card: PanelContainer = %Card
@onready var _pointer: Panel = %Pointer


func _ready() -> void:
	visible = false
	_catch.gui_input.connect(_on_catch_input)
	# the point is a small square of the card's own parchment, turned 45°
	var card_box := _card.get_theme_stylebox("panel")
	if card_box is StyleBoxTexture:
		var point_box: StyleBoxTexture = card_box.duplicate()
		point_box.set_texture_margin_all(6)
		point_box.set_content_margin_all(0)
		_pointer.add_theme_stylebox_override("panel", point_box)
	_pointer.size = Vector2(POINTER_SIZE, POINTER_SIZE)
	_pointer.pivot_offset = _pointer.size * 0.5
	_pointer.rotation_degrees = 45.0
	for side in ["margin_left", "margin_right", "margin_bottom"]:
		_layout.add_theme_constant_override(side, int(SIDE_MARGIN))


func setup(main: HallMain) -> void:
	hall = main


## Drop the card from `anchor` (a header counter) and fill it in.
func open(anchor: Control) -> void:
	_anchor = anchor
	visible = true
	refresh()
	_place()
	if not HallFx.reduce_motion:
		HallFx.fade_in(self, 0.0, OPEN_SECONDS)
		HallFx.slide_in(_card, Vector2(0, -DROP_DISTANCE), 0.0, OPEN_SECONDS)


func close() -> void:
	_anchor = null
	visible = false


func is_open() -> bool:
	return visible


## Fill the card in from the game. Overridden by each popup.
func refresh() -> void:
	pass


## Put the card under the anchor (Layout's top margin; Layout sizes it to the
## screen's width and its text), with the point under the anchor's middle.
func _place() -> void:
	if _anchor == null:
		return
	var anchor_rect := _anchor.get_global_rect()
	var card_top := anchor_rect.end.y + DROP_GAP
	_layout.add_theme_constant_override("margin_top", int(card_top))
	_pointer.position = Vector2(anchor_rect.get_center().x, card_top) - _pointer.size * 0.5


## A tap anywhere outside the card closes it.
func _on_catch_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
