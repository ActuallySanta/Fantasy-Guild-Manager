---
source: Scripts/UI/Rows/Quests/quest_tab.gd
class_name: ""
extends: VBoxContainer
scene: "[[quest_tab (scene)]]"
systems: ["[[Party Drafting and Assignment]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# quest_tab.gd

## Purpose
One quest in Assign Party's strip: a little rolled scroll filled with its type colour (green = sent, red = denied), the quest number on it, and the type tag (or SENT / NO) under it. The quest showing now is parchment. The fill is the Band (`Themes/Styles/quest_band.tres`). Scene: [[quest_tab (scene)]]. Created by [[screen_assign#_show_quest_tabs]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `CURRENT_BAND` | const | Band colour on the quest showing now (`#F0E7D2`). |
| `TEXT_NUMBER`, `TAG_SENT`, `TAG_DENIED` | const | UI strings ("%d", "SENT", "NO"). |
| `_tab`, `_band`, `_number`, `_tag` | onready | Scene nodes `%Tab` (Button), `%Band` (Panel), `%Mark` (Label), `%Tag` (Label). |

## Functions

### setup
`func setup(hall: HallMain, quest_index: int, is_current: bool) -> void` · `Scripts/UI/Rows/Quests/quest_tab.gd:25`

Connects the tab to open Assign Party on that quest, writes the number and tag, and tints the band by state (type colour, green when sent, red when denied, parchment when current).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | `hall` in [[screen_assign]] |
| `quest_index` | `int` | Index into `hall.quest_entries` | loop variable in [[screen_assign#_show_quest_tabs]] |
| `is_current` | `bool` | This is the quest showing now | `quest_index == hall.active_screen.quest_index` in [[screen_assign#_show_quest_tabs]] |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%Tab` to `hall.open_assign` ([[hall_main#open_assign]]); stamps the tag in ([[hall_fx#stamp_in]]) when `hall.pending_fx["quest_stamp"] == quest_index`.

**Called by:** [[screen_assign#_show_quest_tabs]] (`screen_assign.gd:211`).

**Calls:** [[hall_style#quest_type_info]], [[hall_style#tint_art]], [[hall_style#set_font_color]], [[hall_fx#stamp_in]].

## Suspected issues
- None found.
