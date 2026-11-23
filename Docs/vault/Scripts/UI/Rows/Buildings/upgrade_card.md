---
source: Scripts/UI/Rows/Buildings/upgrade_card.gd
class_name: ""
extends: PanelContainer
scene: "[[upgrade_card (scene)]]"
systems: ["[[Economy and Wallet]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# upgrade_card.gd

## Purpose
One building on the Upgrades tab, drawn as a plan on grid paper: its icon, level diamonds, what it does now and next, and the Build button (or why you can't yet). Scene: [[upgrade_card (scene)]]. Created by [[tab_upgrades#_show_building_cards]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `NEW_PIP_DELAY` | const | Seconds after Build before the new level diamond stamps in (lets the building squash first). |
| `SHOW_LEVEL_TEXT` | const | SIMPLIFIED: "Level 2 / 5" beside the diamonds (false). |
| `SHOW_READY_STATUS` | const | SIMPLIFIED: "ready to build" beside an enabled Build button (false). "need 40 more gold" / "needs standing 3" still show on a disabled one. |
| `TEXT_LEVEL`, `TEXT_NOW`, `TEXT_NEXT`, `TEXT_MAXED`, `TEXT_BUTTON`, `TEXT_BUTTON_MAX`, `TEXT_NEED_GOLD`, `TEXT_NEED_STANDING`, `TEXT_READY` | const | UI strings. |
| `_icon`, `_name`, `_level`, `_pips`, `_now`, `_next`, `_status`, `_upgrade_button` | onready | `%Icon`, `%Name`, `%Level`, `%Pips`, `%Now`, `%Next`, `%Status`, `%UpgradeButton`. |

## Functions

### setup
`func setup(hall: HallMain, building: int) -> void` · `Scripts/UI/Rows/Buildings/upgrade_card.gd:48`

Fills the card for one building and connects the Build button. Plays the built animation if `hall.pending_fx["upgraded"] == building`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall | `hall` in [[tab_upgrades]] |
| `building` | `int` | A `GuildUpgrades.Building` value | loop over `buildings` (`HallStyle.buildings_in_order()` filtered by `GuildUpgrades.is_implemented`, affordable first) in [[tab_upgrades#_show_building_cards]] |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%UpgradeButton` to `hall.upgrade_building` bound with `building` ([[hall_main#upgrade_building]]).

**Called by:** [[tab_upgrades#_show_building_cards]] (`tab_upgrades.gd:114`).

**Calls:** [[guild_upgrades#get_level]], [[guild_upgrades#is_max_level]], [[upgrade_card#_show_name_and_level]], [[upgrade_card#_show_effects]], [[upgrade_card#_show_status]], [[upgrade_card#_play_built]].

### _play_built
`func _play_built(level: int) -> void` · `Scripts/UI/Rows/Buildings/upgrade_card.gd:61`

Just built: the building squashes and stretches, the new level's diamond stamps in (after `NEW_PIP_DELAY`), and "Level 3 / 5" pops.

**Parameters:** `level` (`int`), the building's level from `GuildUpgrades.get_level` in [[upgrade_card#setup]].

**Returns:** nothing. **Side effects:** [[hall_fx#squash]], [[hall_fx#stamp_in]], [[hall_fx#pop]] tweens.

**Called by:** [[upgrade_card#setup]] (`upgrade_card.gd:56`).

**Calls:** [[hall_fx#squash]], [[hall_fx#stamp_in]], [[hall_fx#pop]].

### _show_name_and_level
`func _show_name_and_level(building: int, level: int) -> void` · `Scripts/UI/Rows/Buildings/upgrade_card.gd:70`

Icon, name, "Level 2 / 5" (only if `SHOW_LEVEL_TEXT`) and one diamond per level (filled up to the level; the diamonds are authored in the scene as `Pip0` to `Pip4`).

**Parameters:** `building`, `level` as in [[upgrade_card#setup]]. **Returns:** nothing.

**Called by:** [[upgrade_card#setup]] (`upgrade_card.gd:52`).

**Calls:** [[hall_style#icon_texture]], [[guild_upgrades#get_building_name]].

### _show_effects
`func _show_effects(building: int, level: int, is_maxed: bool) -> void` · `Scripts/UI/Rows/Buildings/upgrade_card.gd:82`

"Now · ..." and "Next · ..." (or "Fully built").

**Parameters:** `building`, `level`; `is_maxed` (`bool`) from `GuildUpgrades.is_max_level` in [[upgrade_card#setup]]. **Returns:** nothing.

**Called by:** [[upgrade_card#setup]] (`upgrade_card.gd:53`).

**Calls:** [[guild_upgrades#get_effect_text]].

### _show_status
`func _show_status(building: int, is_maxed: bool) -> void` · `Scripts/UI/Rows/Buildings/upgrade_card.gd:91`

Build button (cost, or "Built") and the status line: ready (blank unless `SHOW_READY_STATUS`), need gold (gold ink), or standing too low (red). The button is disabled unless the status is `READY`.

**Parameters:** `building`, `is_maxed` as above. **Returns:** nothing.

**Called by:** [[upgrade_card#setup]] (`upgrade_card.gd:54`).

**Calls:** [[guild_upgrades#get_upgrade_status]], [[guild_upgrades#get_next_gold_cost]], [[guild_upgrades#get_next_standing_req]], [[hall_style#set_font_color]].

## Suspected issues
- None found.
