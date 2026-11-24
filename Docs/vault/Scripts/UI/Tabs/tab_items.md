---
source: Scripts/UI/Tabs/tab_items.gd
class_name: ""
extends: VBoxContainer
scene: "[[tab_items (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# tab_items.gd

## Purpose
The Items tab, split in two folder tabs: Equipment (internally "pack", [[tab_pack]]: everything the guild owns and who wears what) and Shop ([[tab_shop]]: today's goods). Which one is open is `hall.items_section` (`HallMain.ITEMS_SECTION_*`). The nav button and `HallMain.TAB_SHOP` keep the id `shop` so the tutorial's unlock day and old saves line up. Scene: [[tab_items (scene)]]. [[hall_main]] reaches it as `_tabs.shop`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `FOLDER_TAB_HEIGHT` / `FOLDER_TAB_HEIGHT_OPEN` | const | Folder tab heights in px (72 / 80); the open one is taller. |
| `SHOW_TAB_COUNTS` | const | `false`: folder tabs show just their names; `true`: counts ("Pack · 5", "Shop · 3 left"). |
| `BUTTON_PACK`, `BUTTON_PACK_PLAIN`, `BUTTON_SHOP`, `BUTTON_SHOP_SOLD_OUT`, `BUTTON_SHOP_PLAIN` | const | Button texts. |
| `_pack_button`, `_shop_button` | var | `%SegPack`, `%SegShop`. |
| `_pack`, `_shop` | var | `%TabPack` ([[tab_pack]]) and `%TabShop` ([[tab_shop]]). |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Tabs/tab_items.gd:37`

Stores the hall, sets up both sub-tabs, and connects the folder buttons.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Returns:** nothing.

**Side effects:** [[tab_pack#setup]] and [[tab_shop#setup]]; `pressed` on `%SegPack` / `%SegShop` calls [[hall_main#show_items_section]] with `ITEMS_SECTION_PACK` / `ITEMS_SECTION_SHOP`.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[tab_pack#setup]], [[tab_shop#setup]], [[hall_main#show_items_section]].

### shop_view
`func shop_view() -> Control` · `Scripts/UI/Tabs/tab_items.gd:46`

The Shop sub-tab (the tutorial points at its nodes).

**Returns:** `%TabShop`. Used by the tutorial's target lambdas for the shop's `Grid` and `BuyButton` ([[overlay_tutorial]], `overlay_tutorial.gd:1133`, `:1136`).

**Called by:** [[overlay_tutorial]] (`overlay_tutorial.gd:1133`, `:1136`, on `_tab("shop")`). **Calls:** none.

### pack_view
`func pack_view() -> Control` · `Scripts/UI/Tabs/tab_items.gd:51`

The Pack sub-tab. **Returns:** `%TabPack`.

**Called by:** none found (no `pack_view` call in `Globals/`, `Scripts/` or `Scenes/`). **Calls:** none.

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Tabs/tab_items.gd:55`

Scrolls both sub-tabs back to the top.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1851`, when the view key changes). **Calls:** [[tab_pack#scroll_to_top]], [[tab_shop#scroll_to_top]].

### refresh
`func refresh() -> void` · `Scripts/UI/Tabs/tab_items.gd:60`

Shows the open section, styles the folder tabs (`FolderTabActive` / `FolderTab`, taller when open), sets the button texts, and refreshes only the open sub-tab.

**Side effects:** with `SHOW_TAB_COUNTS` the Pack button shows `ItemContainer.owned_items.size()` and the Shop button the unsold count.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1843`).

**Calls:** [[tab_items#_unsold_count]], [[tab_pack#refresh]], [[tab_shop#refresh]].

### _unsold_count
`func _unsold_count() -> int` · `Scripts/UI/Tabs/tab_items.gd:82`

**Returns:** how many of today's goods are still on the counter (`ItemShop.stock` entries where `ItemShop.is_sold(index)` is false). Used by [[tab_items#refresh]] (`tab_items.gd:70`), only when `SHOW_TAB_COUNTS` is on.

**Called by:** [[tab_items#refresh]]. **Calls:** [[item_shop#is_sold]].

## Suspected issues
- `pack_view` has no callers (dead code). `tab_items.gd:51`.
- `SHOW_TAB_COUNTS` is `false`, so `BUTTON_PACK`, `BUTTON_SHOP`, `BUTTON_SHOP_SOLD_OUT` and `_unsold_count` are never reached at runtime.
