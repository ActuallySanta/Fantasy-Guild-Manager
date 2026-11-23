---
source: Scripts/UI/Components/stat_strip.gd
class_name: ""
extends: HFlowContainer
scene: "[[stat_strip (scene)]]"
systems: ["[[Success Chance]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# stat_strip.gd

## Purpose
A row of stat chips ("Pow 6", "Def 6", ...) that wraps when it runs out of room, led by an optional health chip. The quest's favored stat gets a heavy outline so you can see who fits without reading numbers. It can also tag a hurt hero with an "At risk" chip. The scene has a Health chip, an AtRisk chip, then one chip per stat named `Stat0` to `Stat4` in `HallStyle.STATS` order. Scene: [[stat_strip (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TEXT_AT_RISK` | const | "At risk": tag beside the health chip of a hero who is Hurt or worse (a hit can kill them even on a won quest). |
| `_health_chip`, `_at_risk_chip` | onready | `%Health`, `%AtRisk` ([[chip]]). |

## Functions

### show_stats
`func show_stats(character: GuildCharacter, favored_indexes: Array[int] = [], include_pluck: bool = true, top_count: int = 0) -> void` · `Scripts/UI/Components/stat_strip.gd:27`

Shows the stat chips. Pluck isn't rolled against directly (it boosts the other stats), so it only shows when `include_pluck` is on. With `top_count > 0` only that many of the hero's strongest quest stats show, kept in `STATS` order.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | `character` in the callers |
| `favored_indexes` | `Array[int]` | Indexes into `HallStyle.STATS` to outline (empty = none) | `HallStyle.favored_stat_indexes(entry.quest)` in [[pick_row#setup]]; `[]` in [[member_card#setup]] |
| `include_pluck` | `bool` | Show the Pluck chip | `false` in both callers |
| `top_count` | `int` | How many stats to show (0 = all) | `SHOWN_STAT_COUNT` (2) in [[member_card#setup]]; 0 in [[pick_row#setup]] |

**Returns:** nothing.

**Called by:** [[member_card#setup]] (`member_card.gd:59`), [[pick_row#setup]] (`pick_row.gd:65`).

**Calls:** [[stat_strip#_top_stats]], [[chip#set_stat]].

### show_health
`func show_health(character: GuildCharacter, show_at_risk: bool = false) -> void` · `Scripts/UI/Components/stat_strip.gd:43`

Shows the health chip at the head of the strip (hidden until this is called). With `show_at_risk`, a living hero who is Lightly Injured or worse is also tagged "At risk".

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | callers |
| `show_at_risk` | `bool` | Also tag hurt heroes | `true` in [[pick_row#setup]]; default false in [[member_card#setup]] |

**Returns:** nothing.

**Called by:** [[member_card#setup]] (`member_card.gd:58`), [[pick_row#setup]] (`pick_row.gd:64`).

**Calls:** [[chip#set_health]], [[chip#set_chip]].

### _top_stats
`func _top_stats(character: GuildCharacter, count: int) -> Array` · `Scripts/UI/Components/stat_strip.gd:52`

The `count` strongest quest stats as `STATS` indexes (by `HallStyle.quest_stat_value`; Pluck is never one of them; ties go to the stat listed first).

**Parameters:** `character`, `count` (= `top_count`) from [[stat_strip#show_stats]].

**Returns:** `Array` of stat indexes, used by [[stat_strip#show_stats]] to decide which chips are visible.

**Called by:** [[stat_strip#show_stats]] (`stat_strip.gd:28`).

**Calls:** [[hall_style#quest_stat_value]].

## Suspected issues
- None found.
