---
source: Scripts/UI/Overlays/Day/overlay_move_confirm.gd
class_name: ""
extends: Control
scene: "[[overlay_move_confirm (scene)]]"
systems: ["[[Party Drafting and Assignment]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_move_confirm.gd

## Purpose
Asks "Move X?" when the player taps an adventurer in Assign Party's picker who is already in another quest's party (picked or sent). Cancel closes; Move calls [[hall_main#toggle_in_party]], which pulls them off the other quest and pins them to the one on screen. It is a child of [[screen_assign (scene)]], set up and opened through [[screen_assign]]; tapping the dim cancels. The scene sets `top_level`, so it draws over the whole screen. Scene: [[overlay_move_confirm (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `BUTTON_FONT_SIZE` | const | Button font size (design px). |
| `FADE_IN_SECONDS` | const | Fade-in time (s). |
| `TITLE`, `TEXT_QUEST_NAME`, `BODY_PICKED`, `BODY_SENT`, `NOTE`, `NOTE_LAST_SENT`, `BUTTON_CANCEL`, `BUTTON_MOVE` | const | UI strings. `NOTE_LAST_SENT` is used when they are the only one on a sent quest. |
| `hall` | var | The [[hall_main]] node. |
| `_character` | var | Who the popup asks about (null = closed). |
| `_dim`, `_title`, `_body`, `_note`, `_cancel_button`, `_move_button` | onready | Scene nodes `%Dim`, `%Title`, `%Body`, `%Note`, `%CancelButton`, `%MoveButton`. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Day/overlay_move_confirm.gd:42`

Stores the hall, connects the buttons and dim, sets texts and styles (wood Cancel, gold Move).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `hall` as passed to [[screen_assign#setup]] (`screen_assign.gd:155`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%CancelButton` to [[overlay_move_confirm#close]], `pressed` on `%MoveButton` to [[overlay_move_confirm#_on_move_pressed]], `gui_input` on `%Dim` to [[overlay_move_confirm#_on_dim_input]].

**Called by:** [[screen_assign#setup]] (`screen_assign.gd:155`). It is not in hall_main's overlay list.

**Calls:** [[hall_style#style_button]].

### open
`func open(character: GuildCharacter) -> void` · `Scripts/UI/Overlays/Day/overlay_move_confirm.gd:56`

Shows the popup for `character`: title, body (picked or already sent, naming the quest as "#N title") and a note. Does nothing if `hall.quest_index_of` is negative (not in any party).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero being moved | Bound by [[pick_row#setup]] (`pick_row.gd:56`) to the `pressed` signal of a pick row whose hero is busy on another quest |

**Returns:** nothing.

**Side effects:** sets `_character`, makes itself visible, fades in.

**Called by:** `pressed` on a pick row. [[screen_assign#_show_picker]] hands `_move_confirm.open` to `pick_row.setup` as `ask_to_move` (`screen_assign.gd:370`), and the row connects it with `ask_to_move.bind(character)` (`pick_row.gd:56`).

**Calls:** [[hall_main#quest_index_of]], [[hall_fx#fade_in]].

### close
`func close() -> void` · `Scripts/UI/Overlays/Day/overlay_move_confirm.gd:73`

Hides the popup and clears `_character`.

**Returns:** nothing.

**Called by:** signal `pressed` on `%CancelButton`; [[overlay_move_confirm#_on_move_pressed]]; [[overlay_move_confirm#_on_dim_input]].

### _on_move_pressed
`func _on_move_pressed() -> void` · `Scripts/UI/Overlays/Day/overlay_move_confirm.gd:79`

Keeps the character, closes first (the move refreshes the screen), then calls [[hall_main#toggle_in_party]].

**Returns:** nothing.

**Called by:** signal `pressed` on `%MoveButton`.

**Calls:** [[overlay_move_confirm#close]], [[hall_main#toggle_in_party]].

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Day/overlay_move_confirm.gd:87`

A mouse press on the dim cancels.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `%Dim` |

**Returns:** nothing.

**Called by:** signal `gui_input` on `%Dim`.

**Calls:** [[overlay_move_confirm#close]].

## Suspected issues
- None found.
