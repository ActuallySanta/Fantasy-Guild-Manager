---
source: Scripts/Hall/Rules/hire_scaling.gd
class_name: HireScaling
extends: null
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hire_scaling.gd

## Purpose
How strong (and how pricey) today's recruits are. Each morning's For Hire pool rolls its stats from a budget that keeps up with the guild: the higher of a floor set by standing rank and a share of the roster's average power. Now and then one applicant is a standout with a bigger budget. Recruits who beat the standing floor cost extra on top of the day's price. Static rules only. The only caller is [[character_container#_add_new_recruits]]. No scene.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `BASE_POINTS` | const | 17. Stat points a recruit gets at standing rank F (0). Matches the old flat `GuildCharacter.total_points`. |
| `POINTS_PER_RANK` | const | 4. Extra stat points per standing rank ([[hall_rules#standing_rank_for]]). |
| `POWER_FRACTION` | const | 0.85. Share (0-1) of the roster's average base stat total a recruit is budgeted. |
| `STANDOUT_CHANCE` | const | 0.35. Chance (0-1) each morning that one applicant is a standout. Read in [[character_container#_add_new_recruits]]. |
| `STANDOUT_BONUS` | const | 1.25. A standout's budget is multiplied by this. |
| `PRICE_PER_POINT` | const | 10 gold per stat point above the standing floor. Only on days that already have a price (days 1-2 stay free). |
| `DEVIATION_PER_POINT` | const | `2.0 / 17.0`. Spread of a recruit's stats per budget point: 2 at the old 17 points. |

## Functions

### guild_power
`static func guild_power(roster: Array) -> float` · `Scripts/Hall/Rules/hire_scaling.gd:40`

The guild's average power: the mean base stat total of living heroes. Doesn't count the Armory bonus (subtracted per stat with [[guild_upgrades#get_stat_bonus]]), gear or Pluck.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `roster` | `Array` | The heroes to average | `active_characters`, passed on by [[hire_scaling#recruit_budget]] |

**Returns:** `float`, 0.0 when nobody is alive (null or DEAD heroes are skipped). Used by [[hire_scaling#recruit_budget]].

**Side effects:** none.

**Called by:** [[hire_scaling#recruit_budget]] (`hire_scaling.gd:66`).

**Calls:** [[guild_upgrades#get_stat_bonus]].

### standing_floor
`static func standing_floor(standing: int) -> int` · `Scripts/Hall/Rules/hire_scaling.gd:56`

The least stat points a recruit gets at this standing: `BASE_POINTS + POINTS_PER_RANK * rank`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `standing` | `int` | The guild's standing | `GameState.standing`, passed through |

**Returns:** `int` points. [[hire_scaling#recruit_budget]] uses it as the lower bound; [[hire_scaling#recruit_cost]] as the free point allowance.

**Side effects:** none.

**Called by:** [[hire_scaling#recruit_budget]] (`hire_scaling.gd:66`), [[hire_scaling#recruit_cost]] (`hire_scaling.gd:92`).

**Calls:** [[hall_rules#standing_rank_for]].

### recruit_budget
`static func recruit_budget(day: int, standing: int, roster: Array) -> int` · `Scripts/Hall/Rules/hire_scaling.gd:65`

Stat points for an ordinary recruit today: `max(standing_floor, guild_power * POWER_FRACTION)`, times [[hall_rules#freeplay_scale]] (1.0 until freeplay), rounded.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | Current day | `GameState.day` in [[character_container#_add_new_recruits]] |
| `standing` | `int` | Guild standing | `GameState.standing` in the same function |
| `roster` | `Array` | Current roster | `active_characters` of [[character_container]] |

**Returns:** `int` budget. [[character_container#_add_new_recruits]] keeps it and feeds it to the other functions here (standout budget, deviation, cost).

**Side effects:** none.

**Called by:** [[character_container#_add_new_recruits]] (`character_container.gd:62`).

**Calls:** [[hire_scaling#standing_floor]], [[hire_scaling#guild_power]], [[hall_rules#freeplay_scale]].

### standout_budget
`static func standout_budget(budget: int) -> int` · `Scripts/Hall/Rules/hire_scaling.gd:71`

A standout's stat points: `roundi(budget * STANDOUT_BONUS)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `budget` | `int` | An ordinary recruit's budget | result of [[hire_scaling#recruit_budget]] |

**Returns:** `int` points, the roll budget for the chosen standout in [[character_container#_add_new_recruits]].

**Side effects:** none.

**Called by:** [[character_container#_add_new_recruits]] (`character_container.gd:68`).

**Calls:** none.

### deviation_for
`static func deviation_for(points: int) -> int` · `Scripts/Hall/Rules/hire_scaling.gd:77`

How spread out a recruit's stats are for this budget (`GuildCharacter.stat_deviation`): `max(2, roundi(points * DEVIATION_PER_POINT))`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `points` | `int` | The recruit's budget | `points` in [[character_container#_add_new_recruits]] |

**Returns:** `int`, passed as the second argument of [[character_resource#reroll_stats]].

**Side effects:** none.

**Called by:** [[character_container#_add_new_recruits]] (`character_container.gd:70`).

**Calls:** none.

### recruit_cost
`static func recruit_cost(day: int, standing: int, points: int) -> int` · `Scripts/Hall/Rules/hire_scaling.gd:88`

The day's price ([[character_resource#recruit_cost_for_day]]) plus `PRICE_PER_POINT` for each point over the standing floor. Free days stay free (returns 0). The day's price is still the cheapest a recruit can be, so the Game Over check ([[hall_ledger#is_short_of_recruit_gold]]) can keep using `recruit_cost_for_day` alone.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | Current day | `GameState.day` |
| `standing` | `int` | Guild standing | `GameState.standing` |
| `points` | `int` | The recruit's stat budget | `points` in [[character_container#_add_new_recruits]] |

**Returns:** `int` gold, assigned to `recruit.cost` in [[character_container#_add_new_recruits]].

**Side effects:** none.

**Called by:** [[character_container#_add_new_recruits]] (`character_container.gd:71`).

**Calls:** [[character_resource#recruit_cost_for_day]], [[hire_scaling#standing_floor]].

## Suspected issues
None found.
