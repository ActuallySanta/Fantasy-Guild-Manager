---
source: Scripts/UI/Tabs/tab_pack.gd
class_name: ""
extends: VBoxContainer
scene: "[[tab_pack (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# tab_pack.gd

## Purpose
The Pack sub-tab of the Items tab, shown to players as "Equipment": every item the guild owns and who wears what. It has a title, role filters (All / Knight / Priest / Pathfinder / Mage), a grid of [[pack_tile (scene)]] tiles grouped by role (a worn item carries its hero's portrait and an "ON GWEN" ribbon), and an item bar above the nav for the picked item (Take off or Equip). Equip opens [[overlay_equip_picker]]; Take off, and swapping onto a hero whose slots are full, ask first through [[overlay_gear_confirm]]. Both are child scenes drawn over the screen. The picked item, filter and open overlay are view state only; gear changes only through `hall.equip_item`, `hall.unequip_item` and `hall.swap_gear`. Scene: [[tab_pack (scene)]]. It sits inside [[tab_items]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `PackTileScene` | const (preload) | `uid://g3ntvsh05abd`, `Scenes/Rows/Items/pack_tile.tscn`, [[pack_tile (scene)]]. |
| `FILTER_ALL` | const | Filter value for "every role" (-1); otherwise a `GuildCharacter.CharacterRole`. |
| `ROLE_ORDER` | const | Knight, Priest, Pathfinder, Mage: order on the grid and the filter row. |
| `FILTER_HEIGHT` / `FILTER_FONT_SIZE` | const | Filter button height and label size (design px, 60 / 24). |
| `SHOW_HIDE_WORN_TOGGLE` | const | `false`: hides the "Hide equipped" toggle. |
| `SHOW_COUNT_LINE` | const | `false`: hides the "N items · N worn · N spare" line. |
| `SHOW_SPARE_NOTE` | const | `false`: hides "Not worn · ready to equip" in the item bar. |
| `TITLE`, `HIDE_WORN`, `COUNT_LINE`, `EMPTY_PACK`, `ALL_WORN`, `NONE_FOR_ROLE`, `FILTER_ALL_TEXT`, `NOTHING_PICKED`, `WORN_BY`, `SPARE_NOTE`, `BUTTON_TAKE_OFF`, `BUTTON_EQUIP` | const | Text strings. |
| `_scroll`, `_title`, `_hide_worn_toggle`, `_count_line`, `_filters`, `_grid`, `_empty_note`, `_wearer_portrait`, `_item_name`, `_item_effect`, `_item_status`, `_action_button`, `_picker`, `_confirm` | var | `@onready` nodes by unique name, see [[tab_pack (scene)]]. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |
| `_selected` | var | The picked `StandardItem` (null = none), kept by reference because `owned_items` can reorder. |
| `_filter` | var | `FILTER_ALL` or a `CharacterRole`. |
| `_hide_worn` | var | Hide items someone wears. |
| `_just_picked` | var | True right after a tile tap, so that tile pops on the next refresh. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Tabs/tab_pack.gd:88`

Stores the hall, sets the fixed texts and visibilities, labels and connects the scene's filter buttons, and wires the two overlays.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `main` passed down by [[tab_items#setup]] |

**Returns:** nothing.

**Side effects:** `pressed` on each filter button calls `_set_filter(value)` (button 0 = All, then one per `ROLE_ORDER`); `pressed` on `%ActionButton` runs [[tab_pack#_on_action_pressed]]; `toggled` on `%HideWornToggle` runs [[tab_pack#_on_hide_worn_toggled]]. Overlay signals: `equip_chosen` and `swap_chosen` on `%EquipPicker` ([[overlay_equip_picker]]) go to [[tab_pack#_on_equip_chosen]] and [[tab_pack#_on_swap_chosen]]; `closed` on the picker calls its own `close`; `take_off_confirmed` and `swap_confirmed` on `%GearConfirm` ([[overlay_gear_confirm]]) go to [[tab_pack#_on_take_off_confirmed]] and [[tab_pack#_on_swap_confirmed]]; its `closed` calls its own `close`. (Connected at `tab_pack.gd:92`, `:101`-`:108`; these overlay signals have no other listener in `Scripts/`.)

**Called by:** [[tab_items#setup]] (`tab_items.gd:39`). **Calls:** [[tab_pack#_role_word]], [[tab_pack#_set_filter]].

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Tabs/tab_pack.gd:111`

Sets `%Scroll`'s `scroll_vertical` to 0. **Called by:** [[tab_items#scroll_to_top]] (`tab_items.gd:56`). **Calls:** none.

### refresh
`func refresh() -> void` · `Scripts/UI/Tabs/tab_pack.gd:115`

Drops `_selected` if it is no longer owned, syncs the toggle, redraws filters, grid and item bar, and refreshes both overlays.

**Called by:** [[tab_items#refresh]] (`tab_items.gd:76`, only while the Equipment section is open).

**Calls:** [[tab_pack#_show_filters]], [[tab_pack#_show_grid]], [[tab_pack#_show_item_bar]], [[overlay_equip_picker#refresh]], [[overlay_gear_confirm#refresh]].

### _show_filters
`func _show_filters() -> void` · `Scripts/UI/Tabs/tab_pack.gd:126`

Styles each filter button: wood when it is the current filter, paper otherwise, at `FILTER_FONT_SIZE` and a height scaled by the font scale.

**Called by:** [[tab_pack#refresh]] (`tab_pack.gd:119`). **Calls:** [[hall_style#style_button]], [[hall_font_scale#px]].

### _show_grid
`func _show_grid() -> void` · `Scripts/UI/Tabs/tab_pack.gd:135`

Rebuilds the grid: one [[pack_tile (scene)]] per item from [[tab_pack#_shown_items]], and the empty-state note (`EMPTY_PACK` / `NONE_FOR_ROLE` / `ALL_WORN`).

**Side effects:** `HallStyle.clear_children(_grid)`, then `tile.setup(item, item == _selected, _pick.bind(item))` ([[pack_tile#setup]]) per item. A tile that is `hall.pending_fx.gear_in` stamps in ([[hall_fx#stamp_in]]); a just-picked tile pops ([[hall_fx#pop]]). Clears `_just_picked`.

**Called by:** [[tab_pack#refresh]] (`tab_pack.gd:120`).

**Calls:** [[item_shop#unworn_count]], [[hall_style#count_text]], [[hall_style#clear_children]], [[tab_pack#_shown_items]], [[hall_style#add_row]], [[pack_tile#setup]], [[hall_fx#stamp_in]], [[hall_fx#pop]], [[tab_pack#_has_role]], [[tab_pack#_role_word]].

### _shown_items
`func _shown_items() -> Array[StandardItem]` · `Scripts/UI/Tabs/tab_pack.gd:162`

**Returns:** owned items that pass the filters, grouped by role (`ROLE_ORDER`), in the order they were got within a role. Skips worn items when `_hide_worn` is on. Used by [[tab_pack#_show_grid]] (`tab_pack.gd:141`).

**Called by:** [[tab_pack#_show_grid]]. **Calls:** none.

### _show_item_bar
`func _show_item_bar() -> void` · `Scripts/UI/Tabs/tab_pack.gd:177`

The picked item's name, effect, who wears it and the button. With no pick: "Pick an item" and everything else hidden. A worn item shows the wearer's portrait, "Worn by <name>" and a red "Take off" (paper button). A spare item shows a gold "Equip" button (and the spare note only if `SHOW_SPARE_NOTE`).

**Called by:** [[tab_pack#refresh]] (`tab_pack.gd:121`). **Calls:** [[hall_style#item_look]], [[portrait#show_character]], [[hall_style#set_font_color]], [[hall_style#style_button]].

### _pick
`func _pick(item: StandardItem) -> void` · `Scripts/UI/Tabs/tab_pack.gd:211`

A tile was tapped: pick it. The redraw is queued instead of run here, because the handler fires inside the tapped control's own release event and `refresh()` frees that control, which would leave the `ScrollContainer` stuck "dragging" (see [[tab_shop#_pick]]).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The tapped item | bound in [[tab_pack#_show_grid]] (`tab_pack.gd:144`) |

**Side effects:** sets `_selected`, `_just_picked`; [[hall_main#queue_refresh]].

**Called by:** `pressed` on each runtime `pack_tile`, through the `on_pick` callable stored by [[pack_tile#setup]] (`pack_tile.gd:56`). **Calls:** [[hall_main#queue_refresh]].

### _set_filter
`func _set_filter(value: int) -> void` · `Scripts/UI/Tabs/tab_pack.gd:217`

Sets `_filter` and queues a refresh.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `value` | `int` | `FILTER_ALL` or a `CharacterRole` | bound per button in [[tab_pack#setup]] (`tab_pack.gd:101`) |

**Called by:** `pressed` on each filter button. **Calls:** [[hall_main#queue_refresh]].

### _on_hide_worn_toggled
`func _on_hide_worn_toggled(is_on: bool) -> void` · `Scripts/UI/Tabs/tab_pack.gd:222`

Sets `_hide_worn` and queues a refresh.

**Parameters**: `is_on` is the toggle's new state, from `toggled` on `%HideWornToggle`.

**Called by:** `toggled` on `%HideWornToggle` (`tab_pack.gd:92`; the toggle is hidden while `SHOW_HIDE_WORN_TOGGLE` is false). **Calls:** [[hall_main#queue_refresh]].

### _on_action_pressed
`func _on_action_pressed() -> void` · `Scripts/UI/Tabs/tab_pack.gd:227`

The item bar's button: for a worn item opens the Take off confirm; for a spare one opens the hero picker. Does nothing without a pick.

**Called by:** `pressed` on `%ActionButton` (`tab_pack.gd:102`). **Calls:** [[overlay_gear_confirm#open_take_off]], [[overlay_equip_picker#open]].

### _on_equip_chosen
`func _on_equip_chosen(character: GuildCharacter) -> void` · `Scripts/UI/Tabs/tab_pack.gd:236`

A hero was picked to wear the item: closes the picker and equips.

**Parameters**: `character` is the hero from `equip_chosen` (emitted at `overlay_equip_picker.gd:82`).

**Side effects:** [[hall_main#equip_item]] with `_selected`.

**Called by:** signal `equip_chosen` on `%EquipPicker`. **Calls:** [[overlay_equip_picker#close]], [[hall_main#equip_item]].

### _on_swap_chosen
`func _on_swap_chosen(character: GuildCharacter) -> void` · `Scripts/UI/Tabs/tab_pack.gd:242`

A hero whose slots are full was picked: closes the picker and opens the swap confirm.

**Parameters**: `character` from `swap_chosen` (emitted at `overlay_equip_picker.gd:84`).

**Called by:** signal `swap_chosen` on `%EquipPicker`. **Calls:** [[overlay_equip_picker#close]], [[overlay_gear_confirm#open_swap]].

### _on_take_off_confirmed
`func _on_take_off_confirmed(item: StandardItem) -> void` · `Scripts/UI/Tabs/tab_pack.gd:248`

Closes the confirm and takes the item off.

**Parameters**: `item` from `take_off_confirmed` (emitted at `overlay_gear_confirm.gd:162`).

**Called by:** signal `take_off_confirmed` on `%GearConfirm`. **Calls:** [[overlay_gear_confirm#close]], [[hall_main#unequip_item]].

### _on_swap_confirmed
`func _on_swap_confirmed(item_on: StandardItem, item_off: StandardItem, character: GuildCharacter) -> void` · `Scripts/UI/Tabs/tab_pack.gd:253`

Closes the confirm and swaps gear on the hero.

**Parameters**: `item_on`, `item_off`, `character` from `swap_confirmed` (emitted at `overlay_gear_confirm.gd:164`).

**Called by:** signal `swap_confirmed` on `%GearConfirm`. **Calls:** [[overlay_gear_confirm#close]], [[hall_main#swap_gear]].

### _role_word
`static func _role_word(role: int) -> String` · `Scripts/UI/Tabs/tab_pack.gd:258`

**Returns:** the role's enum key capitalized (e.g. "Knight"). Used for filter labels and the `NONE_FOR_ROLE` note.

**Called by:** [[tab_pack#setup]] (`tab_pack.gd:100`), [[tab_pack#_show_grid]] (`:155`). **Calls:** none.

### _has_role
`static func _has_role(items: Array[StandardItem], role: int) -> bool` · `Scripts/UI/Tabs/tab_pack.gd:262`

**Returns:** `true` when any item in `items` has that `role`. Used to pick the empty note in [[tab_pack#_show_grid]] (`tab_pack.gd:154`).

**Called by:** [[tab_pack#_show_grid]]. **Calls:** none.

## Suspected issues
- `SHOW_HIDE_WORN_TOGGLE`, `SHOW_COUNT_LINE` and `SHOW_SPARE_NOTE` are `false`, so `_hide_worn` stays false at runtime and `COUNT_LINE` / `SPARE_NOTE` are never visible; `ALL_WORN` mentions "Untick Hide equipped" but that toggle is hidden (unreachable text).
