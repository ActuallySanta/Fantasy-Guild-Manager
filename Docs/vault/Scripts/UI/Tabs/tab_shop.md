---
source: Scripts/UI/Tabs/tab_shop.gd
class_name: ""
extends: VBoxContainer
scene: "[[tab_shop (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# tab_shop.gd

## Purpose
The Shop sub-tab of the Items tab (the "Counter" layout). The keeper (Grizzle) sits behind his counter at the top of the scroll with a speech bubble and name tag; below, a 3x2 grid of today's goods with prices (sold-out items grey out); above the nav, a buy bar for the picked item. Goods come from the `ItemShop` autoload (new stock every dawn). Bought items go to the pack; heroes put them on from [[tab_pack]] or [[screen_character]]. Which item is picked is view state only. Scene: [[tab_shop (scene)]]. It sits inside [[tab_items]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `ShopTileScene` | const (preload) | `uid://b25qy8uoil5du`, `Scenes/Rows/Items/shop_tile.tscn`, [[shop_tile (scene)]]. |
| `SHOW_PACK_NOTE` | const | `false`: hides the "N items in your pack" note beside Today's Goods. |
| `SHOP_NAME`, `KEEPER_LINE`, `GOODS_TITLE`, `PACK_NOTE`, `BUY_BUTTON`, `SOLD_BUTTON`, `NOTHING_PICKED`, `SOLD_HINT`, `TOO_POOR_HINT` | const | Text strings. |
| `_bubble_text`, `_shop_name`, `_scroll`, `_goods_title`, `_restock_note`, `_grid`, `_item_name`, `_item_effect`, `_buy_button` | var | `@onready` nodes by unique name, see [[tab_shop (scene)]]. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |
| `_selected` | var | Index into `ItemShop.stock` of the picked item (-1 = none; starts at 0). |
| `_just_picked` | var | True right after a tile tap, so that tile pops on the next refresh. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Tabs/tab_shop.gd:58`

Stores the hall, sets the keeper's fixed texts and connects the buy button.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `main` passed down by [[tab_items#setup]] |

**Side effects:** `pressed` on `%BuyButton` runs [[tab_shop#_on_buy_pressed]].

**Called by:** [[tab_items#setup]] (`tab_items.gd:40`). **Calls:** none.

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Tabs/tab_shop.gd:66`

Sets `%Scroll`'s `scroll_vertical` to 0. **Called by:** [[tab_items#scroll_to_top]] (`tab_items.gd:57`). **Calls:** none.

### refresh
`func refresh() -> void` · `Scripts/UI/Tabs/tab_shop.gd:70`

Resets `_selected` to -1 when it is past the stock, then redraws goods, restock note and buy bar.

**Called by:** [[tab_items#refresh]] (`tab_items.gd:78`, only while the Shop section is open).

**Calls:** [[tab_shop#_show_goods]], [[tab_shop#_show_restock_note]], [[tab_shop#_show_buy_bar]].

### _show_goods
`func _show_goods() -> void` · `Scripts/UI/Tabs/tab_shop.gd:78`

Rebuilds the grid: for each `ItemShop.stock` entry builds a dictionary (`name`, `tag`, `color`, `icon`, `price`, `sold`) from [[hall_style#item_look]] and adds a [[shop_tile (scene)]] with `setup(good, index == _selected, _pick.bind(index))` ([[shop_tile#setup]]). A tile equal to `hall.pending_fx.bought` stamps in and the keeper's bubble pops; a just-picked tile pops.

**Called by:** [[tab_shop#refresh]] (`tab_shop.gd:72`).

**Calls:** [[hall_style#clear_children]], [[item_shop#get_item]], [[hall_style#item_look]], [[item_shop#is_sold]], [[hall_style#add_row]], [[shop_tile#setup]], [[hall_fx#stamp_in]], [[hall_fx#pop]].

### _show_restock_note
`func _show_restock_note() -> void` · `Scripts/UI/Tabs/tab_shop.gd:102`

Shows "N items in your pack" only when `SHOW_PACK_NOTE` is on and `ItemShop.unworn_count()` is above 0.

**Called by:** [[tab_shop#refresh]] (`tab_shop.gd:73`). **Calls:** [[item_shop#unworn_count]], [[hall_style#count_text]].

### _show_buy_bar
`func _show_buy_bar() -> void` · `Scripts/UI/Tabs/tab_shop.gd:109`

Name, effect and Buy for the picked item. With no item: "Pick something", effect and button hidden. Sold: "Sold" with the `SOLD_HINT`. Unaffordable: " · Not enough gold" appended. The button is disabled when `ItemShop.can_buy(_selected)` is false.

**Called by:** [[tab_shop#refresh]] (`tab_shop.gd:74`). **Calls:** [[item_shop#get_item]], [[hall_style#item_look]], [[item_shop#is_sold]], [[item_shop#can_afford]], [[item_shop#can_buy]], [[hall_style#style_button]].

### _pick
`func _pick(index: int) -> void` · `Scripts/UI/Tabs/tab_shop.gd:133`

A tile was tapped: pick it. The redraw is queued, not run here, because this runs inside the tapped tile's release event and `refresh()` frees that tile, which left the `ScrollContainer` stuck "dragging".

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `index` | `int` | Index into `ItemShop.stock` | bound in [[tab_shop#_show_goods]] (`tab_shop.gd:92`) |

**Side effects:** sets `_selected`, `_just_picked`; [[hall_main#queue_refresh]].

**Called by:** `pressed` on a runtime `shop_tile`, through the `on_pick` callable stored by [[shop_tile#setup]] (`shop_tile.gd:52`). **Calls:** [[hall_main#queue_refresh]].

### _on_buy_pressed
`func _on_buy_pressed() -> void` · `Scripts/UI/Tabs/tab_shop.gd:139`

Buys the picked item.

**Called by:** `pressed` on `%BuyButton` (`tab_shop.gd:63`). **Calls:** [[hall_main#buy_item]].

## Suspected issues
- `_selected` starts at 0 but its comment says -1 = none (fine at runtime: `refresh` clamps). `SHOW_PACK_NOTE` is `false`, so `_show_restock_note` hides the note always.
