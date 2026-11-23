---
source: Scripts/Quest Creator/quest_resource.gd
class_name: CreatedQuest
extends: Resource
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, resource]
---

# quest_resource.gd

## Purpose
`CreatedQuest`: generates one quest (standard, minor-story or boss/milestone), computes the party's success chance (`calcSuccessChance`), and plays the quest out (`generateResults`), returning BBCode story text while changing the quest's `goldReward`, the party's injuries and the quest's `found_items`. Success is not returned: [[quest_scoring#did_succeed]] looks for "NOT SUCCESSFUL" in the text. Scoring rules live in [[quest_scoring]], injury odds in [[quest_injuries]]. [[hall_rules]] creates and scales quests; [[hall_save]] saves the fields listed in its `QUEST_FIELDS` (`hall_save.gd:67`). This file keeps legacy camelCase names (`goldReward`, `questNum`, `generateResults`); they are referenced as they are.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `QuestDifficulty` | enum | `G=-1, F=0, D, C, B, A, S=5, SPP=6`. `SPP` is S++, freeplay only. |
| `QuestType` | enum | `MiscNoBonus=0, DungeonClear=1, Escort=2, ScoutTerrain=3, GatherIntel=4, EliminateMonsters=5, DefendLocation=6, SearchForResources=7, RepresentTheGuild=8`. Read from the story file's column 0. |
| `FavoredStat` | enum | `Power=0, Defense=1, Wisdom=2, Sleaze=3, Pluck=4`, and combos whose two digits are the components (10 Power+Defense, 20 Power+Wisdom, 30 Power+Sleaze, 12 Defense+Wisdom, 13 Defense+Sleaze, 23 Wisdom+Sleaze, 40 Power+Pluck). See [[quest_resource#favored_components]]. |
| `QuestStyle` | enum | `Normal=0, MinorStory=1, MajorMilestone=2`. Chooses which story file the text comes from. |
| `REGION_FAVORED_STAT` | const | `[1, 3, 0, 2]`: the `GuildCharacter.StatType` each region favors by `regionNum` (Meadows Defense, Boglands Sleaze, Wastes Power, Mountains Wisdom). `calcSuccessChance` counts it twice; a good-odds win can train it. |
| `PLUCK_COMPONENT` | const | 4. The favored-stat component meaning Pluck (not a `StatType`). |
| `numAdventurers`, `maxAdventurers` | var (int) | Party size at play time, and the party slots the quest takes. |
| `goldReward`, `startingGoldReward` | var (int) | Gold paid on a win, and what it began as. Search finds and corpse gold raise `goldReward`; the difference is what a loss still pays ([[quest_scoring#get_gold_earned]]). |
| `location`, `regionNum` | var | Location name and `Region` index (0-3 for normal quests). |
| `difficulty`, `type`, `favStat` | var | `QuestDifficulty`, `QuestType`, `FavoredStat`. |
| `questTitle`, `questSummary`, `questNum` | var | Title; plain-text summary built during play; row number in the story file. |
| `dead_adventurers` | var (`Array[GuildCharacter]`) | Heroes who died on this quest (saved). |
| `_will_fail` | var (bool) | Outcome rolled at the start of `generateResults`. Not saved. |
| `_starting_levels` | var (Dictionary) | Hero to injury level when `generateResults` began. |
| `requirement_multiplier` | var (float) | Scale on the stat total the quest asks for (1.0 = none). Set by [[hall_rules#_scale_normal_quest]] and [[hall_rules#_build_boss_entries]]. |
| `found_items` | var (`Array[StandardItem]`) | Equipment found while searching; paid by [[hall_rules#play_quest]] whether or not the quest wins. |
| `equipment_base_chance` | var (float) | 10. Percent chance a successful search finds equipment. |
| `equipment_risk_bonus` | var (float) | 25. Extra percent at 0% success chance, falling to 0 at 100%. |
| `equipment_shorthanded_bonus` | var (float) | 10. Extra percent per empty party slot. |
| `equipment_max_chance` | var (float) | 50. Cap on the find chance (percent). |
| `successfulChecks` | var (int) | Won fights and successful searches this run. A mid-quest check on rank C and above. |
| `styleOfQuest` | var | A `QuestStyle` value (declared as `var styleOfQuest = QuestStyle`, then assigned ints). |
| `reward_items` | var (`Array[StandardItem]`) | Equipment this quest pays instead of gold. Paid only on success. |
| `item_reward_base_chance` | var (float) | 5. Percent chance on day 1 that a standard quest pays in items. |
| `item_reward_chance_per_day` | var (float) | 1.5. Added percent per day after day 1. |
| `item_reward_max_chance` | var (float) | 30. Cap (percent). |
| `item_reward_count_per_rank` | var (float) | 0.5. Count is `1 + int(difficulty * this)`. |
| `trained_stat_quest_chance` | var (float) | 50. Percent that a good-odds win trains the quest's favored stat rather than the region's. |

## Functions

### _init
`func _init(diff := 0, dayNum := 0) -> void` · `Scripts/Quest Creator/quest_resource.gd:145`

Constructor. For `dayNum` in the scripted list (1, 2, 4, 7, 9, 10, 12, 15, 18, -18, 20, -20, 30, 40, -40, 50, 22, 24, 26, 28, 32, 33, 34, 36, 38, 39, 42, 45, 48) it calls [[quest_resource#_initMilestoneVars]] and returns. Otherwise it builds a random standard quest: `maxAdventurers` 1-2 (1-3 after day 5), a random region 0-3, a random story row 0-15, the type from that row, a location, the gold by party size and difficulty (1 slot `100 + 125*d`, 2 slots `150 + 175*d`, 3 slots `200 + 225*d`), and a title and `favStat` by type. When `dayNum == 0`, it may instead become an item quest ([[quest_resource#_get_item_reward_chance]]): `reward_items` is rolled and gold set to 0.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `diff` | int | The quest rank (`QuestDifficulty`) | `rank` rolled in [[hall_rules#build_day_quests]]; `0` for boss entries in [[hall_rules#_build_boss_entries]] |
| `dayNum` | int | A day that selects a scripted quest; negative for the second quest of a two-quest day; 0 = standard quest | `GameState.day`, `-GameState.day`, `5`, or the boss `variant` in [[hall_rules]] |

**Returns:** nothing (constructor).

**Side effects:** consumes the global RNG; reads `GameState.day` (through [[quest_resource#_get_item_reward_chance]]), `ExternalContentContainer` and `QuestManager.world_regions`; prints debug lines (`print(regionNum, " ", location)`).

**Called by:** [[hall_rules#build_day_quests]] (`hall_rules.gd:150`, `:152`, `:157`, `:160`), [[hall_rules#_build_boss_entries]] (`hall_rules.gd:181`), the `RefReader` inner class of [[hall_save]] (`hall_save.gd:467`, `CreatedQuest.new()`, fields overwritten after), [[quest_Manager#_ready]] (`quest_Manager.gd:32`).

**Calls:** [[quest_resource#_initMilestoneVars]], [[external_content_container#get_Quest_Story]], [[region_resource#returnName]], [[quest_resource#_get_item_reward_chance]], [[quest_resource#_roll_reward_items]].

### apply_freeplay_scaling
`func apply_freeplay_scaling(multiplier: float) -> void` · `Scripts/Quest Creator/quest_resource.gd:248`

Freeplay: sets `requirement_multiplier = multiplier` and scales the gold by it.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `multiplier` | `float` | 1.0 = unchanged, 1.5 = half again the stats and gold | no caller |

**Returns:** nothing.

**Side effects:** writes `requirement_multiplier`, `goldReward`, `startingGoldReward`.

**Called by:** nothing found. [[hall_rules]] sets `requirement_multiplier` directly and calls [[quest_resource#apply_freeplay_gold]] itself.

**Calls:** [[quest_resource#apply_freeplay_gold]].

### apply_freeplay_gold
`func apply_freeplay_gold(multiplier: float) -> void` · `Scripts/Quest Creator/quest_resource.gd:255`

Scales only `goldReward` and `startingGoldReward` (rounded), leaving the stat requirement alone.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `multiplier` | `float` | 1.0 = unchanged | `freeplay_scale(day)` in [[hall_rules#_scale_normal_quest]] |

**Returns:** nothing.

**Side effects:** writes the two gold fields.

**Called by:** [[hall_rules#_scale_normal_quest]] (`hall_rules.gd:195`), [[quest_resource#apply_freeplay_scaling]] (`quest_resource.gd:250`).

**Calls:** none.

### calcSuccessChance
`func calcSuccessChance(_questingAdventurers: Array) -> int` · `Scripts/Quest Creator/quest_resource.gd:260`

The party's success chance in percent. The requirement is `(60 + 20 * difficulty) * (party slots / 2) * requirement_multiplier`. The party total is, per hero: the four quest stats, the region's favored stat again, then each favored component once (a Pluck component adds `pluck`, doubled when `favStat` is plain Pluck). The result is `snapped(total / requirement, 0.01) * 100`. It can run past 100. Each hero's temp stats are rebuilt first so Pluck and gear are current.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_questingAdventurers` | `Array` | The party | `party` passed through [[quest_scoring#get_success_chance]]; `party` or `[character]` in [[hall_main#success_chance]] and [[hall_main#chance_added_by]] |

**Returns:** `int` declared, but the value is `snapped(..) * 100`, a float. [[quest_scoring#get_success_chance]] returns it as float to [[hall_rules#play_quest]] and [[hall_wallet#tonight_earnings]]; [[hall_main#success_chance]] and [[hall_main#chance_added_by]] wrap it in `int()` for the views.

**Side effects:** rebuilds each hero's `temp_stats` ([[character_resource#reset_temp_stats]]).

**Called by:** [[hall_main#success_chance]] (`hall_main.gd:634`), [[hall_main#chance_added_by]] (`hall_main.gd:657`), [[quest_scoring#get_success_chance]] (`quest_scoring.gd:22`), [[quest_Manager#_ready]] (`quest_Manager.gd:40`).

**Calls:** [[quest_scoring#get_slot_count]], [[character_resource#reset_temp_stats]], [[character_resource#get_quest_stat]], [[quest_resource#region_favored_stat]], [[quest_resource#favored_components]].

### region_favored_stat
`func region_favored_stat() -> int` · `Scripts/Quest Creator/quest_resource.gd:290`

The `GuildCharacter.StatType` index this quest's region favors: `REGION_FAVORED_STAT[regionNum]`.

**Parameters:** none.

**Returns:** `int` (0-3). Used by the success chance, and by [[quest_resource#trained_stat_options]] and [[quest_resource#roll_trained_stat]] as the fallback stat.

**Side effects:** none.

**Called by:** [[quest_resource#calcSuccessChance]] (`quest_resource.gd:275`), [[quest_resource#trained_stat_options]] (`:318`, `:319`), [[quest_resource#roll_trained_stat]] (`:333`).

**Calls:** none.

### favored_components
`func favored_components() -> Array[int]` · `Scripts/Quest Creator/quest_resource.gd:298`

The favored stat's components: a value under 10 is one component (a `StatType` index 0-3, or `PLUCK_COMPONENT`); a two-digit value is a combo of its two digits (12 = Defense + Wisdom, 40 = Pluck + Power).

**Parameters:** none.

**Returns:** `Array[int]`. `PLUCK_COMPONENT` (4) is Pluck, which isn't a `StatType`.

**Side effects:** none.

**Called by:** [[hall_style#favored_components]] (`hall_style.gd:341`, `quest.favored_components()` on a `CreatedQuest`), [[quest_resource#calcSuccessChance]] (`:279`), [[quest_resource#trained_stat_options]] (`:315`), [[quest_resource#roll_trained_stat]] (`:328`).

**Calls:** none.

### trained_stat_options
`func trained_stat_options() -> Array[int]` · `Scripts/Quest Creator/quest_resource.gd:313`

The one or two stats a good-odds win can train: the trainable favored components (Pluck is dropped), then the region's stat if not already listed.

**Parameters:** none.

**Returns:** `Array[int]` of `StatType` indexes. [[hall_main#trained_stat_options]] returns it, and [[screen_assign#_odds_caption]] lists the stat names with it.

**Side effects:** none.

**Called by:** [[hall_main#trained_stat_options]] (`hall_main.gd:652`).

**Calls:** [[quest_resource#favored_components]], [[quest_resource#region_favored_stat]].

### roll_trained_stat
`func roll_trained_stat() -> int` · `Scripts/Quest Creator/quest_resource.gd:326`

Picks the stat a good-odds win trains: a random trainable favored stat `trained_stat_quest_chance` percent of the time (if there is one), otherwise the region's.

**Parameters:** none.

**Returns:** `int` `StatType` index (0-3). [[hall_rules#play_quest]] raises that stat on every party member and reports it as `trained_stat`.

**Side effects:** consumes the global RNG.

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:394`).

**Calls:** [[quest_resource#favored_components]], [[quest_resource#region_favored_stat]].

### generateResults
`func generateResults(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String` · `Scripts/Quest Creator/quest_resource.gd:338`

Plays the quest and returns the BBCode story. It rolls `_will_fail = randi_range(0, 100) >= _successChance` once up front, records each hero's starting injury level, and writes the intro (names plus story column 1). It then runs the encounter loops, a mid-quest gold bonus or penalty on rank C and above, and a closing branch for failure (column 4, a retreat injury, "NOT SUCCESSFUL" summary) or success (column 5, gold or item-reward summary). Found equipment and death lines are appended last.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_questingAdventurers` | `Array[GuildCharacter]` | The party (at least one hero) | `party` built from `entry.party` in [[hall_rules#play_quest]]; a one-hero array in [[quest_Manager#_ready]] |
| `_successChance` | `float` | Percent chance | `chance` from [[quest_scoring#get_success_chance]] |

**Returns:** `String` (BBCode). [[hall_rules#play_quest]] passes it to [[quest_scoring#did_succeed]] and stores it as the result's `story`.

**Side effects:** changes `goldReward`, `successfulChecks`, `questSummary`, `found_items`, `dead_adventurers`, the party's injuries; sets `numAdventurers`, `_will_fail`, `_starting_levels`.

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:361`), [[quest_Manager#_ready]] (`quest_Manager.gd:42`).

**Calls:** [[external_content_container#get_Quest_Story]], [[external_content_container#get_Minor_Story]], [[external_content_container#get_Milestone_story]], [[quest_resource#_combatEncounter]], [[quest_resource#_search]], [[quest_resource#_retreat]], [[quest_resource#pays_in_items]], [[quest_resource#_get_reward_item_names]], [[quest_resource#_get_found_items_lines]], [[quest_resource#_deathLines]].

> [!note] How it works
> Rank G (-1): a fixed search, fight, search; its loop counter starts at -1 so the loop below never runs. Rank F and D (difficulty 0-1): one loop `while randi_range(-1, 10) < loopbreaker` (starting 12 + 3*difficulty, shrinking by one each pass) picking a fight or search each pass.
> Rank C and above: a first loop (`4 + 2*difficulty`, `randi_range(-1, 6)`), then a check: if `successfulChecks >= 2 + difficulty` the middle story (column 3) says `extraGold` (`50 + 25*difficulty`) is added, otherwise column 2 says it is removed; a second loop follows. On a win, `goldReward` gets `+extraGold` or `-extraGold` accordingly.

### _can_die
`func _can_die(hero: GuildCharacter) -> bool` · `Scripts/Quest Creator/quest_resource.gd:518`

Whether a hero may die from the next hit: when the quest fails (`_will_fail`), or the hero set out Hurt (LIGHTLY_INJURED) or worse. Heroes who set out Healthy or Sore on a won quest stop at Gravely injured.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hero` | `GuildCharacter` | A party member | loop variable in [[quest_resource#_hittable_heroes]] / argument of [[quest_resource#_injure_in_fight]] |

**Returns:** `bool`.

**Side effects:** none.

**Called by:** [[quest_resource#_hittable_heroes]] (`quest_resource.gd:529`), [[quest_resource#_injure_in_fight]] (`quest_resource.gd:537`).

**Calls:** none.

### _hittable_heroes
`func _hittable_heroes(party: Array[GuildCharacter]) -> Array[GuildCharacter]` · `Scripts/Quest Creator/quest_resource.gd:524`

Heroes the next fight hit could still change: alive, and not already at the Gravely cap while protected from dying.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `party` | `Array[GuildCharacter]` | The quest's party | `_questingAdventurers` in [[quest_resource#_combatEncounter]] |

**Returns:** `Array[GuildCharacter]`. [[quest_resource#_combatEncounter]] picks the hurt hero from it.

**Side effects:** none.

**Called by:** [[quest_resource#_combatEncounter]] (`quest_resource.gd:584`).

**Calls:** [[quest_resource#_can_die]].

### _injure_in_fight
`func _injure_in_fight(hero: GuildCharacter) -> void` · `Scripts/Quest Creator/quest_resource.gd:536`

Injures a hero from a fight (`injure_character(_can_die(hero))`) and records a death in `dead_adventurers`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hero` | `GuildCharacter` | The hero hit | `hurt_hero` in [[quest_resource#_combatEncounter]] |

**Returns:** nothing.

**Side effects:** injures the hero, may append to `dead_adventurers`.

**Called by:** [[quest_resource#_combatEncounter]] (`quest_resource.gd:618`).

**Calls:** [[character_resource#injure_character]], [[quest_resource#_can_die]].

### _retreat
`func _retreat(party: Array[GuildCharacter]) -> String` · `Scripts/Quest Creator/quest_resource.gd:544`

After a failed quest's fights, every living hero takes one more injury (can die).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `party` | `Array[GuildCharacter]` | The party | `_questingAdventurers` in [[quest_resource#generateResults]] |

**Returns:** `String`, the "beaten back" story line, or `""` when nobody could be hurt further. Appended to the story in `generateResults`.

**Side effects:** injures heroes, may append to `dead_adventurers`.

**Called by:** [[quest_resource#generateResults]] (`quest_resource.gd:460`).

**Calls:** [[character_resource#injure_character]].

### _combatEncounter
`func _combatEncounter(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String` · `Scripts/Quest Creator/quest_resource.gd:558`

One fight. The fight is won when `min(90, chance^2 / 100) >= randi(0..100)`. Whether it hurts someone is set by the quest's odds ([[quest_injuries#injury_chance_per_encounter]]), not by who wins, so the average wear matches the injury table; the hurt hero is a random hittable one. A won fight turns up 11-29 gold on the corpse 25% of the time (added to `goldReward`). A won fight adds 1 to `successfulChecks`. The monster comes from the region, or from the quest manager's story monsters on minor (rows 5-8) and milestone (rows 0-2) quests.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_questingAdventurers` | `Array[GuildCharacter]` | The party | `_questingAdventurers` of [[quest_resource#generateResults]] |
| `_successChance` | `float` | Percent chance | `_successChance` of `generateResults` |

**Returns:** `String`, the fight's story line (names a hurt hero or the party).

**Side effects:** may injure a hero and raise `goldReward` and `successfulChecks`.

**Called by:** [[quest_resource#generateResults]] (`quest_resource.gd:376`, `:382`, `:392`, `:437`).

**Calls:** [[region_resource#returnMonster]], [[quest_Manager#_returnQuestMonster]], [[quest_resource#_hittable_heroes]], [[quest_injuries#injury_chance_per_encounter]], [[quest_resource#_injure_in_fight]].

### _search
`func _search(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String` · `Scripts/Quest Creator/quest_resource.gd:640`

One search. It succeeds when `min(90, chance^2 / 100) >= randi(0..100)`. On success it may find equipment instead ([[quest_resource#_get_equipment_find_chance]], then [[quest_resource#_find_equipment]]); otherwise a random result of gold finds (3-59 gold into `goldReward`) and `successfulChecks` goes up by 1. On a failure it rolls a "found nothing" line, or a trapped chest worth 3-15 gold, or 1 gold.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_questingAdventurers` | `Array[GuildCharacter]` | The party | `_questingAdventurers` of [[quest_resource#generateResults]] |
| `_successChance` | `float` | Percent chance | `_successChance` of `generateResults` |

**Returns:** `String`, the search's story line (may be `""`, see issues).

**Side effects:** raises `goldReward`, `successfulChecks`; may append to `found_items`.

**Called by:** [[quest_resource#generateResults]] (`quest_resource.gd:375`, `:377`, `:384`, `:394`, `:439`).

**Calls:** [[quest_resource#_get_equipment_find_chance]], [[quest_resource#_find_equipment]].

### _get_equipment_find_chance
`func _get_equipment_find_chance(questing_adventurers: Array[GuildCharacter], success_chance: float) -> float` · `Scripts/Quest Creator/quest_resource.gd:714`

How likely (percent) a successful search is to turn up equipment: `equipment_base_chance + equipment_risk_bonus * (1 - chance/100) + equipment_shorthanded_bonus * empty slots`, clamped to 0..`equipment_max_chance`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `questing_adventurers` | `Array[GuildCharacter]` | The party | `_questingAdventurers` in [[quest_resource#_search]] |
| `success_chance` | `float` | Quest chance, 0-100 | `_successChance` in `_search` |

**Returns:** `float` percent, compared to a `randf_range(0, 100)` in `_search`.

**Side effects:** none.

**Called by:** [[quest_resource#_search]] (`quest_resource.gd:654`).

**Calls:** none.

### _find_equipment
`func _find_equipment(searching_adventurer: GuildCharacter) -> String` · `Scripts/Quest Creator/quest_resource.gd:731`

Makes a [[passive_item]] for the finder's role (rarity by this quest's difficulty), sets its `role`, and appends it to `found_items`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `searching_adventurer` | `GuildCharacter` | The hero who found it | random pick from the party in `_search` |

**Returns:** `String`, the "hidden cache" story line.

**Side effects:** appends to `found_items`.

**Called by:** [[quest_resource#_search]] (`quest_resource.gd:655`).

**Calls:** [[passive_item#_init]].

### _get_found_items_lines
`func _get_found_items_lines() -> String` · `Scripts/Quest Creator/quest_resource.gd:744`

The end-of-quest line listing every piece of equipment found, also added to `questSummary`. Found gear is kept even when the quest fails.

**Parameters:** none.

**Returns:** `String`, or `""` if nothing was found. Appended to the story.

**Side effects:** appends to `questSummary` when items were found.

**Called by:** [[quest_resource#generateResults]] (`quest_resource.gd:503`).

**Calls:** none.

### pays_in_items
`func pays_in_items() -> bool` · `Scripts/Quest Creator/quest_resource.gd:758`

True if the quest pays in equipment (`reward_items`) instead of gold.

**Parameters:** none.

**Returns:** `bool`. [[hall_rules#play_quest]] pays `reward_items` only when this is true and the quest won; [[quest_row#_show_quest_facts]] shows the item reward.

**Side effects:** none.

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:379`), [[quest_row#_show_quest_facts]] (`quest_row.gd:91`), [[quest_resource#generateResults]] (`quest_resource.gd:488`), [[quest_resource#get_reward_text]] (`quest_resource.gd:765`).

**Calls:** none.

### get_reward_text
`func get_reward_text() -> String` · `Scripts/Quest Creator/quest_resource.gd:764`

The reward as shown on the Board and Assign Party: "250 gold" or, for an item quest, "2 items · RARE, COMMON".

**Parameters:** none.

**Returns:** `String`. No caller found: [[hall_style]] documents it (`hall_style.gd:445`) but builds its own text.

**Side effects:** none.

**Called by:** nothing found (only mentioned in a comment at `hall_style.gd:445`).

**Calls:** [[quest_resource#pays_in_items]].

### _get_item_reward_chance
`func _get_item_reward_chance() -> float` · `Scripts/Quest Creator/quest_resource.gd:779`

How likely (percent) a new standard quest pays in items: `item_reward_base_chance + item_reward_chance_per_day * max(GameState.day - 1, 0)`, clamped to 0..`item_reward_max_chance`. The day comes from `GameState`, as the code comment says standard quests are built with `dayNum = 0` (see Suspected issues).

**Parameters:** none.

**Returns:** `float` percent, compared to `randf_range(0, 100)` in [[quest_resource#_init]].

**Side effects:** none.

**Called by:** [[quest_resource#_init]] (`quest_resource.gd:178`).

**Calls:** none.

### _roll_reward_items
`func _roll_reward_items() -> void` · `Scripts/Quest Creator/quest_resource.gd:788`

Fills `reward_items` for an item quest: `1 + int(difficulty * item_reward_count_per_rank)` [[passive_item]]s, each for a random hero role (`role` set like Shop stock), with rarity weighted by difficulty, sorted rarest first.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** rewrites `reward_items`.

**Called by:** [[quest_resource#_init]] (`quest_resource.gd:179`).

**Calls:** [[passive_item#_init]].

### _get_reward_item_names
`func _get_reward_item_names() -> PackedStringArray` · `Scripts/Quest Creator/quest_resource.gd:805`

The names of the reward items, e.g. `["RARE Dagger", "COMMON Charm"]`.

**Parameters:** none.

**Returns:** `PackedStringArray`, joined into the success summary in `generateResults`.

**Side effects:** none.

**Called by:** [[quest_resource#generateResults]] (`quest_resource.gd:490`).

**Calls:** none.

### _init_boss_vars
`func _init_boss_vars(rank: int, slots: int, story_row: int, region: int, favored: FavoredStat, title: String) -> void` · `Scripts/Quest Creator/quest_resource.gd:817`

Fills in a boss quest read from the Milestone Story Parts rows (days 30, 40 and 50). Gold is `300 + 150 * difficulty`; `styleOfQuest` is 2.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `rank` | int | Difficulty | literal in [[quest_resource#_initMilestoneVars]] (3, 4, 4, 5) |
| `slots` | int | `maxAdventurers` | literal (5, 4, 5, 8) |
| `story_row` | int | Row of the Milestone Story Parts file (`questNum`) | literal (3, 4, 5, 6) |
| `region` | int | Index into `QuestManager.world_regions` | literal (2, 1, 3, 0) |
| `favored` | `FavoredStat` | Favored stat | literal |
| `title` | String | Board title | literal |

**Returns:** nothing.

**Side effects:** sets the quest's fields.

**Called by:** [[quest_resource#_initMilestoneVars]] (`quest_resource.gd:871`, `:875`, `:879`, `:883`).

**Calls:** [[external_content_container#get_Milestone_story]], [[region_resource#returnName]].

### _initMilestoneVars
`func _initMilestoneVars(dayNum: int)` · `Scripts/Quest Creator/quest_resource.gd:831`

Fills in a scripted quest for a day. Days 10, 20 and -20 (Bone Drake, resurrected drake, Necromancer) set the fields inline (style 2). Days 30, 40, -40 and 50 go through [[quest_resource#_init_boss_vars]]. Every other listed day (1, 2, 4, ... 48 and -18) reads a row of the minor story variables by a fixed day-to-row table (style 1: difficulty, slots, story row, region, gold, favored stat, title).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `dayNum` | int | The scripted day (negative = the second quest of a two-quest day) | `dayNum` of [[quest_resource#_init]] |

**Returns:** nothing.

**Side effects:** sets the quest's fields; prints debug lines.

**Called by:** [[quest_resource#_init]] (`quest_resource.gd:148`).

**Calls:** [[quest_resource#_init_boss_vars]], [[external_content_container#get_Milestone_story]], [[external_content_container#get_Minor_Story]], [[external_content_container#get_Minor_Story_Variables]], [[region_resource#returnName]].

### _deathLines
`func _deathLines() -> String` · `Scripts/Quest Creator/quest_resource.gd:956`

One "succumbed to their injuries" line per hero in `dead_adventurers`, also appended to `questSummary`.

**Parameters:** none.

**Returns:** `String`, appended to the story in `generateResults`.

**Side effects:** appends to `questSummary`.

**Called by:** [[quest_resource#generateResults]] (`quest_resource.gd:504`).

**Calls:** none.

### generatePartyDuo
`func generatePartyDuo() -> Array[GuildCharacter]` · `Scripts/Quest Creator/quest_resource.gd:964`

Makes two random heroes. Debug helper for [[quest_Manager#_ready]].

**Parameters:** none.

**Returns:** `Array[GuildCharacter]` of two new heroes.

**Side effects:** none.

**Called by:** [[quest_Manager#_ready]] (`quest_Manager.gd:37`).

**Calls:** [[character_resource#_init]].

## Suspected issues
- `quest_resource.gd:248` `apply_freeplay_scaling` has no callers; [[hall_rules]] sets `requirement_multiplier` itself. The comment at `:104` still names it as the setter.
- `quest_resource.gd:764` `get_reward_text` has no callers.
- `quest_resource.gd:260` `calcSuccessChance` is declared `-> int` but returns a float expression.
- `quest_resource.gd:779` the doc comment says "HallRules passes dayNum = 0 for normal quests", but [[hall_rules#build_day_quests]] passes `GameState.day`, so on days outside the scripted list `dayNum` is non-zero and the item-quest branch at `:178` (`dayNum == 0`) does not run in the normal hall flow. Only a `CreatedQuest.new()` with no arguments (the save loader, debug) reaches it. Likely a bug; the caller side was read but not run.
- `quest_resource.gd:640` `_search`: on a successful search, a roll of 76-100 matches no branch, so it returns `""` while still counting a successful check. A roll of 38 matches the 26-38 branch first (the 38-50 branch overlaps at 38).
- `quest_resource.gd:1` the file has a header-less top (no `##` class comment) and many undocumented functions (`_init`, `calcSuccessChance`, `generateResults`, `_combatEncounter`, `_search`, `_initMilestoneVars`, `_deathLines`, `generatePartyDuo`).
