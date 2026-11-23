---
source: Scripts/UI/Components/tap_panel.gd
class_name: TapPanel
extends: PanelContainer
scene: ""
systems: ["[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# tap_panel.gd

## Purpose
A panel you can tap that still lets its ScrollContainer scroll when you drag across it. Rows that open something extend this script and connect to `pressed`. Subclasses: [[quest_row]], [[pick_row]], [[party_slot]], [[member_card]], [[today_item]], [[report_entry]]; the [[hire_peek (scene)]] uses it directly. No scene of its own. See also [[drag_scroll]] for plain controls in scroll lists.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `pressed` | signal | A tap: press and release without moving more than `TAP_MOVE_LIMIT`. Listeners: each subclass `setup`, e.g. `pressed.connect(hall.open_assign.bind(...))` in [[quest_row#setup]] (`quest_row.gd:65`); [[pick_row#setup]] (`pick_row.gd:56`, `58`); [[party_slot#setup]] (`party_slot.gd:43`, `60`); [[member_card#setup]] (`member_card.gd:53`); [[report_entry#setup]] (`report_entry.gd:195`); on the Board's today notes [[tab_board#setup]] (`tab_board.gd:45`, `46`, `47`); on `hire_peek` instances [[tab_guild#_show_for_hire]] (`tab_guild.gd:199`). |
| `TAP_MOVE_LIMIT` | const | A press that moves further than this (24 px) is a scroll, not a tap. Also read by [[drag_scroll#_on_button_input]]. |
| `_is_pressing` | var | True between a left press on this panel and its release. |
| `_press_position` | var | Where that press started (global coordinates). |

## Functions

### _init
`func _init() -> void` · `Scripts/UI/Components/tap_panel.gd:19`

Sets `mouse_filter` to PASS (not STOP) so a drag still reaches the parent ScrollContainer. Called by the engine when the node is created.

**Called by:** the engine.

### _gui_input
`func _gui_input(event: InputEvent) -> void` · `Scripts/UI/Components/tap_panel.gd:24`

Only left mouse button / touch presses matter. On press it records the position. On release, if the finger moved less than `TAP_MOVE_LIMIT` and is not over a child button, it emits `pressed`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Any input over the panel | the engine's GUI input |

**Returns:** nothing.

**Side effects:** emits `pressed`.

**Called by:** the engine (GUI input on this control).

**Calls:** [[tap_panel#_is_over_child_button]].

### _is_over_child_button
`func _is_over_child_button() -> bool` · `Scripts/UI/Components/tap_panel.gd:42`

True when the finger is on a button inside this panel (e.g. [[pick_row]]'s Info button). Buttons in scroll lists are Pass ([[drag_scroll]]), so their taps also reach this panel; that tap belongs to the button, not to the row.

**Parameters:** none.

**Returns:** `bool`, used by [[tap_panel#_gui_input]] to suppress `pressed`.

**Called by:** [[tap_panel#_gui_input]] (`tap_panel.gd:35`).

## Suspected issues
- None found.
