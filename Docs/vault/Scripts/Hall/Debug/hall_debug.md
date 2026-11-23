---
source: Scripts/Hall/Debug/hall_debug.gd
class_name: HallDebug
extends: RefCounted
scene: null
systems: ["[[Day Cycle]]", "[[Hiring Characters]]", "[[Night - Training Hospital Revive]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_debug.gd

## Purpose
`HallDebug`: the rules behind the Menu's Debug tools ([[overlay_debug]]): cheats for testing a run. Static functions only. [[hall_main]]'s `debug_*` actions call them, then show a toast and refresh. None of them count toward `run_stats`, so Game Over and the credits only show what the player really did. Turning the tools on makes the run a debug run (`HallMain.is_debug_run`), which is never saved again.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `GOLD_STEPS` | const | `[100, 1000]`: gold added per tap of each wallet button (negative takes gold away). Read by [[overlay_debug]] (`overlay_debug.gd:106`) to build buttons bound to `hall.debug_add_gold`. |
| `STANDING_STEPS` | const | `[5, -5]`: standing added per tap (the negative is for testing the danger strip and Game Over). Read at `overlay_debug.gd:108`. |
| `JUMP_DAYS` | const | `[HallMain.MILESTONE_DAY, HallMain.FINAL_DAY]`: days the "Jump to day" buttons go to (Bone Drake, final battle). Read at `overlay_debug.gd:102`. |

## Functions

### can_skip_day
`static func can_skip_day(hall: HallMain) -> bool` · `Scripts/Hall/Debug/hall_debug.gd:23`

True when the day can be skipped now: not while the night is falling or a report, Game Over or credits are up, and never past the final battle outside freeplay.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall script | `hall` of [[overlay_debug]], or the argument passed down from `skip_day` / `can_jump_to` |

**Returns:** `bool`. [[overlay_debug#refresh]] uses it to disable `_skip_button` (`overlay_debug.gd:144`); `skip_day` and `can_jump_to` use it as a guard.

**Side effects:** none.

**Called by:** [[hall_debug#skip_day]] (`hall_debug.gd:36`), [[hall_debug#can_jump_to]] (`hall_debug.gd:45`), [[overlay_debug#refresh]] (`overlay_debug.gd:144`).

**Calls:** nothing.

### skip_day
`static func skip_day(hall: HallMain) -> bool` · `Scripts/Hall/Debug/hall_debug.gd:35`

Skip to the next dawn: tonight's training and healing still run (`GuildUpgrades.run_night`), but no quest is played and no Day Report shows. Today's drafted parties go with today's quests.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall script | `self` in [[hall_main#debug_skip_day]]; `hall` in `jump_to_day` |

**Returns:** `bool`, false if the day can't be skipped now. [[hall_main#debug_skip_day]] shows a toast on false (`hall_main.gd:1426`); `jump_to_day` stops looping on false.

**Side effects:** runs the night, calls `hall.start_new_day()`.

**Called by:** [[hall_main#debug_skip_day]] (`hall_main.gd:1426`), [[hall_debug#jump_to_day]] (`hall_debug.gd:54`).

**Calls:** [[hall_debug#can_skip_day]], [[guild_upgrades#run_night]], [[hall_main#start_new_day]].

### can_jump_to
`static func can_jump_to(hall: HallMain, day: int) -> bool` · `Scripts/Hall/Debug/hall_debug.gd:44`

True when `day` is still ahead and the day can be skipped.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall script | `hall` of [[overlay_debug]] |
| `day` | `int` | Target day | keys of `HallDebug.JUMP_DAYS` in `overlay_debug.gd:146` |

**Returns:** `bool`, used to disable each Jump button in [[overlay_debug#refresh]].

**Side effects:** none.

**Called by:** [[overlay_debug#refresh]] (`overlay_debug.gd:146`).

**Calls:** [[hall_debug#can_skip_day]].

### jump_to_day
`static func jump_to_day(hall: HallMain, day: int) -> int` · `Scripts/Hall/Debug/hall_debug.gd:52`

Run `skip_day` repeatedly until `GameState.day` reaches `day`, stopping early if the run ends on the way.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The main hall script | `self` in [[hall_main#debug_jump_to_day]] |
| `day` | `int` | Day to land on | `day` bound to the Jump button in `overlay_debug.gd:104` |

**Returns:** `int`, days skipped. [[hall_main#debug_jump_to_day]] treats 0 as "couldn't jump" (`hall_main.gd:1433`).

**Side effects:** as `skip_day`, per day.

**Called by:** [[hall_main#debug_jump_to_day]] (`hall_main.gd:1433`).

**Calls:** [[hall_debug#skip_day]].

### add_hero
`static func add_hero() -> GuildCharacter` · `Scripts/Hall/Debug/hall_debug.gd:61`

Put a random hero on the roster for free (needs a free bed): a new `GuildCharacter` with `cost = 0`, added with `CharacterContainer.add_character_to_guild`.

**Returns:** the new `GuildCharacter`, or null when the Barracks is full. [[hall_main#debug_add_hero]] toasts accordingly (`hall_main.gd:1452`).

**Side effects:** adds to `CharacterContainer.active_characters`.

**Called by:** [[hall_main#debug_add_hero]] (`hall_main.gd:1452`).

**Calls:** [[character_container#has_free_bed]], [[character_container#add_character_to_guild]].

### add_random_item
`static func add_random_item() -> StandardItem` · `Scripts/Hall/Debug/hall_debug.gd:74`

A random piece of gear (random role, usual rarity roll) put in the Pack for free. Sets `item.role` again as `ItemShop._make_item` does, since equipping is role-locked.

**Returns:** the new `StandardItem`. [[hall_main#debug_add_item]] uses it for the toast (`hall_main.gd:1459`).

**Side effects:** appends to `ItemContainer.owned_items`.

**Called by:** [[hall_main#debug_add_item]] (`hall_main.gd:1459`).

**Calls:** nothing else in the project (`PassiveItem.new`).

### heal_everyone
`static func heal_everyone() -> Dictionary` · `Scripts/Hall/Debug/hall_debug.gd:88`

Every living hero back to Healthy and out of the Hospital; the dead come back Healthy while there's a free bed (doesn't use up Hospital revives). Clears `died_on_day`, `died_on_quest`, the `GuildUpgrades.RECOVERY_META` metadata, removes from `GuildUpgrades.patients`, and rebuilds `temp_stats`.

**Returns:** `{"healed": int (living heroes healed), "revived": int, "left_dead": int (dead with no bed)}`. [[hall_main#debug_heal_everyone]] builds its toast from it (`hall_main.gd:1466`).

**Side effects:** changes heroes; emits `GuildUpgrades.home_changed`.

**Called by:** [[hall_main#debug_heal_everyone]] (`hall_main.gd:1466`).

**Calls:** [[character_container#has_free_bed]], [[character_resource#reset_temp_stats]].

### max_buildings
`static func max_buildings() -> void` · `Scripts/Hall/Debug/hall_debug.gd:113`

Every building to its top level for free.

**Returns:** nothing.

**Side effects:** changes `GuildUpgrades.levels`.

**Called by:** [[hall_main#debug_max_buildings]] (`hall_main.gd:1476`).

**Calls:** [[guild_upgrades#max_all_buildings]].

### reroll_hires
`static func reroll_hires() -> void` · `Scripts/Hall/Debug/hall_debug.gd:119`

A fresh For Hire pool for today without moving the day on. Today's quests are rebuilt by `hall_main` itself ([[hall_main#debug_reroll_today]]).

**Returns:** nothing.

**Side effects:** replaces `CharacterContainer.hireable_characters`.

**Called by:** [[hall_main#debug_reroll_today]] (`hall_main.gd:1484`).

**Calls:** [[character_container#refresh_hireable_characters]].

## Suspected issues
- None found.
