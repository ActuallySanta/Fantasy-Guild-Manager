---
source: Scripts/Quest Creator/quest_injuries.gd
class_name: QuestInjuries
extends: RefCounted
scene: null
systems: ["[[Quest Resolution and Injuries]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# quest_injuries.gd

## Purpose
Static rules for how often fights hurt heroes (design: `Docs/hall_design.md`, "Injuries"). The wear per hero depends only on the quest's odds, not on its rank or party size, so a solo hero is no likelier to be hurt than each member of a party. The only caller is [[quest_resource#_combatEncounter]]. No scene.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `INJURIES_BY_ODDS` | const | Fight injuries per hero per quest by success odds. Rows `[odds percent, injuries per hero]`: `[130, 0.1], [100, 0.2], [90, 0.35], [80, 0.5], [70, 0.7], [60, 0.9], [50, 1.2]`. Highest odds first; interpolated linearly between rows and clamped past either end. |
| `EXPECTED_COMBATS_BY_RANK` | const | Combat encounters a quest of each rank runs on average, measured from [[quest_resource#generateResults]]'s loops (counting "ATTACKED" lines over 4,000 quests per rank): `{-1: 1.0, 0: 2.56, 1: 4.02, 2: 4.25, 3: 6.24, 4: 8.25, 5: 10.23, 6: 12.32}`. Keys are `QuestDifficulty` values. The comment says to re-measure if the loops change. |

## Functions

### target_injuries_per_hero
`static func target_injuries_per_hero(odds: float) -> float` · `Scripts/Quest Creator/quest_injuries.gd:26`

Target fight injuries per hero for a quest at these odds, interpolated from `INJURIES_BY_ODDS`: 0.1 at 130 or more, up to 1.2 at 50 or less.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `odds` | `float` | Success chance in percent (can be above 100) | `odds` of [[quest_injuries#injury_chance_per_encounter]] |

**Returns:** `float` injuries per hero per quest. Used by [[quest_injuries#injury_chance_per_encounter]].

**Side effects:** none.

**Called by:** [[quest_injuries#injury_chance_per_encounter]] (`quest_injuries.gd:51`).

**Calls:** none.

### injury_chance_per_encounter
`static func injury_chance_per_encounter(odds: float, rank: int, party_size: int) -> float` · `Scripts/Quest Creator/quest_injuries.gd:48`

Chance that one combat encounter injures a hero, so the quest's total fight injuries average the odds' target per hero: `clamp(target * max(party_size, 1) / expected_combats, 0, 1)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `odds` | `float` | Success chance in percent | `_successChance` of [[quest_resource#_combatEncounter]] |
| `rank` | `int` | `QuestDifficulty` value, clamped to -1..6 | `difficulty` of the quest |
| `party_size` | `int` | Heroes on the quest (at least 1) | `_questingAdventurers.size()` |

**Returns:** `float` 0.0 to 1.0. [[quest_resource#_combatEncounter]] compares it to `randf()` to decide whether a hero is hurt in the fight.

**Side effects:** none.

**Called by:** [[quest_resource#_combatEncounter]] (`quest_resource.gd:585`).

**Calls:** [[quest_injuries#target_injuries_per_hero]].

## Suspected issues
None found.
