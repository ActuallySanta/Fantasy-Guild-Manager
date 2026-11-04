## One item on the Shop tab's goods grid, drawn as a parchment price tag:
## a coloured seal with the item's short tag, its name and price.
## A sold item (bought today) is faded, stamped "Sold" and can't be picked.
## The picked one gets the gold-edged tag (GoodsTagSelected in hall_theme).
## The tile is a Button set to mouse_filter PASS (in the scene) so a drag that
## starts on it still scrolls the goods grid; a press that moved like a scroll
## is ignored instead of picking the item (same rule as TapPanel).
## Scene: MobileHall/Scenes/Rows/shop_tile.tscn
extends Button


## Sold-out tags fade back.
const SOLD_OPACITY := 0.7

# ---- TEXT
const PRICE := "%dg"
const SOLD_TAG := "SOLD"
const SOLD_NOTE := "Back tomorrow"

# ---- NODES
@onready var _tag: PanelContainer = %Tag
@onready var _tag_text: Label = %TagText
@onready var _name: Label = %ItemName
@onready var _price: Control = %Price
@onready var _price_text: Label = %PriceText
@onready var _sold_note: Label = %SoldNote
@onready var _sold_stamp: Control = %SoldStamp

## Where the current press started (global coordinates).
var _press_position := Vector2.ZERO
## True when the last press moved further than TapPanel.TAP_MOVE_LIMIT,
## i.e. the player was scrolling, so the release shouldn't pick the item.
var _was_drag := false
## Called with no arguments when the tile is tapped (set in setup()).
var _on_pick := Callable()


## good: one entry of tab_shop.gd's PLACEHOLDER_GOODS.
## is_selected: draw the gold-edged "picked" tag.
## on_pick: called on a real tap (not on a scroll that ends over the tile).
func setup(good: Dictionary, is_selected: bool, on_pick: Callable) -> void:
	var is_sold: bool = good.get("sold", false)
	_name.text = good.name
	_price_text.text = PRICE % good.price
	_sold_note.text = SOLD_NOTE
	_price.visible = not is_sold
	_sold_note.visible = is_sold
	_sold_stamp.visible = is_sold
	disabled = is_sold
	if is_sold:
		HallStyle.style_tag(_tag, _tag_text, SOLD_TAG, HallStyle.LINE)
		HallStyle.set_font_color(_name, HallStyle.TEXT_SOFT)
		modulate = Color(1, 1, 1, SOLD_OPACITY)
	else:
		HallStyle.style_tag(_tag, _tag_text, good.tag, good.color)
		_on_pick = on_pick
		pressed.connect(_on_pressed)
	theme_type_variation = &"GoodsTagSelected" if is_selected and not is_sold else &"GoodsTag"


# Runs before the Button's own handling emits `pressed` on release, so
# _was_drag is already up to date when _on_pressed checks it.
func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		_press_position = mouse_event.global_position
		_was_drag = false
	else:
		var moved_distance := mouse_event.global_position.distance_to(_press_position)
		_was_drag = moved_distance >= TapPanel.TAP_MOVE_LIMIT


func _on_pressed() -> void:
	if not _was_drag:
		_on_pick.call()
