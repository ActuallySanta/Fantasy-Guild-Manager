## One item on the Shop tab's goods grid, drawn as a parchment price tag:
## a rarity-coloured seal with the item's icon (or its rarity tag when the
## item has no icon), its name and price.
## A sold item (bought today) is faded, stamped "Sold" and can't be picked.
## The picked one gets the gold-edged tag (GoodsTagSelected in hall_theme).
## Scene: Scenes/Rows/Items/shop_tile.tscn
extends Button


## Sold-out tags fade back.
const SOLD_OPACITY := 0.7
## The tag's size (design px; width 0 = share the grid row). Grown with the
## font scale: the seal, name and price sit in an anchored column inside it,
## so the tag has to get taller for them to keep fitting.
const TILE_SIZE := Vector2(0, 222)

# ---- TEXT
const PRICE := "%dg"
const SOLD_TAG := "SOLD"
const SOLD_NOTE := "Back tomorrow"

# ---- NODES
@onready var _tag: PanelContainer = %Tag
@onready var _tag_text: Label = %TagText
@onready var _tag_icon: TextureRect = %TagIcon
@onready var _name: Label = %ItemName
@onready var _price: Control = %Price
@onready var _price_text: Label = %PriceText
@onready var _sold_note: Label = %SoldNote
@onready var _sold_stamp: Control = %SoldStamp


## good: {name, tag, color, icon, price, sold} built by tab_shop.gd from
## HallStyle.item_look (icon = an ICON_FILES name, "" for none).
func setup(good: Dictionary, is_selected: bool, on_pick: Callable) -> void:
	var is_sold: bool = good.get("sold", false)
	custom_minimum_size = HallFontScale.px_vec(TILE_SIZE)
	_name.text = good.name
	_price_text.text = PRICE % good.price
	_sold_note.text = SOLD_NOTE
	_price.visible = not is_sold
	_sold_note.visible = is_sold
	_sold_stamp.visible = is_sold
	disabled = is_sold
	if is_sold:
		# no icon: the seal just says SOLD
		HallStyle.style_icon_tag(_tag, _tag_text, _tag_icon, SOLD_TAG, "", HallStyle.LINE)
		HallStyle.set_font_color(_name, HallStyle.TEXT_SOFT)
		modulate = Color(1, 1, 1, SOLD_OPACITY)
	else:
		HallStyle.style_icon_tag(_tag, _tag_text, _tag_icon, good.tag, good.get("icon", ""), good.color)
		pressed.connect(on_pick)
	theme_type_variation = &"GoodsTagSelected" if is_selected and not is_sold else &"GoodsTag"
