## One item on the Shop tab's goods grid: short coloured tag, name, price.
## A sold-out item is greyed and can't be picked. The selected one is blue.
## Scene: MobileHall/Scenes/Rows/shop_tile.tscn
extends Button

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const PRICE := "%dg"
const SOLD_TAG := "SOLD"
const SOLD_NOTE := "Back tomorrow"

# ---- LOOK
const SELECTED_BG := Color("#EAF2FA")
const SOLD_BG := Color("#EEEEEE")
const SOLD_BORDER := Color("#DDDDDD")
const SOLD_TAG_BG := Color("#BBBBBB")

# ---- NODES
@onready var _tag: PanelContainer = %Tag
@onready var _tag_text: Label = %TagText
@onready var _name: Label = %ItemName
@onready var _price: PanelContainer = %Price
@onready var _price_text: Label = %PriceText
@onready var _sold_note: Label = %SoldNote


## good: one entry of tab_shop.gd's PLACEHOLDER_GOODS.
func setup(good: Dictionary, is_selected: bool, on_pick: Callable) -> void:
	var is_sold: bool = good.get("sold", false)
	_name.text = good.name
	_price_text.text = PRICE % good.price
	_sold_note.text = SOLD_NOTE
	_price.visible = not is_sold
	_sold_note.visible = is_sold
	disabled = is_sold
	if is_sold:
		Style.style_tag(_tag, _tag_text, SOLD_TAG, SOLD_TAG_BG)
		Style.set_font_color(_name, Style.TEXT_SOFT)
	else:
		Style.style_tag(_tag, _tag_text, good.tag, good.color)
		pressed.connect(on_pick)
	_show_box(is_sold, is_selected)


func _show_box(is_sold: bool, is_selected: bool) -> void:
	var box: StyleBoxFlat
	if is_sold:
		box = Style.flat_box(SOLD_BG, 14, 2, SOLD_BORDER, Vector4(8, 10, 8, 10))
	elif is_selected:
		box = Style.flat_box(SELECTED_BG, 14, 4, Style.BLUE_TEXT, Vector4(8, 10, 8, 10))
	else:
		box = Style.flat_box(Style.CARD_BG, 14, 3, Style.BORDER, Vector4(8, 10, 8, 10))
	for state in Style.BUTTON_BOX_STATES + ["disabled"]:
		add_theme_stylebox_override(state, box)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
