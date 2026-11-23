---
source: Scripts/UI/Overlays/Day/overlay_end_day.gd
class_name: ""
extends: Control
scene: "[[overlay_end_day (scene)]]"
systems: ["[[Day Cycle]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_end_day.gd

## Purpose
The End Day check: a sheet over the screen before the day ends, listing who goes out tonight (one [[plan_row]] per sent quest), the denied quests, and, if any building can be bought, upgrade suggestions ([[suggest_row]]). Scene: [[overlay_end_day (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `PlanRowScene` | preload | [[plan_row (scene)]], one per sent quest. |
| `SuggestRowScene` | preload | [[suggest_row (scene)]], one per affordable building. |
| `TEXT_TITLE`, `TEXT_SUBTITLE`, `TEXT_SUBTITLE_NONE`, `TEXT_DENIED`, `TEXT_UPGRADE_TITLE`, `TEXT_UPGRADE_TITLE_PLAIN`, `BUTTON_BACK`, `BUTTON_END` | const | UI strings. |
| `SHOW_SUBTITLE` | const | SIMPLIFIED switch (false): the "N parties going out tonight" line. The "Nobody is going out" warning shows either way. |
| `SHOW_UPGRADE_GOLD` | const | SIMPLIFIED switch (false): "· N gold" after "Upgrade first?". |
| `hall` | var | The [[hall_main]] node, set in `setup`. |
| `_dim`, `_title`, `_subtitle`, `_plan_list`, `_denied_label`, `_upgrade_box`, `_upgrade_title`, `_suggest_list`, `_back_button`, `_end_button` | onready | Scene nodes `%Dim`, `%Title`, `%Sub`, `%PlanList`, `%Denied`, `%UpgradeBox`, `%UpgradeTitle`, `%SuggestList`, `%BackButton`, `%EndButton`. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Day/overlay_end_day.gd:45`

Stores the hall, connects the buttons and the dim, sets texts and styles the buttons ("paper" Back, "green" End).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] (`hall_main.gd:424`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%BackButton` to [[hall_main#close_end_check]], `pressed` on `%EndButton` to [[hall_main#end_day]], and `gui_input` on `%Dim` to [[overlay_end_day#_on_dim_input]].

**Called by:** [[hall_main#_ready]] (`hall_main.gd:424`).

**Calls:** [[hall_style#style_button]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Day/overlay_end_day.gd:56`

Redraws the title, plan and suggestions from hall queries. Does nothing while `hall.is_night_falling`, so the sheet keeps tonight's plan while the dusk falls over it.

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1866`) while visible.

**Calls:** [[overlay_end_day#_show_tonights_plan]], [[overlay_end_day#_show_upgrade_suggestions]].

### _show_tonights_plan
`func _show_tonights_plan() -> void` · `Scripts/UI/Overlays/Day/overlay_end_day.gd:67`

One [[plan_row]] per party going out, then the denied quest titles on one line.

**Returns:** nothing.

**Side effects:** rebuilds `%PlanList`; sets `%Sub` and `%Denied` text and visibility.

**Called by:** [[overlay_end_day#refresh]].

**Calls:** [[hall_main#sent_entries]], [[hall_main#denied_entries]], [[hall_style#count_text]], [[hall_style#clear_children]], [[hall_style#add_row]] (passes `PlanRowScene`, then `plan_row.setup(hall, entry)`).

### _show_upgrade_suggestions
`func _show_upgrade_suggestions() -> void` · `Scripts/UI/Overlays/Day/overlay_end_day.gd:88`

Shows `%UpgradeBox` only if any building is affordable, and adds one [[suggest_row]] per building.

**Returns:** nothing.

**Called by:** [[overlay_end_day#refresh]].

**Calls:** [[hall_main#affordable_buildings]], [[hall_style#clear_children]], [[hall_style#add_row]] (passes `SuggestRowScene`, then `suggest_row.setup(hall, building)`).

### _on_dim_input
`func _on_dim_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Day/overlay_end_day.gd:98`

Tapping the dimmed background closes the sheet (mouse button press only).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `%Dim` (connected in [[overlay_end_day#setup]]) |

**Returns:** nothing.

**Called by:** signal `gui_input` on `%Dim`.

**Calls:** [[hall_main#close_end_check]].

## Suspected issues
- None found.
