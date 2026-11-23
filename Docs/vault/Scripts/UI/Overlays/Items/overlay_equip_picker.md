---
source: Scripts/UI/Overlays/Items/overlay_equip_picker.gd
class_name: ""
extends: Control
scene: "[[overlay_equip_picker (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_equip_picker.gd

## Purpose
The sheet that slides up from the Pack's "Equip on..." button. Head (the item's seal, name, effect), "Can wear" (one `equip_pick_row` per living hero of the item's role, free slots first: Equip, or Swap... when slots are full), "Wrong role" (the other heroes named) and Cancel. It belongs to [[tab_pack]], which opens it and acts on its signals. Tapping the dim closes it too. It is `top_level`, so it draws over the whole screen. It has no `setup(hall)`: it never talks to the hall. Scene: [[overlay_equip_picker (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `PickRowScene` | preload | `Scenes/Rows/Items/equip_pick_row.tscn` ([[equip_pick_row (scene)]]), one per hero. |
| `TITLE`, `CAN_WEAR`, `NONE_CAN_WEAR`, `WRONG_ROLE`, `BUTTON_EQUIP`, `BUTTON_SWAP`, `BUTTON_CANCEL` | const | UI strings. |
| `_dim`, `_tag`, `_tag_text`, `_tag_icon`, `_title`, `_effect`, `_can_wear`, `_fits`, `_none_note`, `_wrong_role`, `_cancel_button` | onready | Scene nodes `%Dim`, `%Tag`, `%TagText`, `%TagIcon`, `%Title`, `%Effect`, `%CanWear`, `%Fits`, `%NoneNote`, `%WrongRole`, `%CancelButton`. |
| `_item` | var | The item being equipped (null while closed). |
| `equip_chosen(character)` | signal | A hero with a free slot was picked. Listener: [[tab_pack#_on_equip_chosen]] (`tab_pack.gd:103`). |
| `swap_chosen(character)` | signal | A hero whose slots are full was picked. Listener: [[tab_pack#_on_swap_chosen]] (`tab_pack.gd:104`). |
| `closed` | signal | Cancel or a tap on the dim. Listener: `_picker.closed.connect(_picker.close)`, which calls [[overlay_equip_picker#close]] (`tab_pack.gd:105`). |

## Functions

### _ready
`func _ready() -> void` · `Scripts/UI/Overlays/Items/overlay_equip_picker.gd:46`

Sets the "Can wear" and Cancel texts and connects `pressed` on `%CancelButton` (emits `closed`) and `gui_input` on `%Dim`. Called by the engine.

**Calls:** [[overlay_equip_picker#_on_dim_input]] (connection).

### open
`func open(item: StandardItem) -> void` · `Scripts/UI/Overlays/Items/overlay_equip_picker.gd:54`

Shows the picker for an owned item.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The unworn item to equip | `_selected` in [[tab_pack#_on_action_pressed]] (`tab_pack.gd:233`), the item picked in the Pack grid. Only called when `curr_user` is null. |

**Returns:** nothing.

**Side effects:** sets `_item`, becomes visible, fades in.

**Called by:** [[tab_pack#_on_action_pressed]] (`tab_pack.gd:233`).

**Calls:** [[overlay_equip_picker#refresh]], [[hall_fx#fade_in]].

### close
`func close() -> void` · `Scripts/UI/Overlays/Items/overlay_equip_picker.gd:61`

Clears `_item` and hides the sheet.

**Returns:** nothing.

**Called by:** [[tab_pack#_on_equip_chosen]] (`tab_pack.gd:238`), [[tab_pack#_on_swap_chosen]] (`tab_pack.gd:244`), and the `closed` signal ([[tab_pack#setup]], `tab_pack.gd:105`).

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Items/overlay_equip_picker.gd:67`

Rebuilds for the current item (the roster or gear may have changed). Does nothing while `_item` is null. Draws the seal, name and effect from `HallStyle.item_look`, then one pick row per hero from `HallGear.heroes_for`: a free slot gets "Equip" (gold, emits `equip_chosen`), full slots get "Swap..." (paper, emits `swap_chosen`). Shows `%NoneNote` if nobody can wear it, and `%WrongRole` naming the other-role heroes.

**Returns:** nothing.

**Side effects:** clears and refills `%Fits` with [[equip_pick_row (scene)]] rows.

**Called by:** [[overlay_equip_picker#open]] (`overlay_equip_picker.gd:57`), [[tab_pack#refresh]] (`tab_pack.gd:122`), which is itself called from `hall_main`'s refresh.

**Calls:** [[hall_style#item_look]], [[hall_style#style_icon_tag]], [[hall_style#clear_children]], [[hall_gear#heroes_for]], [[hall_gear#preview]], [[hall_style#add_row]], [[hall_gear#has_free_slot]], [[equip_pick_row#setup]] (`equip_pick_row.gd:25`), [[hall_style#item_role_name]], [[hall_gear#heroes_wrong_role]], [[hall_style#join_names]].

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Items/overlay_equip_picker.gd:93`

A mouse press on the dim emits `closed`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `%Dim` |

**Returns:** nothing.

**Called by:** signal `gui_input` on `%Dim`.

## Suspected issues
- The index's text-search lists other `open`/`close` callers (file and CSV writers, `hall_header`); those are other objects, not callers.
