---
source: Scripts/UI/Rows/Quests/today_item.gd
class_name: ""
extends: TapPanel
scene: "[[today_item (scene)]]"
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# today_item.gd

## Purpose
One pinned note in the Board's "Today" checklist (Recruits / Decided / Upgrades). Green ink when done, dark ink when it wants a visit, faded otherwise. Extends [[tap_panel]]. Scene: [[today_item (scene)]], placed three times in [[tab_board (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `_title`, `_value` | onready | Scene nodes `%Title`, `%Value` (Labels). |

## Functions

### set_item
`func set_item(title: String, value: String, _icon_name: String, look: String) -> void` · `Scripts/UI/Rows/Quests/today_item.gd:15`

Writes the note. `look` is "done" (green), "todo" (dark ink), "idle" (faded) or "locked" (blank and greyed: Pip hasn't taught it yet, text cleared). `_icon_name` is unused (the notes are pinned paper, no icon); kept for callers.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `title` | `String` | Note heading | `TODAY_RECRUITS` / `TODAY_QUESTS` / `TODAY_UPGRADES` constants in [[tab_board]] |
| `value` | `String` | Note body, e.g. decided count | built in [[tab_board#_show_recruits_box]], [[tab_board#_show_quests_box]], [[tab_board#_show_upgrades_box]] |
| `_icon_name` | `String` | Unused | e.g. `"nav_characters"` |
| `look` | `String` | `"done"`, `"todo"`, `"idle"` or `"locked"` | chosen by the tab_board functions from hall queries |

**Returns:** nothing.

**Side effects:** sets label text and font colour; calls `HallStyle.set_locked(self, ...)`.

**Called by:** [[tab_board#_show_recruits_box]] (`tab_board.gd:77`, `81`, `84`, `87`), [[tab_board#_show_quests_box]] (`tab_board.gd:93`), [[tab_board#_show_upgrades_box]] (`tab_board.gd:98`, `103`).

**Calls:** [[hall_style#set_locked]], [[hall_style#set_font_color]].

## Suspected issues
- `_icon_name` is an unused parameter, kept only for callers (noted in its comment).
