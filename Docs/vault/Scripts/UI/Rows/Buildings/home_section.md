---
source: Scripts/UI/Rows/Buildings/home_section.gd
class_name: ""
extends: PanelContainer
scene: "[[home_section (scene)]]"
systems: ["[[Night - Training Hospital Revive]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# home_section.gd

## Purpose
One building's card on the Upgrades tab's Facilities half: the Training Yard (heroes in a slot, plus "+ Add a hero" to pick more) or the Hospital (heroes in a bed, hurt heroes, fallen heroes). Its rows are [[home_row (scene)]]. Scene: [[home_section (scene)]], placed twice in [[tab_upgrades (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `HomeRowScene` | preload | `Scenes/Rows/Buildings/home_row.tscn` ([[home_row (scene)]]). |
| `HeadingScene` | preload | `Scenes/Rows/Buildings/home_heading.tscn` ([[home_heading (scene)]]). |
| `SHOW_TRAINING_SUMMARY` | const | SIMPLIFIED: the Training Yard's "0 of 1 slot · +1 a night" line (false). |
| `SHOW_HOSPITAL_CALM_SUMMARY` | const | SIMPLIFIED: the Hospital's "2 in a bed" / "Nobody is hurt" line (false). The red "1 hurt, not in a bed" warning shows either way. |
| `SHOW_EMPTY_TRAINING_NOTE` | const | SIMPLIFIED: "Trainees gain a stat each night." in an empty Training Yard (false). |
| `TEXT_*`, `HEADING_*`, `BUTTON_*` | const | UI strings. |
| `_tag_box`, `_tag`, `_tag_icon`, `_name`, `_level`, `_summary`, `_list`, `_empty_label`, `_add_button` | onready | `%TagBox`, `%Tag`, `%TagIcon`, `%Name`, `%Level`, `%Summary`, `%List`, `%Empty`, `%AddButton`. |
| `hall` | var | The `HallMain`, set in [[home_section#setup]]. |
| `building` | var | `GuildUpgrades.Building.TRAINING_YARD` or `HOSPITAL`. |

## Functions

### setup
`func setup(main: HallMain, section_building: int) -> void` · `Scripts/UI/Rows/Buildings/home_section.gd:51`

Stores the hall and building, styles the tag (icon from `HallStyle.BUILDING_ICONS`, colour from `GuildUpgrades.get_building_color` darkened), sets the name, and connects `%AddButton` `pressed` to `hall.toggle_training_picker` ([[hall_main#toggle_training_picker]]).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The main hall | `hall` in [[tab_upgrades#setup]] |
| `section_building` | `int` | A `GuildUpgrades.Building` value | `GuildUpgrades.Building.TRAINING_YARD` / `HOSPITAL` in [[tab_upgrades#setup]] |

**Returns:** nothing.

**Called by:** [[tab_upgrades#setup]] (`tab_upgrades.gd:61` for `%TrainingSection`, `tab_upgrades.gd:62` for `%HospitalSection`).

**Calls:** [[guild_upgrades#get_building_color]], [[hall_style#style_icon_tag]], [[guild_upgrades#get_building_name]], [[hall_style#style_panel]].

### refresh
`func refresh() -> void` · `Scripts/UI/Rows/Buildings/home_section.gd:63`

Sets the "Lv N" text, clears the list, and rebuilds it for a Training Yard or a Hospital.

**Parameters:** none. **Returns:** nothing.

**Called by:** [[tab_upgrades#refresh]] (`tab_upgrades.gd:76` and `77`, only on the Tonight half).

**Calls:** [[guild_upgrades#get_level]], [[hall_style#clear_children]], [[home_section#_show_training]], [[home_section#_show_hospital]].

### _add_heading
`func _add_heading(text: String) -> void` · `Scripts/UI/Rows/Buildings/home_section.gd:72`

Adds a [[home_heading (scene)]] label with `text` to `%List`.

**Parameters:** `text` (`String`), one of the `HEADING_*` constants. **Returns:** nothing.

**Called by:** [[home_section#_show_training]] (`home_section.gd:99`, `103`), [[home_section#_show_hospital]] (`home_section.gd:145`, `149`, `153`).

**Calls:** [[hall_style#add_row]].

### _add_row
`func _add_row() -> Node`  · `Scripts/UI/Rows/Buildings/home_section.gd:76`

Adds a [[home_row (scene)]] to `%List`.

**Returns:** the new row `Node`, on which the caller calls a `show_*` function ([[home_row]]).

**Called by:** [[home_section#_show_training]], [[home_section#_show_hospital]].

**Calls:** [[hall_style#add_row]].

### _show_training
`func _show_training() -> void` · `Scripts/UI/Rows/Buildings/home_section.gd:82`

Training Yard body: trainees as slot rows, then, if the picker is open (`hall.training_picker_open`) and a slot is free, a "PICK A HERO" list of heroes who can train and a "CAN'T TRAIN" list. Updates the add button (hidden for an empty roster, "All slots are full" disabled, "Done picking" / "+ Add a hero").

**Parameters:** none. **Returns:** nothing.

**Called by:** [[home_section#refresh]] (`home_section.gd:67`).

**Calls:** [[guild_upgrades#get_training_slots]], [[hall_main#roster]], [[guild_upgrades#is_training]], [[hall_style#pick_plural]], [[guild_upgrades#get_training_gain]], [[hall_style#set_font_color]], [[guild_upgrades#has_free_training_slot]], [[home_row#show_training_slot]], [[guild_upgrades#can_train]], [[hall_style#is_dead]], [[home_section#_add_heading]], [[home_row#show_can_train]], [[home_row#show_cant_train]], [[hall_style#style_button]].

### _show_hospital
`func _show_hospital() -> void` · `Scripts/UI/Rows/Buildings/home_section.gd:123`

Hospital body: "IN A BED" patients, "NEEDS CARE" hurt heroes not in a bed, "FALLEN" heroes. The summary is the red "N hurt, not in a bed" warning when anyone is waiting; the calm summaries show only with `SHOW_HOSPITAL_CALM_SUMMARY`.

**Parameters:** none. **Returns:** nothing.

**Called by:** [[home_section#refresh]] (`home_section.gd:69`).

**Calls:** [[hall_main#roster]], [[guild_upgrades#is_patient]], [[guild_upgrades#needs_care]], [[hall_style#is_dead]], [[hall_style#set_font_color]], [[home_section#_add_heading]], [[home_row#show_patient]], [[home_row#show_needs_care]], [[home_row#show_fallen]].

## Suspected issues
- None found.
