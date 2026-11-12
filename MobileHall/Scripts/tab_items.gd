## Items tab: the guild's gear, split in two folder tabs.
##   Pack - everything the guild owns and who wears what (tab_pack.gd)
##   Shop - Grizzle's counter, today's goods (tab_shop.gd)
## Which one is open is hall.items_section (HallMain.ITEMS_SECTION_*). The nav
## button and HallMain.TAB_SHOP keep the id "shop" so the tutorial's unlock day
## and old saves still line up.
## Scene: MobileHall/Scenes/Tabs/tab_items.tscn
extends VBoxContainer


## Folder tab heights (pixels): the open one stands a little taller (as on the Guild tab).
const FOLDER_TAB_HEIGHT := 72
const FOLDER_TAB_HEIGHT_OPEN := 80

## SIMPLIFIED (Info-Chunking): true = the folder tabs show counts
## ("Pack · 5", "Shop · 3 left"); false = just their names.
const SHOW_TAB_COUNTS := false

# ---- TEXT
const BUTTON_PACK := "Pack · %d"
## The Pack folder tab's name while SHOW_TAB_COUNTS is off.
const BUTTON_PACK_PLAIN := "Equipment"
const BUTTON_SHOP := "Shop · %d left"
const BUTTON_SHOP_SOLD_OUT := "Shop · sold out"
const BUTTON_SHOP_PLAIN := "Shop"

# ---- NODES
@onready var _pack_button: Button = %SegPack
@onready var _shop_button: Button = %SegShop
@onready var _pack: Control = %TabPack
@onready var _shop: Control = %TabShop

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_pack.setup(main)
	_shop.setup(main)
	_pack_button.pressed.connect(func(): hall.show_items_section(HallMain.ITEMS_SECTION_PACK))
	_shop_button.pressed.connect(func(): hall.show_items_section(HallMain.ITEMS_SECTION_SHOP))


## The Shop sub-tab (the tutorial points at its nodes).
func shop_view() -> Control:
	return _shop


## The Pack sub-tab.
func pack_view() -> Control:
	return _pack


func scroll_to_top() -> void:
	_pack.scroll_to_top()
	_shop.scroll_to_top()


func refresh() -> void:
	var is_pack := hall.items_section == HallMain.ITEMS_SECTION_PACK
	_pack.visible = is_pack
	_shop.visible = not is_pack
	_pack_button.theme_type_variation = &"FolderTabActive" if is_pack else &"FolderTab"
	_shop_button.theme_type_variation = &"FolderTab" if is_pack else &"FolderTabActive"
	_pack_button.custom_minimum_size.y = FOLDER_TAB_HEIGHT_OPEN if is_pack else FOLDER_TAB_HEIGHT
	_shop_button.custom_minimum_size.y = FOLDER_TAB_HEIGHT if is_pack else FOLDER_TAB_HEIGHT_OPEN
	if SHOW_TAB_COUNTS:
		_pack_button.text = BUTTON_PACK % ItemContainer.owned_items.size()
		var left := _unsold_count()
		_shop_button.text = BUTTON_SHOP % left if left > 0 else BUTTON_SHOP_SOLD_OUT
	else:
		_pack_button.text = BUTTON_PACK_PLAIN
		_shop_button.text = BUTTON_SHOP_PLAIN
	if is_pack:
		_pack.refresh()
	else:
		_shop.refresh()


## How many of today's goods are still on the counter.
func _unsold_count() -> int:
	var count := 0
	for index in ItemShop.stock.size():
		if not ItemShop.is_sold(index):
			count += 1
	return count
