---
source: Scripts/UI/Rows/Items/pack_tile.gd
class_name: ""
extends: Button
scene: "[[pack_tile (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# pack_tile.gd

## Purpose
One item on the Pack grid ([[tab_pack]]), drawn as a goods tag like the Shop's: rarity-coloured seal with the item's icon, name and what it adds. A worn item shows who wears it twice: the hero's round portrait pinned to the tag's corner and a navy "ON GWEN" ribbon along its foot. A spare item says "SPARE" there. The picked one gets the gold-edged tag (`GoodsTagSelected` in `hall_theme`). Scene: [[pack_tile (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TILE_SIZE` | const | The tag's size in design px (width 0 = share the grid row), grown with the font scale like [[shop_tile]]. |
| `BONUS`, `WORN_RIBBON`, `SPARE_NOTE` | const | UI strings. |
| `_tag`, `_tag_text`, `_tag_icon`, `_name`, `_bonus`, `_ribbon`, `_ribbon_text`, `_spare_note`, `_medallion` | onready | `%Tag`, `%TagText`, `%TagIcon`, `%ItemName`, `%Bonus`, `%Ribbon`, `%RibbonText`, `%SpareNote`, `%Medallion` ([[portrait]]). |

## Functions

### setup
`func setup(item: StandardItem, is_selected: bool, on_pick: Callable) -> void` · `Scripts/UI/Rows/Items/pack_tile.gd:34`

Fills the tag from `HallStyle.item_look(item)`, the stat bonus (`HallGear.item_bonus`, hidden when `bonus.x < 0`), and the wearer (`item.curr_user`: ribbon, portrait medallion and tooltip when worn; "Spare" otherwise). Picks the `GoodsTagSelected` or `GoodsTag` theme variation.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | An owned item | loop over `_shown_items()` in [[tab_pack#_show_grid]] |
| `is_selected` | `bool` | The picked tile (gold edge) | `item == _selected` in [[tab_pack#_show_grid]] |
| `on_pick` | `Callable` | Called when tapped | `_pick.bind(item)` in [[tab_pack#_show_grid]] |

**Returns:** nothing.

**Side effects:** sets `custom_minimum_size` (font-scaled), connects `pressed` to `on_pick`.

**Called by:** [[tab_pack#_show_grid]] (`tab_pack.gd:144`).

**Calls:** [[hall_font_scale#px_vec]], [[hall_style#item_look]], [[hall_style#style_icon_tag]], [[hall_gear#item_bonus]], [[hall_style#set_font_color]], [[portrait#show_character]].

## Suspected issues
- None found.
