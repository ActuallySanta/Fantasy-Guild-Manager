---
source: Scripts/Hall/Rules/hall_ledger.gd
class_name: HallLedger
extends: null
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_ledger.gd

## Purpose
How the run stands (is it over, is it one death from over) and the numbers the Game Over ledger and the final battle's credits show. No state and no nodes. Every function is static and takes the roster and [[hall_main]]'s `run_stats` as parameters (or reads autoloads). The run's state stays on `HallMain`, so a new run (which reloads the hall scene) starts from zero. [[hall_main]] wraps most of these in one-line query functions so views only talk to `hall`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `DANGER_STANDING_MARGIN` | const | 3 standing points. Standing within this many points of `GuildUpgrades.MINIMUM_STANDING` counts as "nearly too low for recruits" for the header's "last hero standing" strip. |

## Functions

### is_run_over
`static func is_run_over() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:23`

True when the guild can never send anyone out again: nobody is alive (patients in the Hospital count as alive), nobody in today's For Hire is affordable, and no recruit ever will be (standing at or under the floor, or tomorrow's price is already more than the gold left, and prices never go down). Never true on the free-recruit days.

**Parameters:** none (reads `CharacterContainer`, `GameState`, `GuildUpgrades`).

**Returns:** `bool`. [[hall_main#is_run_over]] returns it (or'd with `final_battle_lost`), and the hall uses that to show Game Over.

**Side effects:** none.

**Called by:** [[hall_main#is_run_over]] (`hall_main.gd:549`).

**Calls:** [[character_container#living_count]], [[hall_ledger#can_afford_a_recruit_today]], [[hall_ledger#is_short_of_recruit_gold]].

### is_one_death_from_falling
`static func is_one_death_from_falling() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:36`

True when exactly one hero is left alive and losing them would (or nearly would) end the run: nobody in today's For Hire is affordable, and either tomorrow's recruit price is more than the gold left, or standing is within `DANGER_STANDING_MARGIN` of the floor. Drives the header's warning strip. Never true on the free-recruit days.

**Parameters:** none.

**Returns:** `bool`. [[hall_main#is_one_death_from_falling]] returns it.

**Side effects:** none.

**Called by:** [[hall_main#is_one_death_from_falling]] (`hall_main.gd:555`). [[hall_header#_refresh_danger_strip]] (`hall_header.gd:198`) calls `hall.is_one_death_from_falling()` on the hall, which is the `hall_main` wrapper above, not this function directly.

**Calls:** [[character_container#living_count]], [[hall_ledger#can_afford_a_recruit_today]], [[hall_ledger#is_short_of_recruit_gold]], [[hall_ledger#is_standing_near_floor]].

### last_living_hero
`static func last_living_hero(roster: Array) -> GuildCharacter` · `Scripts/Hall/Rules/hall_ledger.gd:44`

The one living member of `roster`, or null if there isn't exactly one.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `roster` | `Array` | Array of `GuildCharacter` | `roster()` (the active roster) in [[hall_main#last_living_hero]] |

**Returns:** `GuildCharacter` or null. [[hall_main#last_living_hero]] returns it; [[hall_header#_refresh_danger_strip]] (`hall_header.gd:196`) reads it through `hall.last_living_hero()` to name the hero in the strip.

**Side effects:** none.

**Called by:** [[hall_main#last_living_hero]] (`hall_main.gd:560`).

**Calls:** [[hall_style#is_dead]].

### can_afford_a_recruit_today
`static func can_afford_a_recruit_today() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:50`

Someone in today's For Hire (`CharacterContainer.hireable_characters`) costs no more than `GameState.gold`.

**Parameters:** none.

**Returns:** `bool`, used by the two run checks in this file.

**Side effects:** none.

**Called by:** [[hall_ledger#is_run_over]] (`hall_ledger.gd:24`), [[hall_ledger#is_one_death_from_falling]] (`hall_ledger.gd:37`).

**Calls:** none.

### is_short_of_recruit_gold
`static func is_short_of_recruit_gold() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:58`

Tomorrow's recruit price ([[character_resource#recruit_cost_for_day]] of `GameState.day + 1`) is more than the gold in hand (prices never drop).

**Parameters:** none.

**Returns:** `bool`. The run checks in this file use it; [[hall_header#_refresh_danger_strip]] uses it to pick the strip's wording, and [[popup_gold#refresh]] to show its warning.

**Side effects:** none.

**Called by:** [[hall_ledger#is_run_over]] (`hall_ledger.gd:28`), [[hall_ledger#is_one_death_from_falling]] (`hall_ledger.gd:39`), [[hall_header#_refresh_danger_strip]] (`hall_header.gd:207`), [[popup_gold#refresh]] (`popup_gold.gd:86`, sets `_warning.visible`).

**Calls:** [[character_resource#recruit_cost_for_day]].

### is_standing_near_floor
`static func is_standing_near_floor() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:63`

Standing is within `DANGER_STANDING_MARGIN` of the floor where recruits stop showing up.

**Parameters:** none.

**Returns:** `bool`. [[popup_standing#refresh]] sets `_warning.visible` with it (`popup_standing.gd:83`).

**Side effects:** none.

**Called by:** [[hall_ledger#is_one_death_from_falling]] (`hall_ledger.gd:39`), [[popup_standing#refresh]] (`popup_standing.gd:83`).

**Calls:** none.

### build_run_over_stats
`static func build_run_over_stats(run_stats: Dictionary, roster: Array) -> Dictionary` · `Scripts/Hall/Rules/hall_ledger.gd:77`

Everything the Game Over ledger shows, read from the tallies and the roster.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `run_stats` | `Dictionary` | `hall_main`'s tallies (reads `released`, `gold_earned`, `quests_sent`, `quests_won`, `heroes_hired`, `drake_result`) | `run_stats` on [[hall_main]] |
| `roster` | `Array` | `CharacterContainer.active_characters` | `roster()` in [[hall_main]] |

**Returns:** `Dictionary` with `days`, `gold_earned`, `quests_sent`, `quests_won`, `heroes_hired`, `fallen` (int), `standing` (int), `drake_result` (String), `roll_call` (Array of `GuildCharacter`: the fallen first by earliest death, then the released, then anyone else) and `released` (to tell the released apart in the roll call). [[hall_main#build_run_over_stats]] hands it to the Game Over screen; [[hall_ledger#build_credits]] embeds it as `stats`.

**Side effects:** none.

**Called by:** [[hall_main#build_run_over_stats]] (`hall_main.gd:565`), [[hall_ledger#build_credits]] (`hall_ledger.gd:157`).

**Calls:** [[hall_style#is_dead]].

### build_run_records
`static func build_run_records(run_stats: Dictionary, roster: Array) -> Dictionary` · `Scripts/Hall/Rules/hall_ledger.gd:115`

The run's extra records for the final battle's credits roll. A hero's service runs from `joined_on_day` to `died_on_day` (if dead and recorded), else today. Released heroes who are still alive aren't counted (their leaving day isn't kept).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `run_stats` | `Dictionary` | Tallies (reads `gold_spent`, `items_found`, `released`) | `run_stats` on [[hall_main]] |
| `roster` | `Array` | `CharacterContainer.active_characters` | `roster()` in [[hall_main]] |

**Returns:** `Dictionary` with `gold_spent`, `items_found` (int), `buildings` (Array of `{name, level}`, implemented buildings only, in [[hall_style#buildings_in_order]] order), `longest_serving` (`GuildCharacter`, null if nobody) and `longest_days` (int). [[hall_main#build_run_records]] returns it; [[hall_ledger#build_credits]] embeds it as `records`.

**Side effects:** none.

**Called by:** [[hall_main#build_run_records]] (`hall_main.gd:570`), [[hall_ledger#build_credits]] (`hall_ledger.gd:158`).

**Calls:** [[hall_style#buildings_in_order]], [[guild_upgrades#is_implemented]], [[guild_upgrades#get_building_name]], [[guild_upgrades#get_level]], [[hall_style#is_dead]].

### build_credits
`static func build_credits(result: Dictionary, run_stats: Dictionary, roster: Array) -> Dictionary` · `Scripts/Hall/Rules/hall_ledger.gd:152`

Everything the final battle's credits roll shows ([[overlay_credits]]).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result` | `Dictionary` | The final quest's [[hall_rules#play_quest]] result | the result passed to [[hall_main#_show_final_credits]] (from [[hall_main#_run_quest]]) via `build_credits(result)` (`hall_main.gd:1565`) |
| `run_stats` | `Dictionary` | Tallies | `run_stats` on [[hall_main]] |
| `roster` | `Array` | `CharacterContainer.active_characters` | `roster()` in [[hall_main]] |

**Returns:** `Dictionary` `{won: bool (victory roll with Begin Freeplay, or the defeat screen), day: int, result, stats: build_run_over_stats(), records: build_run_records()}`. [[hall_main#build_credits]] returns it to the credits overlay.

**Side effects:** none.

**Called by:** [[hall_main#build_credits]] (`hall_main.gd:576`).

**Calls:** [[hall_ledger#build_run_over_stats]], [[hall_ledger#build_run_records]].

## Suspected issues
- `hall_ledger.gd:23` and `:36`: the doc comments say "Never true on the free-recruit days". The code has no day check. It relies on `can_afford_a_recruit_today()` being true when recruits cost 0 (recruit price is 0 on days 1-2, so any hire is affordable). Accurate only while a recruit is in the For Hire pool.
