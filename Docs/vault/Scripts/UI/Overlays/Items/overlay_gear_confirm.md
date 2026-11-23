---
source: Scripts/UI/Overlays/Items/overlay_gear_confirm.gd
class_name: ""
extends: Control
scene: "[[overlay_gear_confirm (scene)]]"
systems: ["[[Items and Shop]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_gear_confirm.gd

## Purpose
Asked before gear comes off a hero, from the Pack. Two kinds: **take off** ("Take the X off Y?" with the stat it drops: Keep it on / Take off) and **swap** (for a hero whose gear slots are full: the new item, a pick of which worn item comes off, what that does to their stats, Cancel / Swap). It belongs to [[tab_pack]], which opens it and acts on its signals. Tapping the dim cancels. It is `top_level`. It has no `setup(hall)`. Scene: [[overlay_gear_confirm (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `GearRowScene` | preload | `Scenes/Rows/Items/gear_row.tscn` ([[gear_row (scene)]]), one per worn item in a swap. |
| `TITLE_TAKE_OFF`, `TITLE_SWAP`, `ON_LINE`, `CHOICE_HEADING`, `NOTE_TAKE_OFF`, `NOTE_SWAP`, `BUTTON_PICK`, `BUTTON_KEEP`, `BUTTON_TAKE_OFF`, `BUTTON_CANCEL`, `BUTTON_SWAP` | const | UI strings. |
| `_dim`, `_portrait`, `_title`, `_on_line`, `_choice_heading`, `_choices`, `_changes`, `_note`, `_cancel_button`, `_confirm_button` | onready | Scene nodes `%Dim`, `%Portrait`, `%Title`, `%OnLine`, `%ChoiceHeading`, `%Choices`, `%Changes`, `%Note`, `%CancelButton`, `%ConfirmButton`. |
| `_request` | var | `{}` while closed, else `{"kind": "take_off", "item"}` or `{"kind": "swap", "item_on", "character", "item_off"}`. |
| `take_off_confirmed(item)` | signal | Take off confirmed. Listener: [[tab_pack#_on_take_off_confirmed]] (`tab_pack.gd:106`). |
| `swap_confirmed(item_on, item_off, character)` | signal | Swap confirmed. Listener: [[tab_pack#_on_swap_confirmed]] (`tab_pack.gd:107`). |
| `closed` | signal | Cancel / Keep it on, dim tap, or the gear moved meanwhile. Listener: `_confirm.closed.connect(_confirm.close)` calling [[overlay_gear_confirm#close]] (`tab_pack.gd:108`). |

## Functions

### _ready
`func _ready() -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:50`

Sets the choice heading text and connects `pressed` on `%CancelButton` (emits `closed`), `pressed` on `%ConfirmButton` ([[overlay_gear_confirm#_on_confirm]]) and `gui_input` on `%Dim` ([[overlay_gear_confirm#_on_dim_input]]). Called by the engine.

### open_take_off
`func open_take_off(item: StandardItem) -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:58`

Asks before taking a worn item off its wearer. Does nothing if `item.curr_user` is null.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The worn item | `_selected` in [[tab_pack#_on_action_pressed]] (`tab_pack.gd:231`), called only when `_selected.curr_user != null` |

**Returns:** nothing.

**Side effects:** sets `_request`, shows and fades in the sheet.

**Called by:** [[tab_pack#_on_action_pressed]] (`tab_pack.gd:231`).

**Calls:** [[overlay_gear_confirm#_show]].

### open_swap
`func open_swap(item_on: StandardItem, character: GuildCharacter) -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:66`

Asks which worn item comes off so `item_on` can go on `character` (slots full). Starts with their first worn item (`equipped_items[0]`) chosen. Does nothing if they wear nothing.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item_on` | `StandardItem` | The item to put on | `item` (= `_selected`) in [[tab_pack#_on_swap_chosen]] (`tab_pack.gd:245`) |
| `character` | `GuildCharacter` | The hero with full slots | The `swap_chosen(character)` argument from [[overlay_equip_picker]] |

**Returns:** nothing.

**Called by:** [[tab_pack#_on_swap_chosen]] (`tab_pack.gd:245`).

**Calls:** [[overlay_gear_confirm#_show]].

### close
`func close() -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:73`

Clears `_request` and hides the sheet.

**Called by:** [[tab_pack#_on_take_off_confirmed]] (`tab_pack.gd:249`), [[tab_pack#_on_swap_confirmed]] (`tab_pack.gd:254`), and the `closed` signal (`tab_pack.gd:108`).

### is_open
`func is_open() -> bool` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:78`

**Returns:** `true` while a request is pending.

**Called by:** nobody found. The `popup.is_open()` at `hall_header.gd:178` is on the header's gold/standing popups, not this overlay.

### _show
`func _show() -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:82`

Makes the sheet visible, draws it and fades it in.

**Called by:** [[overlay_gear_confirm#open_take_off]] (`:62`), [[overlay_gear_confirm#open_swap]] (`:70`).

**Calls:** [[overlay_gear_confirm#refresh]], [[hall_fx#fade_in]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:89`

Redraws for the current request (nothing while `_request` is empty). The code closes (emits `closed`) from the show functions if the gear moved meanwhile.

**Called by:** [[overlay_gear_confirm#_show]] (`:84`), [[overlay_gear_confirm#_pick_off]] (`:155`), [[tab_pack#refresh]] (`tab_pack.gd:123`).

**Calls:** [[overlay_gear_confirm#_show_take_off]], [[overlay_gear_confirm#_show_swap]].

### _show_take_off
`func _show_take_off() -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:98`

Draws the take-off question: wearer's portrait, title, the stat change, note, buttons "Keep it on" / "Take off" (red-text paper). Emits `closed` if the item no longer has a wearer.

**Side effects:** may emit `closed`.

**Called by:** [[overlay_gear_confirm#refresh]] (`:93`).

**Calls:** [[hall_style#item_look]], [[portrait#show_character]], [[overlay_gear_confirm#_set_changes]], [[hall_gear#preview]], [[hall_style#style_button]], [[hall_style#set_font_color]].

### _show_swap
`func _show_swap() -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:118`

Draws the swap question. If the chosen `item_off` is no longer worn, falls back to their first worn item (or emits `closed` if they wear nothing). Lists one [[gear_row (scene)]] per worn item (the chosen one shows no button), with "Pick" binding [[overlay_gear_confirm#_pick_off]].

**Side effects:** clears and refills `%Choices`; may emit `closed`.

**Called by:** [[overlay_gear_confirm#refresh]] (`:95`).

**Calls:** [[hall_style#item_look]], [[portrait#show_character]], [[hall_style#clear_children]], [[hall_style#add_row]], [[gear_row#setup]] (`gear_row.gd:28`), [[overlay_gear_confirm#_set_changes]], [[hall_gear#preview]], [[hall_style#style_button]].

### _set_changes
`func _set_changes(changes: Array[Dictionary]) -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:148`

Shows `%Changes` (hidden if empty) with `HallGear.preview_text(changes)`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `changes` | `Array[Dictionary]` | Stat changes | `HallGear.preview(...)` in `_show_take_off` (`:110`) and `_show_swap` (`:140`) |

**Called by:** [[overlay_gear_confirm#_show_take_off]], [[overlay_gear_confirm#_show_swap]].

**Calls:** [[hall_gear#preview_text]].

### _pick_off
`func _pick_off(item: StandardItem) -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:153`

Sets `_request.item_off` to `item` and redraws.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The worn item chosen to come off | Bound with `_pick_off.bind(worn)` as the Pick button callback in [[overlay_gear_confirm#_show_swap]] (`:137`) |

**Called by:** `pressed` on the Pick button of a gear row (through `gear_row.setup`'s `on_press`).

**Calls:** [[overlay_gear_confirm#refresh]].

### _on_confirm
`func _on_confirm() -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:158`

Emits `take_off_confirmed(item)` or `swap_confirmed(item_on, item_off, character)` by `_request.kind`. Does nothing when closed.

**Called by:** `pressed` on `%ConfirmButton`.

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Items/overlay_gear_confirm.gd:167`

A mouse press on the dim emits `closed`.

**Called by:** `gui_input` on `%Dim`.

## Suspected issues
- `is_open()` has no real caller (dead code). The index's `hall_header.gd:178` match is a different object.
- The `refresh` doc says "closes itself if the gear moved meanwhile", but it does so only by emitting `closed` from `_show_take_off` / `_show_swap`; `tab_pack` turns that into `close()`.
