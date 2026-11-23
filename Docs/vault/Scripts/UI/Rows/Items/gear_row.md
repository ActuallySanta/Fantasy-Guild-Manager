---
source: Scripts/UI/Rows/Items/gear_row.gd
class_name: ""
extends: PanelContainer
scene: "[[gear_row (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# gear_row.gd

## Purpose
One line in a hero's Gear section ([[screen_character]]): an equipped item with Take off; an empty slot with Equip (opens the pick list) or Cancel; or an owned item in the pick list with Equip / Take (if someone else has it). Also used for each worn item in the swap sheet ([[overlay_gear_confirm]]). A rarity-coloured seal with the item's icon on the left, name and what it does, one button on the right. Scene: [[gear_row (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `EMPTY_TAG` | const | The "+" shown in the seal of an empty slot. |
| `PICK_BG` | const | Paper colour of a row in the pick list (`#EAF2FA`, blue tint). |
| `_tag`, `_tag_text`, `_tag_icon`, `_name`, `_effect`, `_button` | onready | `%Tag`, `%TagText`, `%TagIcon`, `%ItemName`, `%Effect`, `%ActionButton`. |

## Functions

### setup
`func setup(look: Dictionary, button_text: String, button_kind: String, on_press: Callable, is_choice := false) -> void` · `Scripts/UI/Rows/Items/gear_row.gd:28`

Fills the row for an item. `button_text` of `""` hides the button.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `look` | `Dictionary` | `HallStyle.item_look(item)` (`tag`, `icon`, `color`, `name`, `effect`) | `HallStyle.item_look(item)` in [[screen_character#_show_gear]] and [[overlay_gear_confirm#_show_swap]] |
| `button_text` | `String` | Label; `""` hides the button | `BUTTON_TAKE_OFF` (worn), `BUTTON_EQUIP` / `BUTTON_TAKE` (pick list), `""` for the chosen worn item in a swap |
| `button_kind` | `String` | `HallStyle.style_button` kind | `"paper"`, or `"green"` in the pick list |
| `on_press` | `Callable` | The button's action | `hall.unequip_item.bind(item)`, `_on_gear_picked.bind(item)`, `_pick_off.bind(worn)` |
| `is_choice` | `bool` | A row in the pick list (tinted blue) | `true` in the pick list and for the chosen worn item in a swap, else false |

**Returns:** nothing.

**Side effects:** restyles the panel; connects `pressed` on `%ActionButton` (via [[gear_row#_set_button]]).

**Called by:** [[screen_character#_show_gear]] (`screen_character.gd:269` worn items, `screen_character.gd:298` pick list), [[overlay_gear_confirm#_show_swap]] (`overlay_gear_confirm.gd:139`).

**Calls:** [[hall_style#style_icon_tag]], [[hall_style#set_font_color]], [[hall_style#style_panel]], [[gear_row#_set_button]].

### setup_empty
`func setup_empty(label: String, hint: String, button_text: String, button_kind: String, on_press: Callable) -> void` · `Scripts/UI/Rows/Items/gear_row.gd:41`

An empty gear slot: a "+" seal, `label`, `hint` (`""` hides the line) and a button.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `label` | `String` | Slot name | `TEXT_EMPTY_SLOT` in [[screen_character#_show_gear]] |
| `hint` | `String` | Line under it | `TEXT_EMPTY_HINT % role_name` if `SHOW_SLOT_HINT`, else `""` |
| `button_text` | `String` | Equip / Cancel on the first free slot of a living hero, else `""` | [[screen_character#_show_gear]] |
| `button_kind` | `String` | `"paper"` while picking, else `"blue"` | [[screen_character#_show_gear]] |
| `on_press` | `Callable` | `_toggle_gear_picker` | [[screen_character#_show_gear]] |

**Returns:** nothing.

**Called by:** [[screen_character#_show_gear]] (`screen_character.gd:281`).

**Calls:** [[hall_style#style_icon_tag]], [[hall_style#set_font_color]], [[hall_style#style_panel]], [[gear_row#_set_button]].

### _set_button
`func _set_button(button_text: String, button_kind: String, on_press: Callable) -> void` · `Scripts/UI/Rows/Items/gear_row.gd:52`

Shows the button if `button_text` is non-empty, sets its text and style (font size 24), and connects `on_press`.

**Parameters:** as in [[gear_row#setup]]. **Returns:** nothing.

**Called by:** [[gear_row#setup]] (`gear_row.gd:37`), [[gear_row#setup_empty]] (`gear_row.gd:49`).

**Calls:** [[hall_style#style_button]].

## Suspected issues
- None found.
