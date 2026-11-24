---
source: Scripts/UI/Tabs/tab_board.gd
class_name: ""
extends: ScrollContainer
scene: "[[tab_board (scene)]]"
systems: ["[[Party Drafting and Assignment]]", "[[UI Architecture and Refresh]]"]
last_verified: 2fae2e0b444f59e9c76be8bda1b39c0f01fc4ea2
tags: [script]
---

# tab_board.gd

## Purpose
The Board tab, the home screen. Every quest of the day as a scroll in one list. Tapping a quest opens its party screen. Under the list is the End Day button, the only way to end the day: it opens the End Day check ([[hall_main#open_end_check]]). Scene: [[tab_board (scene)]]. No `class_name`; [[hall_main]] reaches it through `_tabs.board`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `QuestRowScene` | const (preload) | `uid://dxhtjf067jytf`, `Scenes/Rows/Quests/quest_row.tscn`, [[quest_row (scene)]]. |
| `BUTTON_END_DAY` | const | `"End Day %d"`, the End Day button's text. |
| `_quest_list` | var | `%QuestList`, the VBox that holds the runtime quest rows. |
| `_end_day_button` | var | `%EndDayButton`. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Tabs/tab_board.gd:23`

Stores the hall and connects the End Day button.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Returns:** nothing.

**Side effects:** `pressed` on `%EndDayButton` calls [[hall_main#open_end_check]].

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_main#open_end_check]].

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Tabs/tab_board.gd:28`

Sets `scroll_vertical = 0`.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1851`, `shown_view.scroll_to_top()` when the view key changes). **Calls:** none.

### end_day_button
`func end_day_button() -> Button` · `Scripts/UI/Tabs/tab_board.gd:33`

The End Day button, for Pip (the tutorial) to point at.

**Returns:** `%EndDayButton`. Used by [[hall_main#end_day_button]] (`hall_main.gd:1863`), which the tutorial calls at `overlay_tutorial.gd:1019`.

**Called by:** [[hall_main#end_day_button]] (`hall_main.gd:1863`). **Calls:** none.

### refresh
`func refresh() -> void` · `Scripts/UI/Tabs/tab_board.gd:37`

Redraws the quest list and sets the End Day label (`"End Day <day>"`).

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1843`, `shown_view.refresh()` while the Board is the active tab).

**Calls:** [[tab_board#_show_quest_list]].

### _show_quest_list
`func _show_quest_list() -> void` · `Scripts/UI/Tabs/tab_board.gd:44`

Clears the list and adds one [[quest_row (scene)]] per quest in board order.

**Side effects:** `HallStyle.clear_children(_quest_list)`, then `HallStyle.add_row(_quest_list, QuestRowScene).setup(hall, quest_index)` ([[quest_row#setup]]) per entry.

**Called by:** [[tab_board#refresh]] (`tab_board.gd:38`). **Calls:** [[tab_board#_board_order]], [[hall_style#clear_children]], [[hall_style#add_row]], [[quest_row#setup]].

### _board_order
`func _board_order() -> Array` · `Scripts/UI/Tabs/tab_board.gd:52`

**Returns:** `Array` of indexes into `hall.quest_entries`: story quests ([[hall_style#is_story_quest]]) first, then the rest, each in day order. Used by [[tab_board#_show_quest_list]] (`tab_board.gd:46`).

**Called by:** [[tab_board#_show_quest_list]]. **Calls:** [[hall_style#is_story_quest]].
