---
source: Scripts/Hall/Rules/hall_rules.gd
class_name: HallRules
extends: null
scene: null
systems: ["[[Day Cycle]]", "[[Party Drafting and Assignment]]", "[[Success Chance]]", "[[Quest Generation and Difficulty]]", "[[Quest Resolution and Injuries]]", "[[Economy and Wallet]]", "[[Run End]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# hall_rules.gd

## Purpose
The hall's rules for building the day's quests and playing one out. No state and no nodes: every function is static and takes what it needs, so the rules can be read (and tested) apart from the UI. [[hall_main]] owns the quest entries and the run's tallies and calls in here. Also holds the difficulty tuning (quest counts, standing ranks, boss days, the difficulty staircase, freeplay scaling), the Pluck/training rules and the starting hero.

A quest entry (see [[hall_rules#new_entry]]) is the Dictionary `{quest, state, party, milestone, final}` that `hall_main.quest_entries` holds.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `QUESTS_PER_DAY_BY_DAY` | const | Rows `{max_day, count}`: the first row whose `max_day` the day is at or under gives the board size (days 1-2: 1, to 6: 2, to 9: 3, day 10: 4). |
| `QUESTS_PER_DAY_LATE` | const | 5. Board size for days past the last row. |
| `STANDING_PER_RANK` | const | 10 standing per quest rank (see [[hall_rules#standing_rank_for]]). |
| `TOP_STANDING_RANK` | const | 5 (S). The highest rank standing alone can center quests on. |
| `STARTER_STANDING` | const | 5. At or under this standing every quest is rank 0. Also used by [[hall_wallet#standing_milestones]]. |
| `PLUCK_GAIN_BY_ODDS` | const | Rows `{min, gain}` (80:1, 60:2, 40:3, 0:4). Pluck gained per party member for a win below the training threshold. Matches `HallStyle.ODDS_BANDS`. |
| `TRAIN_ODDS_BASE` | const | 60 percent. Good-odds threshold on an F quest. |
| `TRAIN_ODDS_PER_RANK` | const | 5 percent added per quest rank (F 60 .. S 85). |
| `TRAIN_ODDS_TOP_RANK` | const | `QuestDifficulty.S`. Rank where the threshold stops rising. |
| `TRAIN_STAT_GAIN` | const | 1. Stat points each party member gains on a good-odds win. |
| `FREEPLAY_SCALE_PER_DAY` | const | 0.02. Each day past `HallMain.FINAL_DAY` adds this share to new quests' requirements and gold. No cap. |
| `BOSS_DAYS` | const | `[10, 20, 30, 40, 50]`. Boss days (the last is `FINAL_DAY`). |
| `BOSS_TWO_DAYS` | const | `[20, 40]`. Boss days with two bosses (the second uses the negative day number). |
| `DIFFICULTY_START_DAY` | const | 5. First day the staircase climbs. |
| `DIFFICULTY_DRIFT_PER_DAY` | const | 0.015. Requirement growth per day from the start day. |
| `DIFFICULTY_STEP_PER_BOSS` | const | 0.15. Requirement growth per boss already passed. |
| `BOSS_SPIKE` | const | 1.35. Extra multiplier on a boss quest. |
| `FINAL_BOSS_SPIKE` | const | 1.15. Extra multiplier on the final battle (used instead of `BOSS_SPIKE`). |
| `STARTING_HERO_NAME`, `STARTING_HERO_ROLE`, `STARTING_HERO_GENDER`, `STARTING_HERO_STATS` | const | "Uncle John", a male Priest with STRENGTH 4, DEFENSE 4, WISDOM 8, SLEAZINESS 4 (17 points spread evenly plus the Priest's +3 Wisdom). |

## Functions

### make_starting_hero
`static func make_starting_hero() -> GuildCharacter` · `Scripts/Hall/Rules/hall_rules.gd:95`

A new Uncle John: a Priest with average stats, free (`cost` 0), `joined_on_day` 1. The description is regenerated after the name is set, because the backstory is written for the role and may use the name.

**Parameters:** none.

**Returns:** `GuildCharacter`. [[hall_main#_add_starting_hero]] adds it to the guild.

**Side effects:** none (creates an object).

**Called by:** [[hall_main#_add_starting_hero]] (`hall_main.gd:493`).

**Calls:** [[external_content_container#get_character_icon]], [[character_resource#generate_description]].

### new_entry
`static func new_entry(quest: CreatedQuest, is_milestone: bool) -> Dictionary` · `Scripts/Hall/Rules/hall_rules.gd:116`

A new quest entry: `{quest, state: HallStyle.QUEST_STATE_OPEN, party: [], milestone: bool, final: false}`. `final` is set later by [[hall_rules#_build_boss_entries]].

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The generated quest | `CreatedQuest.new(...)` in [[hall_rules#build_day_quests]] / [[hall_rules#_build_boss_entries]] |
| `is_milestone` | `bool` | Whether it's a boss entry | `false` in `build_day_quests`, `true` in `_build_boss_entries` |

**Returns:** `Dictionary` appended to the day's entries.

**Side effects:** none.

**Called by:** [[hall_rules#build_day_quests]] (`hall_rules.gd:159`, `:162`, `:167`, `:170`, `:173`, `:177`), [[hall_rules#_build_boss_entries]] (`hall_rules.gd:195`).

**Calls:** none.

### build_day_quests
`static func build_day_quests(day: int, standing: int, is_freeplay: bool) -> Array` · `Scripts/Hall/Rules/hall_rules.gd:128`

Today's quest entries. A boss day returns only the boss entries (but in freeplay the final day's number is a normal day). Otherwise `quests_per_day(day)` quests are rolled. Each rank is `standing_rank_for(standing)` plus a bell-curve roll, clamped to 0..S (0..S++ in freeplay); a roll two ranks off is pulled one rank back, and at or under `STARTER_STANDING` every quest is rank 0.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | The day to build | `GameState.day` in [[hall_main#_generate_quests]] |
| `standing` | `int` | Guild standing | `GuildUpgrades.standing` in the same call |
| `is_freeplay` | `bool` | Past the final battle | `GameState.is_freeplay` in the same call |

**Returns:** `Array` of [[hall_rules#new_entry]] Dictionaries, in board order. [[hall_main#_generate_quests]] stores it in `quest_entries`.

**Side effects:** creates `CreatedQuest` objects (they read `GameState.day`, not the `day` parameter); uses `randf` through [[hall_rules#rand_bell_curve]].

**Called by:** [[hall_main#_generate_quests]] (`hall_main.gd:504`).

**Calls:** [[hall_rules#is_boss_day]], [[hall_rules#_build_boss_entries]], [[hall_rules#standing_rank_for]], [[hall_rules#quests_per_day]], [[hall_rules#rand_bell_curve]], [[hall_rules#_scale_normal_quest]], [[hall_rules#new_entry]], [[quest_resource#_init]].

> [!note] How it works
> The body also special-cases `GameState.day` (not `day`): on days 2, 4, 7, 9, 12, 15, 23, 26, 32, 34, 43 and 48 the first quest uses the day's written minor story and later quests that day are created with day 5 (`noRepeatQuests`), "to avoid cloning minor quests". On days 18, 28 and 45 it returns two quests, built with `GameState.day` and `-GameState.day`. On day 37 it returns three: `GameState.day`, `-GameState.day` and the special number `3737`. (The same day numbers are the ones `CreatedQuest._init` treats as milestone days; see [[quest_resource#_init]].)

### _build_boss_entries
`static func _build_boss_entries(day: int) -> Array` · `Scripts/Hall/Rules/hall_rules.gd:187`

The boss entries for a boss day: one quest, or two on `BOSS_TWO_DAYS` (the second built with the negative day number). All are milestone entries with `requirement_multiplier = requirement_scale(day, true, is_final)`. The `HallMain.FINAL_DAY` entry is marked `final` (it rolls the credits).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A `BOSS_DAYS` day (`GameState.day` should equal it, quests read it) | `day` of [[hall_rules#build_day_quests]] |

**Returns:** `Array` of [[hall_rules#new_entry]] Dictionaries. Returned from `build_day_quests`.

**Side effects:** none.

**Called by:** [[hall_rules#build_day_quests]] (`hall_rules.gd:132`).

**Calls:** [[hall_rules#new_entry]], [[hall_rules#requirement_scale]], [[quest_resource#_init]].

### _scale_normal_quest
`static func _scale_normal_quest(quest: CreatedQuest, day: int, is_freeplay: bool) -> void` · `Scripts/Hall/Rules/hall_rules.gd:203`

Sets the normal quest's `requirement_multiplier` to `requirement_scale(day, false, false)`, and, when `is_freeplay`, calls [[quest_resource#apply_freeplay_gold]] with `freeplay_scale(day)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest to scale | local in [[hall_rules#build_day_quests]] |
| `day` | `int` | Day for the scale | `day` of `build_day_quests` |
| `is_freeplay` | `bool` | Freeplay gold scaling on/off | `is_freeplay` of `build_day_quests` |

**Returns:** nothing.

**Side effects:** changes the quest's `requirement_multiplier` and, in freeplay, its gold.

**Called by:** [[hall_rules#build_day_quests]] (`hall_rules.gd:158`, `:161`, `:166`, `:169`, `:172`, `:176`).

**Calls:** [[hall_rules#requirement_scale]], [[hall_rules#freeplay_scale]], [[quest_resource#apply_freeplay_gold]].

### freeplay_scale
`static func freeplay_scale(day: int) -> float` · `Scripts/Hall/Rules/hall_rules.gd:211`

`1.0 + FREEPLAY_SCALE_PER_DAY * max(day - HallMain.FINAL_DAY, 0)`: 1.0 on or before the final day, then +2% per day.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day | `GameState.day` in [[hall_main#freeplay_scale]] (`hall_main.gd:509`); the `day` argument in the callers below |

**Returns:** `float` multiplier. [[hall_main#freeplay_scale]] returns it for display; the callers below multiply requirements, gold or recruit budgets by it.

**Side effects:** none.

**Called by:** [[hall_main#freeplay_scale]] (`hall_main.gd:509`), [[hall_rules#_scale_normal_quest]] (`hall_rules.gd:206`), [[hall_rules#requirement_scale]] (`hall_rules.gd:258`), [[hire_scaling#recruit_budget]] (`hire_scaling.gd:72`).

**Calls:** none.

### is_boss_day
`static func is_boss_day(day: int) -> bool` · `Scripts/Hall/Rules/hall_rules.gd:216`

Whether `day` is in `BOSS_DAYS`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day | `day` of [[hall_rules#build_day_quests]] |

**Returns:** `bool`, used to choose boss entries in [[hall_rules#build_day_quests]].

**Side effects:** none.

**Called by:** [[hall_rules#build_day_quests]] (`hall_rules.gd:131`).

**Calls:** none.

### bosses_before
`static func bosses_before(day: int) -> int` · `Scripts/Hall/Rules/hall_rules.gd:221`

How many `BOSS_DAYS` come strictly before `day`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day (already capped at `FINAL_DAY`) | `capped_day` in [[hall_rules#difficulty_scale]] |

**Returns:** `int`, the number of bosses passed; feeds the per-boss step.

**Side effects:** none.

**Called by:** [[hall_rules#difficulty_scale]] (`hall_rules.gd:246`).

**Calls:** none.

### next_boss_day
`static func next_boss_day(day: int) -> int` · `Scripts/Hall/Rules/hall_rules.gd:230`

The first boss day on or after `day`, or -1 when none is left.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day | `GameState.day` in all three callers |

**Returns:** `int` day or -1. [[hall_main#days_until_next_boss]] subtracts the current day from it (-1 passes through as "no boss left"), [[hall_main#next_boss_is_final]] compares it to `FINAL_DAY`, and the playtest bridge writes it as `next_boss_day`.

**Side effects:** none.

**Called by:** [[hall_main#days_until_next_boss]] (`hall_main.gd:731`), [[hall_main#next_boss_is_final]] (`hall_main.gd:737`), [[agent_bridge_state#build]] (`agent_bridge_state.gd:29`).

**Calls:** none.

### difficulty_scale
`static func difficulty_scale(day: int) -> float` · `Scripts/Hall/Rules/hall_rules.gd:240`

The staircase multiplier on quest requirements: 1.0 before `DIFFICULTY_START_DAY`, then `1 + DRIFT * (capped_day - (START - 1)) + STEP * bosses_before(capped_day)`, with the day capped at `HallMain.FINAL_DAY` (frozen from then on; [[hall_rules#freeplay_scale]] takes over).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day | `day` of [[hall_rules#requirement_scale]] |

**Returns:** `float`, multiplied into [[hall_rules#requirement_scale]].

**Side effects:** none.

**Called by:** [[hall_rules#requirement_scale]] (`hall_rules.gd:258`).

**Calls:** [[hall_rules#bosses_before]].

### requirement_scale
`static func requirement_scale(day: int, is_boss: bool, is_final: bool) -> float` · `Scripts/Hall/Rules/hall_rules.gd:252`

The full multiplier on a quest's stat requirement: `difficulty_scale * spike * freeplay_scale`, where spike is `FINAL_BOSS_SPIKE` for the final battle, `BOSS_SPIKE` for other bosses, else 1.0.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day | `day` of the builder |
| `is_boss` | `bool` | Boss quest | `true` in `_build_boss_entries`, `false` in `_scale_normal_quest` |
| `is_final` | `bool` | The final battle | `day == FINAL_DAY` in `_build_boss_entries`, `false` otherwise |

**Returns:** `float`, assigned to `quest.requirement_multiplier`.

**Side effects:** none.

**Called by:** [[hall_rules#_build_boss_entries]] (`hall_rules.gd:194`), [[hall_rules#_scale_normal_quest]] (`hall_rules.gd:204`).

**Calls:** [[hall_rules#difficulty_scale]], [[hall_rules#freeplay_scale]].

### quests_per_day
`static func quests_per_day(day: int) -> int` · `Scripts/Hall/Rules/hall_rules.gd:262`

How many quests the board gets on `day`, from `QUESTS_PER_DAY_BY_DAY` (else `QUESTS_PER_DAY_LATE`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day | `day` of [[hall_rules#build_day_quests]] |

**Returns:** `int`, the loop count in `build_day_quests`.

**Side effects:** none.

**Called by:** [[hall_rules#build_day_quests]] (`hall_rules.gd:140`).

**Calls:** none.

### standing_rank_for
`static func standing_rank_for(standing: int) -> int` · `Scripts/Hall/Rules/hall_rules.gd:271`

The quest rank (0 = F .. `TOP_STANDING_RANK`) a guild with this standing centers its quests on: `clampi(ceili(standing / STANDING_PER_RANK) - 1, 0, TOP_STANDING_RANK)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `standing` | `int` | A standing value | `standing` of `build_day_quests`; `GameState.standing` in [[standard_item#get_rarity]]; the argument of [[hall_wallet#standing_rank_letter]] / [[hire_scaling#standing_floor]] |

**Returns:** `int` rank. `build_day_quests` centers the roll on it, `get_rarity` uses it to pick Mythic/Legendary odds, [[hire_scaling#standing_floor]] to scale recruit points, [[hall_wallet#standing_rank_letter]] to name it.

**Side effects:** none.

**Called by:** [[hall_rules#build_day_quests]] (`hall_rules.gd:134`), [[guild_upgrades#nightly_fee]] (`guild_upgrades.gd:360`), [[hall_wallet#standing_rank_letter]] (`hall_wallet.gd:81`), [[hire_scaling#standing_floor]] (`hire_scaling.gd:62`), [[standard_item#get_rarity]] (`standard_item.gd:96`).

**Calls:** none.

### standing_for_win
`static func standing_for_win(quest: CreatedQuest) -> int` · `Scripts/Hall/Rules/hall_rules.gd:276`

Standing a won quest pays: `quest.difficulty + 1` (F = 1, E = 2, ...).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest | `entry.quest` in [[hall_rules#play_quest]]; `quest` in [[screen_assign#_show_quest_card]]; `entry.quest` in [[agent_bridge_state#_quests]] |

**Returns:** `int`. `play_quest` pays it; the Assign Party chip and the bridge show it as the reward.

**Side effects:** none.

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:377`), [[agent_bridge_state#_quests]] (`agent_bridge_state.gd:94`), [[screen_assign#_show_quest_card]] (`screen_assign.gd:227`).

**Calls:** none.

### standing_for_loss
`static func standing_for_loss(quest: CreatedQuest) -> int` · `Scripts/Hall/Rules/hall_rules.gd:282`

Standing a failed quest costs: `max(ceili((difficulty + 1) / 2.0), 1)`. Rank 0-1 costs 1, 2-3 costs 2, 4-5 costs 3, and the G rank (-1) costs 1.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest | `entry.quest` / `quest`, as for [[hall_rules#standing_for_win]] |

**Returns:** `int` (positive). [[hall_rules#play_quest]] negates it (capped by the room above the floor); the chip and bridge display it.

**Side effects:** none.

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:382`), [[agent_bridge_state#_quests]] (`agent_bridge_state.gd:95`), [[screen_assign#_show_quest_card]] (`screen_assign.gd:227`).

**Calls:** none.

### standing_for_deny
`static func standing_for_deny(quest: CreatedQuest) -> int` · `Scripts/Hall/Rules/hall_rules.gd:288`

Standing lost for denying a quest: `max(difficulty, 1)`, so even an F quest costs something.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `quest` | `CreatedQuest` | The quest being denied | `entry.quest` of the current entry in [[hall_main#deny_quest]] / [[screen_assign#_show_footer]] |

**Returns:** `int`. [[hall_main#deny_quest]] stores it as `standing_cost` to charge; [[screen_assign#_show_footer]] shows it on the Deny button.

**Side effects:** none.

**Called by:** [[hall_main#deny_quest]] (`hall_main.gd:1025`), [[screen_assign#_show_footer]] (`screen_assign.gd:436`).

**Calls:** none.

### can_deny
`static func can_deny(entry: Dictionary) -> bool` · `Scripts/Hall/Rules/hall_rules.gd:296`

False only for the final battle: denying it would let day 50 pass with no credits and no defeat, so the run would never end. Bosses and every other quest can be denied.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A [[hall_rules#new_entry]] Dictionary | `current_quest_entry()` in [[hall_main#deny_quest]]; the entry argument in [[hall_main#can_deny_quest]] |

**Returns:** `bool`. [[hall_main#deny_quest]] shows an error toast when false; [[hall_main#can_deny_quest]] returns it to the views.

**Side effects:** none.

**Called by:** [[hall_main#can_deny_quest]] (`hall_main.gd:597`), [[hall_main#deny_quest]] (`hall_main.gd:1020`).

**Calls:** none.

### rand_bell_curve
`static func rand_bell_curve(mean: float = 0.0, standard_deviation: float = 1.0) -> float` · `Scripts/Hall/Rules/hall_rules.gd:302`

A normally distributed random number (Box-Muller transform). A zero `u1` is nudged to 0.0001 to avoid `log(0)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `mean` | `float` | The center | default 0.0 (the caller passes nothing) |
| `standard_deviation` | `float` | The spread | default 1.0 |

**Returns:** `float` sample. [[hall_rules#build_day_quests]] truncates it with `int()` and adds it to the standing rank.

**Side effects:** advances the global RNG (`randf` twice).

**Called by:** [[hall_rules#build_day_quests]] (`hall_rules.gd:141`).

**Calls:** none.

### pluck_gain_for
`static func pluck_gain_for(chance: float) -> int` · `Scripts/Hall/Rules/hall_rules.gd:315`

Pluck each party member gains for winning a quest sent at `chance` percent, from `PLUCK_GAIN_BY_ODDS`. A party with no chance yet (-1) counts as a long shot (gain 4).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `chance` | `float` | Success chance, percent (-1 = no party yet) | `chance` computed in [[hall_rules#play_quest]]; the argument of [[hall_main#pluck_gain_for]], which [[screen_assign#_odds_caption]] calls as `hall.pluck_gain_for(chance)` |

**Returns:** `int` Pluck. `play_quest` adds it to each party member's `pluck`; the Assign Party caption shows it.

**Side effects:** none.

**Called by:** [[hall_main#pluck_gain_for]] (`hall_main.gd:654`), [[hall_rules#play_quest]] (`hall_rules.gd:410`).

**Calls:** none.

### train_odds_for
`static func train_odds_for(rank: int) -> int` · `Scripts/Hall/Rules/hall_rules.gd:325`

The good-odds threshold for a quest of `rank`: `TRAIN_ODDS_BASE + TRAIN_ODDS_PER_RANK * clampi(rank, 0, TRAIN_ODDS_TOP_RANK)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `rank` | `int` | A `CreatedQuest.QuestDifficulty` | `rank` of [[hall_rules#trains_stat]] |

**Returns:** `int` percent.

**Side effects:** none.

**Called by:** [[hall_rules#trains_stat]] (`hall_rules.gd:332`).

**Calls:** none.

### trains_stat
`static func trains_stat(chance: float, rank: int) -> bool` · `Scripts/Hall/Rules/hall_rules.gd:331`

Whether winning a quest of `rank` sent at `chance` percent trains a stat (true) or gives Pluck (false). A party with no chance yet (-1) never trains.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `chance` | `float` | Success chance, percent | `chance` in [[hall_rules#play_quest]]; argument of [[hall_main#trains_stat]] |
| `rank` | `int` | Quest difficulty | `entry.quest.difficulty` |

**Returns:** `bool`. `play_quest` branches on it; [[screen_assign#_odds_caption]] reaches it through `hall.trains_stat(entry, chance)` to word the caption.

**Side effects:** none.

**Called by:** [[hall_main#trains_stat]] (`hall_main.gd:660`), [[hall_rules#play_quest]] (`hall_rules.gd:404`).

**Calls:** [[hall_rules#train_odds_for]].

### play_quest
`static func play_quest(entry: Dictionary, day: int) -> Dictionary` · `Scripts/Hall/Rules/hall_rules.gd:352`

Plays out one quest with [[quest_scoring]] and pays its gold and standing into `GameState`. On a win the party trains a stat (good odds, see [[hall_rules#trains_stat]]) or gains Pluck (riskier odds). Found equipment goes into the pack, and the fallen remember where they fell. The run's tallies are left to the caller ([[hall_main#_run_quest]]).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | A quest entry with its party filled in | the entry [[hall_main#end_day]] hands to [[hall_main#_run_quest]] |
| `day` | `int` | The day, used for `died_on_day` | `GameState.day` in `_run_quest` |

**Returns:** the Day Report result `{quest, party, story, succeeded, chance, gold, standing, pluck, trained_stat, stat_gain, injured, died, items, reward_items, milestone, final, story_quest}`.
- `standing` is negative on a loss.
- `pluck` is what each member gained (0 on a failure or a trained win).
- `trained_stat` is the `GuildCharacter.StatType` index trained, -1 if none; `stat_gain` is the gain in it.
- `injured` is the members whose injury level rose but who survived; `died` is those who died on it.
- `items` is the equipment found while searching (already added to the pack); `reward_items` is an item quest's reward (added only on a win).
- `story_quest` is `entry.get("story_quest", false)`; the doc comment doesn't list it.

[[hall_main#_run_quest]] adds the result to the run tallies and the Day Report.

**Side effects:** changes `GameState` gold and standing; appends items to `ItemContainer.owned_items` and emits `ItemShop.gear_changed`; raises `stats` or `pluck` on party members; sets `died_on_day` and `died_on_quest`; the quest generates its story and injuries.

**Called by:** [[hall_main#_run_quest]] (`hall_main.gd:1615`).

**Calls:** [[quest_scoring#get_success_chance]], [[quest_resource#generateResults]], [[quest_scoring#did_succeed]], [[quest_scoring#get_gold_earned]], [[hall_rules#standing_for_win]], [[hall_rules#standing_for_loss]], [[game_state#add_gold]], [[game_state#add_standing]], [[quest_resource#pays_in_items]], [[hall_rules#trains_stat]], [[quest_resource#roll_trained_stat]], [[hall_rules#pluck_gain_for]], [[hall_style#is_dead]].

> [!note] How it works
> A loss costs standing, but the loss is capped at the room above `GuildUpgrades.MINIMUM_STANDING`, because `GuildUpgrades.add_standing` doesn't clamp. The code has a marked placeholder where a final-battle story would go. For now the final battle plays out like any other quest, and a loss must still contain "NOT SUCCESSFUL".

## Suspected issues
- `hall_rules.gd:128` `build_day_quests` takes a `day` parameter, but `CreatedQuest.new(rank, GameState.day)` and the `match(GameState.day)` block (lines 143-156) read the global day instead. They agree in normal play but not if a caller passes another day.
- `hall_rules.gd:352` the `play_quest` doc comment lists the result keys without `story_quest`, which the code adds.
