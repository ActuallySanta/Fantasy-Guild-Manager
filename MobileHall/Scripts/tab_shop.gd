## Shop tab ("Counter" layout, picked by the team from the three Shop mockups).
##   Keeper   - the shopkeeper behind his counter, with a speech bubble and
##              the shop's name tag (top ~40% of the tab)
##   Goods    - a 3 x 2 grid of today's goods with prices; sold-out items grey out
##   Buy bar  - the picked item's name, what it does, and Buy (sits where the
##              action bar normally is; hall_main hides the action bar here)
##
## The goods come from the ItemShop autoload (generated items, new stock every
## dawn). Bought items go into the guild's pack; heroes equip them from their
## own page (screen_character.gd, Gear section).
## The keeper art (MobileHall/Art/shopkeeper_placeholder.svg) is stand-in art.
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
const RESTOCK_NOTE_PACK := "New goods at dawn · %s in your pack"
const BUY_BUTTON := "Buy · %dg"
const SOLD_BUTTON := "Sold"
const NOTHING_PICKED := "Pick something"
const NOTHING_PICKED_HINT := "Tap an item to see what it does"
const SOLD_HINT := "Bought! Equip it from a hero's page."
const TOO_POOR_HINT := " · Not enough gold"

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
## Index into ItemShop.stock of the picked item (-1 = none).
var _selected := 0


func setup(main: HallMain) -> void:
	hall = main
	_bubble_text.text = KEEPER_LINE
	_shop_name.text = SHOP_NAME
	_goods_title.text = GOODS_TITLE
	_buy_button.pressed.connect(_on_buy_pressed)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	if _selected >= ItemShop.stock.size():
		_selected = -1
	_show_goods()
	_show_restock_note()
	_show_buy_bar()


func _show_goods() -> void:
	Style.clear_children(_grid)
	for index in ItemShop.stock.size():
		var item := ItemShop.get_item(index)
		var look := Style.item_look(item)
		var good := {
			"name": look.short,
			"tag": look.tag,
			"color": look.color,
			"price": item.cost,
			"sold": ItemShop.is_sold(index),
		}
		Style.add_row(_grid, ShopTileScene).setup(good, index == _selected, _pick.bind(index))


func _show_restock_note() -> void:
	var unworn := ItemShop.unworn_count()
	if unworn > 0:
		_restock_note.text = RESTOCK_NOTE_PACK % Style.count_text(unworn, "item", "items")
	else:
		_restock_note.text = RESTOCK_NOTE


## Name, what it does, and Buy for the picked item.
func _show_buy_bar() -> void:
	var item := ItemShop.get_item(_selected)
	if item == null:
		_item_name.text = NOTHING_PICKED
		_item_effect.text = NOTHING_PICKED_HINT
		_buy_button.visible = false
		return
	var look := Style.item_look(item)
	var is_sold := ItemShop.is_sold(_selected)
	_item_name.text = look.name
	_item_effect.text = SOLD_HINT if is_sold else look.effect
	if not is_sold and not ItemShop.can_afford(item):
		_item_effect.text += TOO_POOR_HINT
	_buy_button.visible = true
	_buy_button.text = SOLD_BUTTON if is_sold else BUY_BUTTON % item.cost
	_buy_button.disabled = not ItemShop.can_buy(_selected)
	Style.style_button(_buy_button, "gold")


func _pick(index: int) -> void:
	_selected = index
	refresh()


func _on_buy_pressed() -> void:
	hall.buy_item(_selected)
