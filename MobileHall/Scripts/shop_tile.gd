## One item on the Shop tab's goods grid, drawn as a parchment price tag:
## a coloured seal with the item's short tag, its name and price.
## A sold item (bought today) is faded, stamped "Sold" and can't be picked.
## The picked one gets the gold-edged tag (GoodsTagSelected in hall_theme).
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


## good: one entry of tab_shop.gd's PLACEHOLDER_GOODS.
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
		pressed.connect(on_pick)
	theme_type_variation = &"GoodsTagSelected" if is_selected and not is_sold else &"GoodsTag"
