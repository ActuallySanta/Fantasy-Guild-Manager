---
source: Scripts/Hall/Rules/hall_ledger.gd
class_name: HallLedger
extends: null
scene: null
systems: ["[[Hiring Characters]]", "[[Quest Resolution and Injuries]]", "[[Economy and Wallet]]", "[[Run End]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# hall_ledger.gd

## Purpose
How the run stands (is it over, is it one death from over) and the numbers the Game Over ledger and the final battle's credits show. No state and no nodes. Every function is static and takes the roster and [[hall_main]]'s `run_stats` as parameters (or reads autoloads). The run's state stays on `HallMain`, so a new run (which reloads the hall scene) starts from zero. [[hall_main]] wraps most of these in one-line query functions so views only talk to `hall`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TROUBLE_FAILURES` | const | Quests lost over the last `TROUBLE_WINDOW_DAYS` reported days that count as trouble (value 2). |
| `TROUBLE_WINDOW_DAYS` | const | How many days back, not counting today (which isn't played yet), failures are summed (value 2). |
| `TROUBLE_INJURED_SHARE` | const | Share (0-1) of the living roster that is Hurt or worse that counts as trouble (value 0.5). |
| `DANGER_STANDING_MARGIN` | const | 3 standing points. Standing within this many points of `GuildUpgrades.MINIMUM_STANDING` counts as "nearly too low for recruits" for the header's "last hero standing" strip. |

## Functions

### is_run_over
`static func is_run_over() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:23`

True when the guild can never send anyone out again: nobody is alive (patients in the Hospital count as alive), nobody in today's For Hire is affordable, and no recruit ever will be (standing at or under the floor, or tomorrow's price is already more than the gold left, and prices never go down). Never true on the free-recruit days.

**Parameters:** none (reads `CharacterContainer`, `GameState`, `GuildUpgrades`).

**Returns:** `bool`. [[hall_main#is_run_over]] returns it (or'd with `final_battle_lost`), and the hall uses that to show Game Over.

**Side effects:** none.

**Called by:** [[hall_main#is_run_over]] (`hall_main.gd:552`).

**Calls:** [[character_container#living_count]], [[hall_ledger#can_afford_a_recruit_today]], [[hall_ledger#is_short_of_recruit_gold]].

### is_one_death_from_falling
`static func is_one_death_from_falling() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:36`

True when exactly one hero is left alive and losing them would (or nearly would) end the run: nobody in today's For Hire is affordable, and either tomorrow's recruit price is more than the gold left, or standing is within `DANGER_STANDING_MARGIN` of the floor. Drives the header's warning strip. Never true on the free-recruit days.

**Parameters:** none.

**Returns:** `bool`. [[hall_main#is_one_death_from_falling]] returns it.

**Side effects:** none.

**Called by:** [[hall_main#is_one_death_from_falling]] (`hall_main.gd:558`). [[hall_header#_refresh_danger_strip]] (`hall_header.gd:202`) calls `hall.is_one_death_from_falling()` on the hall, which is the `hall_main` wrapper above, not this function directly.

**Calls:** [[character_container#living_count]], [[hall_ledger#can_afford_a_recruit_today]], [[hall_ledger#is_short_of_recruit_gold]], [[hall_ledger#is_standing_near_floor]].

### last_living_hero
`static func last_living_hero(roster: Array) -> GuildCharacter` · `Scripts/Hall/Rules/hall_ledger.gd:44`

The one living member of `roster`, or null if there isn't exactly one.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `roster` | `Array` | Array of `GuildCharacter` | `roster()` (the active roster) in [[hall_main#last_living_hero]] |

**Returns:** `GuildCharacter` or null. [[hall_main#last_living_hero]] returns it; [[hall_header#_refresh_danger_strip]] (`hall_header.gd:200`) reads it through `hall.last_living_hero()` to name the hero in the strip.

**Side effects:** none.

**Called by:** [[hall_main#last_living_hero]] (`hall_main.gd:574`).

**Calls:** [[hall_style#is_dead]].

### trouble_reason
`static func trouble_reason(run_stats: Dictionary, roster: Array, day: int) -> String` · `Scripts/Hall/Rules/hall_ledger.gd:62`

Why the guild is "in trouble" (a milder warning than the last-hero strip): `"failures"` when `recent_failures(run_stats, day) >= TROUBLE_FAILURES`, `"injuries"` when half or more of the living heroes (`injury_level >= LIGHTLY_INJURED`) are hurt, or `""` when neither. Failures are checked first. Dead and null heroes are skipped.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `run_stats` | `Dictionary` | The run's counters; `failed_by_day` may be missing in old saves | `run_stats` in [[hall_main#trouble_reason]] |
| `roster` | `Array` | The guild's `GuildCharacter`s | `roster()` in [[hall_main#trouble_reason]] |
| `day` | `int` | Today's day number | `GameState.day` in [[hall_main#trouble_reason]] |

**Returns:** `String` `"failures"`, `"injuries"` or `""`. [[hall_main#trouble_reason]] returns it; [[hall_header#_refresh_danger_strip]] shows the gold "Guild in trouble" strip for a non-empty value when the red strip isn't showing.

**Side effects:** none.

**Called by:** [[hall_main#trouble_reason]] (`hall_main.gd:564`).

**Calls:** [[hall_ledger#recent_failures]], [[hall_style#is_dead]].

### recent_failures
`static func recent_failures(run_stats: Dictionary, day: int) -> int` · `Scripts/Hall/Rules/hall_ledger.gd:79`

Quests lost in the trouble window: the sum of `run_stats.failed_by_day[day - n]` for `n = 1..TROUBLE_WINDOW_DAYS`. Missing days and a missing `failed_by_day` count as 0.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `run_stats` | `Dictionary` | The run's counters | `run_stats` in [[hall_main#recent_failures]] |
| `day` | `int` | Today's day number | `GameState.day` |

**Returns:** `int`. [[hall_ledger#trouble_reason]] compares it with `TROUBLE_FAILURES`; [[hall_main#recent_failures]] passes it to [[hall_header#_refresh_danger_strip]] for the strip's text.

**Side effects:** none.

**Called by:** [[hall_ledger#trouble_reason]] (`:63`), [[hall_main#recent_failures]] (`hall_main.gd:569`).

**Calls:** none.

### can_afford_a_recruit_today
`static func can_afford_a_recruit_today() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:88`

Someone in today's For Hire (`CharacterContainer.hireable_characters`) costs no more than `GameState.gold`, using the roster-adjusted price from [[character_container#hire_price]].

**Parameters:** none.

**Returns:** `bool`, used by the two run checks in this file.

**Side effects:** none.

**Called by:** [[hall_ledger#is_run_over]] (`hall_ledger.gd:24`), [[hall_ledger#is_one_death_from_falling]] (`hall_ledger.gd:37`).

**Calls:** [[character_container#hire_price]].

### is_short_of_recruit_gold
`static func is_short_of_recruit_gold() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:96`

Tomorrow's recruit price ([[character_resource#recruit_cost_for_day]] of `GameState.day + 1`) is more than the gold in hand (prices never drop).

**Parameters:** none.

**Returns:** `bool`. The run checks in this file use it; [[hall_header#_refresh_danger_strip]] uses it to pick the strip's wording, and [[popup_gold#refresh]] to show its warning.

**Side effects:** none.

**Called by:** [[hall_ledger#is_run_over]] (`hall_ledger.gd:28`), [[hall_ledger#is_one_death_from_falling]] (`hall_ledger.gd:39`), [[hall_header#_refresh_danger_strip]] (`hall_header.gd:223`), [[popup_gold#refresh]] (`popup_gold.gd:86`, sets `_warning.visible`).

**Calls:** [[character_resource#recruit_cost_for_day]].

### is_standing_near_floor
`static func is_standing_near_floor() -> bool` · `Scripts/Hall/Rules/hall_ledger.gd:101`

Standing is within `DANGER_STANDING_MARGIN` of the floor where recruits stop showing up.

**Parameters:** none.

**Returns:** `bool`. [[popup_standing#refresh]] sets `_warning.visible` with it (`popup_standing.gd:83`).

**Side effects:** none.

**Called by:** [[hall_ledger#is_one_death_from_falling]] (`hall_ledger.gd:39`), [[popup_standing#refresh]] (`popup_standing.gd:83`).

**Calls:** none.

### build_run_over_stats
`static func build_run_over_stats(run_stats: Dictionary, roster: Array) -> Dictionary` · `Scripts/Hall/Rules/hall_ledger.gd:115`

Everything the Game Over ledger shows, read from the tallies and the roster.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `run_stats` | `Dictionary` | `hall_main`'s tallies (reads `released`, `gold_earned`, `quests_sent`, `quests_won`, `heroes_hired`, `drake_result`) | `run_stats` on [[hall_main]] |
| `roster` | `Array` | `CharacterContainer.active_characters` | `roster()` in [[hall_main]] |

**Returns:** `Dictionary` with `days`, `gold_earned`, `quests_sent`, `quests_won`, `heroes_hired`, `fallen` (int), `standing` (int), `drake_result` (String), `roll_call` (Array of `GuildCharacter`: the fallen first by earliest death, then the released, then anyone else) and `released` (to tell the released apart in the roll call). [[hall_main#build_run_over_stats]] hands it to the Game Over screen; [[hall_ledger#build_credits]] embeds it as `stats`.

**Side effects:** none.

**Called by:** [[hall_main#build_run_over_stats]] (`hall_main.gd:579`), [[hall_ledger#build_credits]] (`hall_ledger.gd:195`).

**Calls:** [[hall_style#is_dead]].

### build_run_records
`static func build_run_records(run_stats: Dictionary, roster: Array) -> Dictionary` · `Scripts/Hall/Rules/hall_ledger.gd:153`

The run's extra records for the final battle's credits roll. A hero's service runs from `joined_on_day` to `died_on_day` (if dead and recorded), else today. Released heroes who are still alive aren't counted (their leaving day isn't kept).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `run_stats` | `Dictionary` | Tallies (reads `gold_spent`, `items_found`, `released`) | `run_stats` on [[hall_main]] |
| `roster` | `Array` | `CharacterContainer.active_characters` | `roster()` in [[hall_main]] |

**Returns:** `Dictionary` with `gold_spent`, `items_found` (int), `buildings` (Array of `{name, level}`, implemented buildings only, in [[hall_style#buildings_in_order]] order), `longest_serving` (`GuildCharacter`, null if nobody) and `longest_days` (int). [[hall_main#build_run_records]] returns it; [[hall_ledger#build_credits]] embeds it as `records`.

**Side effects:** none.

**Called by:** [[hall_main#build_run_records]] (`hall_main.gd:584`), [[hall_ledger#build_credits]] (`hall_ledger.gd:196`).

**Calls:** [[hall_style#buildings_in_order]], [[guild_upgrades#is_implemented]], [[guild_upgrades#get_building_name]], [[guild_upgrades#get_level]], [[hall_style#is_dead]].

### build_credits
`static func build_credits(result: Dictionary, run_stats: Dictionary, roster: Array) -> Dictionary` · `Scripts/Hall/Rules/hall_ledger.gd:190`

Everything the final battle's credits roll shows ([[overlay_credits]]).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result` | `Dictionary` | The final quest's [[hall_rules#play_quest]] result | the result passed to [[hall_main#_show_final_credits]] (from [[hall_main#_run_quest]]) via `build_credits(result)` (`hall_main.gd:1585`) |
| `run_stats` | `Dictionary` | Tallies | `run_stats` on [[hall_main]] |
| `roster` | `Array` | `CharacterContainer.active_characters` | `roster()` in [[hall_main]] |

**Returns:** `Dictionary` `{won: bool (victory roll with Begin Freeplay, or the defeat screen), day: int, result, stats: build_run_over_stats(), records: build_run_records()}`. [[hall_main#build_credits]] returns it to the credits overlay.

**Side effects:** none.

**Called by:** [[hall_main#build_credits]] (`hall_main.gd:590`).

**Calls:** [[hall_ledger#build_run_over_stats]], [[hall_ledger#build_run_records]].

## Suspected issues
- `hall_ledger.gd:23` and `:36`: the doc comments say "Never true on the free-recruit days". The code has no day check. It relies on `can_afford_a_recruit_today()` being true when recruits cost 0 (recruit price is 0 on days 1-2, so any hire is affordable). Accurate only while a recruit is in the For Hire pool.
