## Shop tab ("Counter" layout, picked by the team from the three Shop mockups).
##   Keeper   - the shopkeeper behind his counter, with a speech bubble and
##              the shop's name tag (top ~40% of the tab)
##   Goods    - a 3 x 2 grid of today's goods with prices; sold-out items grey out
##   Buy bar  - the picked item's name, what it does, and Buy (sits where the
##              action bar normally is; hall_main hides the action bar here)
##
## GROUNDWORK ONLY: nothing can be bought yet. The goods, prices and effects
## below are placeholders, and Buy only shows a toast. The keeper art
## (MobileHall/Art/shopkeeper_placeholder.svg) is stand-in art too.
## Which item is picked is view state only, kept here.
## Scene: MobileHall/Scenes/Tabs/tab_shop.tscn
extends VBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const ShopTileScene := preload("res://MobileHall/Scenes/Rows/shop_tile.tscn")

# ---- TEXT
const SHOP_NAME := "Grizzle's Goods"
const KEEPER_LINE := "Fresh stock every dawn. Touch it, you bought it."
const GOODS_TITLE := "TODAY'S GOODS"
const RESTOCK_NOTE := "New goods at dawn"
const BUY_BUTTON := "Buy · %dg"
const NOTHING_PICKED := "Pick something"
const NOTHING_PICKED_HINT := "Tap an item to see what it does"
const TOAST_NOT_OPEN := "The shop isn't open yet. Coming soon!"

# ---- PLACEHOLDER GOODS (made up to fill the layout; replace with real items)
const PLACEHOLDER_GOODS := [
	{"name": "Healing Tonic", "short": "Tonic", "tag": "TON", "color": Color("#C9574F"), "price": 80,
		"effect": "Heals one hero by one injury level, right now"},
	{"name": "Ward Charm", "short": "Ward Charm", "tag": "WRD", "color": Color("#5D7FA6"), "price": 120,
		"effect": "One hero shrugs off the next injury"},
	{"name": "Whetstone", "short": "Whetstone", "tag": "WHT", "color": Color("#7D7D7D"), "price": 60,
		"effect": "+1 Power for one hero's next quest"},
	{"name": "Scout's Map", "short": "Scout's Map", "tag": "MAP", "color": Color("#B8862B"), "price": 150,
		"effect": "Shows one extra quest on tomorrow's board"},
	{"name": "Lucky Coin", "short": "Lucky Coin", "tag": "LCK", "color": Color("#3F7A2E"), "price": 200,
		"effect": "+10% odds on one quest, used when the party is sent"},
	{"name": "Drake Bane", "short": "Drake Bane", "tag": "BNE", "color": Color("#8E5A9C"), "price": 300,
		"effect": "Sold out", "sold": true},
]

# ---- NODES
@onready var _bubble_text: Label = %BubbleText
@onready var _shop_name: Label = %ShopName
@onready var _scroll: ScrollContainer = %Scroll
@onready var _goods_title: Label = %GoodsTitle
@onready var _restock_note: Label = %RestockNote
@onready var _grid: GridContainer = %Grid
@onready var _item_name: Label = %ItemName
@onready var _item_effect: Label = %ItemEffect
@onready var _buy_button: Button = %BuyButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## Index into PLACEHOLDER_GOODS of the picked item (-1 = none).
var _selected := 0


func setup(main: HallMain) -> void:
	hall = main
	_bubble_text.text = KEEPER_LINE
	_shop_name.text = SHOP_NAME
	_goods_title.text = GOODS_TITLE
	_restock_note.text = RESTOCK_NOTE
	_buy_button.pressed.connect(_on_buy_pressed)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	_show_goods()
	_show_buy_bar()


func _show_goods() -> void:
	Style.clear_children(_grid)
	for index in PLACEHOLDER_GOODS.size():
		var good: Dictionary = PLACEHOLDER_GOODS[index]
		var tile_good := good.duplicate()
		tile_good.name = good.short
		Style.add_row(_grid, ShopTileScene).setup(tile_good, index == _selected, _pick.bind(index))


## Name, what it does, and Buy for the picked item.
func _show_buy_bar() -> void:
	if _selected < 0:
		_item_name.text = NOTHING_PICKED
		_item_effect.text = NOTHING_PICKED_HINT
		_buy_button.visible = false
		return
	var good: Dictionary = PLACEHOLDER_GOODS[_selected]
	_item_name.text = good.name
	_item_effect.text = good.effect
	_buy_button.visible = true
	_buy_button.text = BUY_BUTTON % good.price
	Style.style_button(_buy_button, "gold")


func _pick(index: int) -> void:
	_selected = index
	refresh()


## Groundwork only: no buying yet.
func _on_buy_pressed() -> void:
	hall.show_toast(TOAST_NOT_OPEN)
