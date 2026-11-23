---
source: Scripts/UI/Rows/Day End/suggest_row.gd
class_name: ""
extends: HBoxContainer
scene: "[[suggest_row (scene)]]"
systems: ["[[Economy and Wallet]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# suggest_row.gd

## Purpose
An upgrade you can afford, offered on the End Day check with a buy button. Scene: [[suggest_row (scene)]]. Created by [[overlay_end_day#_show_upgrade_suggestions]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TEXT_NAME`, `TEXT_BUTTON` | const | "%s · Level %d", "%d gold". |
| `_tag_box`, `_tag`, `_tag_icon`, `_name`, `_effect`, `_buy_button` | onready | `%TagBox`, `%Tag`, `%TagIcon`, `%Name`, `%Effect`, `%BuyButton`. |

## Functions

### setup
`func setup(hall: HallMain, building: int) -> void` · `Scripts/UI/Rows/Day End/suggest_row.gd:20`

Shows the building's next level, its effect text and a green gold-cost button that buys it.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | `hall` in [[overlay_end_day]] |
| `building` | `int` | A `GuildUpgrades.Building` value | loop over `hall.affordable_buildings()` in [[overlay_end_day#_show_upgrade_suggestions]] |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%BuyButton` to `hall.upgrade_building` bound with `building` ([[hall_main#upgrade_building]]).

**Called by:** [[overlay_end_day#_show_upgrade_suggestions]] (`overlay_end_day.gd:94`).

**Calls:** [[guild_upgrades#get_level]], [[guild_upgrades#get_building_color]], [[hall_style#style_icon_tag]], [[guild_upgrades#get_building_name]], [[guild_upgrades#get_effect_text]], [[guild_upgrades#get_next_gold_cost]], [[hall_style#style_button]].

## Suspected issues
- None found.
