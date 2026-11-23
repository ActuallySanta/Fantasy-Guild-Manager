---
source: Scripts/UI/Tabs/tab_board.gd
class_name: ""
extends: ScrollContainer
scene: "[[tab_board (scene)]]"
systems: ["[[Party Drafting and Assignment]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# tab_board.gd

## Purpose
The Board tab, the home screen. Three pinned "Today" notes (recruits, quests decided, upgrades), then every quest of the day as a scroll in one list. Tapping a quest opens its party screen. Under the list is the End Day button, the only way to end the day: it opens the End Day check ([[hall_main#open_end_check]]). Scene: [[tab_board (scene)]]. No `class_name`; [[hall_main]] reaches it through `_tabs.board`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `QuestRowScene` | const (preload) | `uid://dxhtjf067jytf`, `Scenes/Rows/Quests/quest_row.tscn`, [[quest_row (scene)]]. |
| `TODAY_*`, `RECRUITS_*`, `QUESTS_DECIDED`, `UPGRADES_*`, `HEADING*`, `BUTTON_END_DAY` | const | Text strings and formats. |
| `_today_recruits`, `_today_quests`, `_today_upgrades` | var | `%TodayRecruits`, `%TodayQuests`, `%TodayUpgrades`, each a [[today_item]]. |
| `_heading` | var | `%Heading` label above the quest list. |
| `_quest_list` | var | `%QuestList`, the VBox that holds the runtime quest rows. |
| `_end_day_button` | var | `%EndDayButton`. |
| `hall` | var | The [[hall_main]] reference, set in `setup`. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Tabs/tab_board.gd:43`

Stores the hall and connects the three Today notes and the End Day button.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Returns:** nothing.

**Side effects:** `pressed` on `%TodayRecruits` opens the Guild tab's hire section ([[hall_main#open_tab]] with `GUILD_SECTION_HIRE`); `pressed` on `%TodayQuests` runs [[tab_board#_on_today_quests_pressed]]; `pressed` on `%TodayUpgrades` opens the Upgrades tab's build section; `pressed` on `%EndDayButton` calls [[hall_main#open_end_check]].

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_main#open_tab]], [[hall_main#open_end_check]].

### scroll_to_top
`func scroll_to_top() -> void` · `Scripts/UI/Tabs/tab_board.gd:51`

Sets `scroll_vertical = 0`.

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1851`, `shown_view.scroll_to_top()` when the view key changes). **Calls:** none.

### end_day_button
`func end_day_button() -> Button` · `Scripts/UI/Tabs/tab_board.gd:56`

The End Day button, for Pip (the tutorial) to point at.

**Returns:** `%EndDayButton`. Used by [[hall_main#end_day_button]] (`hall_main.gd:1863`), which the tutorial calls at `overlay_tutorial.gd:1019`.

**Called by:** [[hall_main#end_day_button]] (`hall_main.gd:1863`). **Calls:** none.

### refresh
`func refresh() -> void` · `Scripts/UI/Tabs/tab_board.gd:60`

Redraws the checklist, the quest list, and the End Day label (`"End Day <day>"`).

**Called by:** [[hall_main#_refresh_content]] (`hall_main.gd:1843`, `shown_view.refresh()` while the Board is the active tab).

**Calls:** [[tab_board#_show_today_checklist]], [[tab_board#_show_quest_list]].

### _show_today_checklist
`func _show_today_checklist() -> void` · `Scripts/UI/Tabs/tab_board.gd:69`

Fills the three notes. Each is "todo" (dark ink) when it wants a visit, "done" (green) or "idle" (faded), or "locked" while the tutorial hasn't unlocked it.

**Called by:** [[tab_board#refresh]] (`tab_board.gd:61`). **Calls:** [[tab_board#_show_recruits_box]], [[tab_board#_show_quests_box]], [[tab_board#_show_upgrades_box]].

### _show_recruits_box
`func _show_recruits_box() -> void` · `Scripts/UI/Tabs/tab_board.gd:75`

Recruits note. Locked while hiring isn't taught. "beds full" (idle) if the roster is full; "N new" (todo) when there are unseen recruits or an empty roster, with N = the For Hire pool size; otherwise "living / max hired" (idle).

**Called by:** [[tab_board#_show_today_checklist]]. **Calls:** [[hall_main#is_locked]], [[hall_main#is_roster_full]], [[hall_main#unseen_recruit_count]], [[today_item#set_item]].

### _show_quests_box
`func _show_quests_box() -> void` · `Scripts/UI/Tabs/tab_board.gd:90`

"Decided Quests" note: `decided / total`, look "done" once none are undecided, else "todo".

**Called by:** [[tab_board#_show_today_checklist]]. **Calls:** [[hall_main#decided_count]], [[hall_main#undecided_count]], [[today_item#set_item]].

### _show_upgrades_box
`func _show_upgrades_box() -> void` · `Scripts/UI/Tabs/tab_board.gd:96`

Upgrades note: locked while the Upgrades tab is locked; otherwise "N ready" (todo) from [[hall_main#affordable_buildings]] or "none yet" (idle).

**Called by:** [[tab_board#_show_today_checklist]]. **Calls:** [[hall_main#is_tab_locked]], [[hall_main#affordable_buildings]], [[today_item#set_item]].

### _on_today_quests_pressed
`func _on_today_quests_pressed() -> void` · `Scripts/UI/Tabs/tab_board.gd:107`

The Decided note jumps to the next undecided quest (does nothing once all are decided).

**Called by:** `pressed` on `%TodayQuests` (connected in [[tab_board#setup]], `tab_board.gd:46`). **Calls:** [[hall_main#undecided_count]], [[hall_main#open_assign]], [[hall_main#next_undecided_index]].

### _show_quest_list
`func _show_quest_list() -> void` · `Scripts/UI/Tabs/tab_board.gd:114`

Sets the heading ("The Final Battle" on the final day, "The Bone Drake" on a milestone day, else "Today's Quests", from the first entry's `final` / `milestone` flags), clears the list and adds one [[quest_row (scene)]] per quest in board order.

**Side effects:** `HallStyle.clear_children(_quest_list)`, then `HallStyle.add_row(_quest_list, QuestRowScene).setup(hall, quest_index)` ([[quest_row#setup]]) per entry.

**Called by:** [[tab_board#refresh]] (`tab_board.gd:62`). **Calls:** [[tab_board#_board_order]], [[hall_style#clear_children]], [[hall_style#add_row]], [[quest_row#setup]].

### _board_order
`func _board_order() -> Array` · `Scripts/UI/Tabs/tab_board.gd:128`

**Returns:** `Array` of indexes into `hall.quest_entries`: story quests ([[hall_style#is_story_quest]]) first, then the rest, each in day order. Used by [[tab_board#_show_quest_list]] (`tab_board.gd:123`).

**Called by:** [[tab_board#_show_quest_list]]. **Calls:** [[hall_style#is_story_quest]].

## Suspected issues
- `HEADING_MILESTONE` ("The Bone Drake") is used whenever the first entry has the `milestone` flag; if that flag is also set on the later boss days (Necromancer, Demon Generals) the heading is wrong there. Not traced. `tab_board.gd:24`.
