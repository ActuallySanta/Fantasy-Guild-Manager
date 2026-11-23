---
source: Scripts/UI/Rows/Day End/plan_row.gd
class_name: ""
extends: HBoxContainer
scene: "[[plan_row (scene)]]"
systems: ["[[Day Cycle]]", "[[Success Chance]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# plan_row.gd

## Purpose
One party going out tonight on the End Day check: quest, who, odds. Scene: [[plan_row (scene)]]. Created by [[overlay_end_day#_show_tonights_plan]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TEXT_ODDS` | const | "%d%%". |
| `_tag_box`, `_tag`, `_tag_icon`, `_title`, `_party_names`, `_odds` | onready | `%TagBox`, `%Tag`, `%TagIcon`, `%Title`, `%PartyNames`, `%Odds`. |

## Functions

### setup
`func setup(hall: HallMain, entry: Dictionary) -> void` · `Scripts/UI/Rows/Day End/plan_row.gd:19`

Fills the row: type seal, quest title, the party's names and their success chance (capped at 100, coloured by `HallStyle.odds_look`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | For `success_chance` | `hall` in [[overlay_end_day]] |
| `entry` | `Dictionary` | One of `hall.quest_entries` (a sent quest) | loop over `sent` in [[overlay_end_day#_show_tonights_plan]] |

**Returns:** nothing.

**Called by:** [[overlay_end_day#_show_tonights_plan]] (`overlay_end_day.gd:77`).

**Calls:** [[hall_style#quest_type_info]], [[hall_style#style_icon_tag]], [[hall_style#join_names]], [[hall_main#success_chance]], [[hall_style#set_font_color]], [[hall_style#odds_look]].

## Suspected issues
- None found.
