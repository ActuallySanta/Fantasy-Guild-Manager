---
source: Scripts/UI/Rows/Items/shop_tile.gd
class_name: ""
extends: Button
scene: "[[shop_tile (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# shop_tile.gd

## Purpose
One item on the Shop tab's goods grid ([[tab_shop]]), drawn as a parchment price tag: a rarity-coloured seal with the item's icon (or its rarity tag when it has no icon), its name and price. A sold item (bought today) is faded, stamped "Sold" and can't be picked. The picked one gets the gold-edged tag (`GoodsTagSelected`). Scene: [[shop_tile (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `SOLD_OPACITY` | const | Sold-out tags fade back (0.7). |
| `TILE_SIZE` | const | The tag's size in design px (width 0 = share the grid row), grown with the font scale so the anchored column of seal, name and price keeps fitting. |
| `PRICE`, `SOLD_TAG`, `SOLD_NOTE` | const | UI strings ("%dg", "SOLD", "Back tomorrow"). |
| `_tag`, `_tag_text`, `_tag_icon`, `_name`, `_price`, `_price_text`, `_sold_note`, `_sold_stamp` | onready | `%Tag`, `%TagText`, `%TagIcon`, `%ItemName`, `%Price`, `%PriceText`, `%SoldNote`, `%SoldStamp`. |

## Functions

### setup
`func setup(good: Dictionary, is_selected: bool, on_pick: Callable) -> void` · `Scripts/UI/Rows/Items/shop_tile.gd:35`

Fills the tag. A sold good hides the price, shows the note and stamp, disables the button, greys the name and fades; an unsold one shows its icon tag and connects `on_pick`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `good` | `Dictionary` | `{name, tag, color, icon, price, sold}`; `icon` is an `ICON_FILES` name or `""` | built from `HallStyle.item_look(item)`, `item.cost` and `ItemShop.is_sold(index)` in [[tab_shop#_show_goods]] |
| `is_selected` | `bool` | The picked tile (gold edge; never for a sold one) | `index == _selected` in [[tab_shop#_show_goods]] |
| `on_pick` | `Callable` | Called when tapped | `_pick.bind(index)` in [[tab_shop#_show_goods]] |

**Returns:** nothing.

**Side effects:** sets `custom_minimum_size`, `disabled`, `modulate`, theme variation; connects `pressed` (unsold only).

**Called by:** [[tab_shop#_show_goods]] (`tab_shop.gd:92`).

**Calls:** [[hall_font_scale#px_vec]], [[hall_style#style_icon_tag]], [[hall_style#set_font_color]].

## Suspected issues
- None found.
