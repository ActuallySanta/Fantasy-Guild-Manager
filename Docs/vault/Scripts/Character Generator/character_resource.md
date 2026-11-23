---
source: Scripts/Character Generator/character_resource.gd
class_name: GuildCharacter
extends: Resource
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, resource]
---

# character_resource.gd

## Purpose
`GuildCharacter`: one hero. It holds role, injury level, base `stats`, the `temp_stats` that quests actually read (rebuilt from base stats, Pluck and gear), the equipped items, and the recruit price rules. Creating one needs [[external_content_container]] to have loaded (names, icons, backstories) and [[quest_Manager]] for `world_regions`. Heroes are created in [[character_container]], [[hall_rules#make_starting_hero]], the save loader and the playtest scenarios. Gear never writes to `stats`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `CharacterGender` | enum | `FEMALE, MALE, ANDROGYNOUS`. |
| `CharacterRole` | enum | `KNIGHT=0, PRIEST=1, PATHFINDER=2, MAGE=3`. Saved by value. |
| `InjuryLevel` | enum | `HEALTHY=0, SORE, LIGHTLY_INJURED, GRAVELY_INJURED, DEAD=4`. Saved by value. |
| `StatType` | enum | `STRENGTH, DEFENSE, WISDOM, SLEAZINESS` (indexes 0-3). |
| `CharacterStatus` | enum | `IDLE, ON_QUEST, TRAINING, HEALING, DEAD`. `status` is set to `IDLE` in `_init`; nothing else reads or writes it. |
| `name`, `title`, `description` | var (String) | Display name, "Name the Role" title, backstory text. |
| `hometown` | var (`Region`) | Random world region, set in `_init`. |
| `max_rand_backstories` | var (int) | 3. Extra random backstory lines tried in [[character_resource#generate_description]]. |
| `role` | var (`CharacterRole`) | The hero's role. Decides which gear fits and the +3 stat bonus. |
| `injury_level`, `injury_count` | var | Current `InjuryLevel`, and how many injuries were taken in total. |
| `died_on_day`, `died_on_quest` | var | Day (-1 while alive) and quest title of death. Set by [[hall_rules#play_quest]]. |
| `joined_on_day` | var (int) | The day the hero last joined the guild (default 1). Feeds [[hall_ledger#build_run_records]]. |
| `stat_deviation` | var (int) | 2. Spread of the stat roll; recruits get a larger one from [[hire_scaling#deviation_for]]. |
| `stats` | var (`Dictionary[StatType, int]`) | Base stats. Armory bonus is written here by [[guild_upgrades]]; training raises it. |
| `temp_stats` | var (`Dictionary[StatType, int]`) | Pluck and gear bonus, rebuilt by [[character_resource#reset_temp_stats]]. |
| `pluck` | var (int) | Pluck level; each level adds a bonus to every stat. |
| `total_points` | var (int) | 17. Stat points rolled by `generate_stat_spread`. |
| `gender`, `status`, `icon` | var | Gender, `CharacterStatus`, icon texture. |
| `cost` | var (int) | Hire price in gold. |
| `equipped_items` | var (`Array[StandardItem]`) | Worn items. Added by [[item_container]]. |
| `max_items` | var (int) | 2. Gear slots. |

## Functions

### _init
`func _init() -> void` · `Scripts/Character Generator/character_resource.gd:96`

Constructor. Rolls a random gender and role, a name for the gender ([[external_content_container#get_character_name]]), a random `hometown` from `QuestManager.world_regions`, the role icon, the stat spread and description. Sets `injury_level` HEALTHY, `injury_count` 0, status IDLE, the title, `cost = recruit_cost_for_day(GameState.day)` and the Pluck temp stats.

**Parameters:** none.

**Returns:** nothing (constructor).

**Side effects:** consumes the global RNG; reads `GameState.day`.

**Called by:** `GuildCharacter.new()` in [[character_container#_add_new_recruits]] (`character_container.gd:69`), [[character_container#generate_new_character]] (`character_container.gd:112`), [[hall_rules#make_starting_hero]] (`hall_rules.gd:96`), the `RefReader` inner class of [[hall_save]] (`hall_save.gd:463`), [[hall_debug#add_hero]] (`hall_debug.gd:64`), [[playtest_scenario#_ready]] (`playtest_scenario.gd:56`, `:61`), [[quest_resource#generatePartyDuo]] (`quest_resource.gd:967`, `:968`).

**Calls:** [[external_content_container#get_character_name]], [[external_content_container#get_character_icon]], [[character_resource#generate_stat_spread]], [[character_resource#generate_description]], [[character_resource#recruit_cost_for_day]], [[character_resource#add_pluck_temp_stats]].

### recruit_cost_for_day
`static func recruit_cost_for_day(day: int) -> int` · `Scripts/Character Generator/character_resource.gd:124`

What a new recruit costs to hire on a given day: 200 from day 5, 100 on days 3-4, free before that.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day | `GameState.day` (or `GameState.day + 1` for tomorrow's price in the danger checks) |

**Returns:** `int` gold. [[hire_scaling#recruit_cost]] adds the per-point surcharge to it; [[hall_ledger#is_short_of_recruit_gold]] and the header strip compare tomorrow's price to the gold; [[hall_wallet#recruit_price]] shows it; [[character_container#_add_returning_characters]] uses it as the base for a returning hero's price.

**Side effects:** none.

**Called by:** [[character_container#_add_returning_characters]] (`character_container.gd:78`), [[character_resource#_init]] (`character_resource.gd:116`), [[hall_ledger#is_short_of_recruit_gold]] (`hall_ledger.gd:59`), [[hall_wallet#recruit_price]] (`hall_wallet.gd:121`), [[hire_scaling#recruit_cost]] (`hire_scaling.gd:89`), [[hall_header#_refresh_danger_strip]] (`hall_header.gd:208`), [[popup_gold#refresh]] (`popup_gold.gd:85`).

**Calls:** none.

### reroll_stats
`func reroll_stats(points: int, deviation: int) -> void` · `Scripts/Character Generator/character_resource.gd:136`

Rolls this character's stats again from `points` stat points (plus the usual role bonus) with a spread of `deviation`. Used for recruits, whose budget grows with the guild.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `points` | `int` | Stat points to spread | `points` budget from [[hire_scaling#recruit_budget]] / [[hire_scaling#standout_budget]] |
| `deviation` | `int` | Spread of the roll | [[hire_scaling#deviation_for]] |

**Returns:** nothing.

**Side effects:** sets `total_points` and `stat_deviation`, zeroes then rewrites `stats`, rebuilds `temp_stats`.

**Called by:** [[character_container#_add_new_recruits]] (`character_container.gd:70`).

**Calls:** [[character_resource#generate_stat_spread]], [[character_resource#reset_temp_stats]].

### generate_stat_spread
`func generate_stat_spread(_stats: Dictionary[StatType, int], _total_points: int) -> void` · `Scripts/Character Generator/character_resource.gd:146`

Generates the stats by normalized random sampling: each of the four stats gets `randfn(total / 4, stat_deviation)`, then each is scaled to its share of `_total_points` (truncated to int). Then the role bonus of +3 is added to one stat by `role`: Knight to Defense, Priest to Wisdom, Pathfinder to Sleaziness, Mage to Strength.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_stats` | `Dictionary[StatType, int]` | The stats dictionary to fill | `stats` of this hero |
| `_total_points` | `int` | Points to spread | `total_points` |

**Returns:** nothing.

**Side effects:** writes `_stats`.

**Called by:** [[character_resource#_init]] (`character_resource.gd:107`), [[character_resource#reroll_stats]] (`character_resource.gd:141`).

**Calls:** none.

### generate_description
`func generate_description() -> String` · `Scripts/Character Generator/character_resource.gd:175`

Builds the backstory text: the role backstory plus up to `max_rand_backstories` random backstory lines (a line already present is skipped).

**Parameters:** none.

**Returns:** `String`, assigned to `description`. [[hall_rules#make_starting_hero]] calls it again after setting the name.

**Side effects:** consumes the global RNG.

**Called by:** [[character_resource#_init]] (`character_resource.gd:108`), [[hall_rules#make_starting_hero]] (`hall_rules.gd:105`).

**Calls:** [[external_content_container#get_role_backstory]], [[external_content_container#get_random_backstory]].

### injure_character
`func injure_character(can_die: bool = true) -> bool` · `Scripts/Character Generator/character_resource.gd:190`

Raises the injury level by one. A dead hero is unchanged. With `can_die` false, a hit that would kill stops at Gravely injured: nothing changes (`injury_count` included) and it returns false.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `can_die` | `bool` | Whether this hit may kill | `_can_die(hero)` in [[quest_resource#_injure_in_fight]]; `true` in [[quest_resource#_retreat]] |

**Returns:** `bool`, true when this hit killed the hero. Both callers append the hero to `dead_adventurers` when true.

**Side effects:** `injury_count += 1`, `injury_level += 1`.

**Called by:** [[quest_resource#_injure_in_fight]] (`quest_resource.gd:537`), [[quest_resource#_retreat]] (`quest_resource.gd:550`).

**Calls:** none.

### level_up_random_stat
`func level_up_random_stat(_points_to_add: int)` · `Scripts/Character Generator/character_resource.gd:208`

Adds 1 to a random base stat, `_points_to_add` times, and `total_points` with it.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_points_to_add` | `int` | Number of points | no caller |

**Returns:** nothing.

**Side effects:** writes `stats` and `total_points`.

**Called by:** nothing found (Grep of `Globals/`, `Scripts/`, `Scenes/`). Dead code.

**Calls:** none.

### increase_temp_stat
`func increase_temp_stat(_stat: StatType, _points_to_add: int)` · `Scripts/Character Generator/character_resource.gd:215`

Adds `_points_to_add` to one entry of `temp_stats`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_stat` | `StatType` | Stat to raise | `pass_item.affected_stat` / the stat in the pluck loop |
| `_points_to_add` | `int` | Amount | `pass_item.stat_amount` / [[character_resource#get_pluck_stat_bonus]] |

**Returns:** nothing.

**Side effects:** writes `temp_stats`.

**Called by:** [[character_resource#add_passive_item_stats]] (`character_resource.gd:240`), [[character_resource#add_pluck_temp_stats]] (`character_resource.gd:246`).

**Calls:** none.

### reset_temp_stats
`func reset_temp_stats()` · `Scripts/Character Generator/character_resource.gd:220`

Zeroes `temp_stats`, then reapplies Pluck and equipped gear. Pluck is worked out from the base stats only, so it doesn't stack on gear.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** rewrites `temp_stats`.

**Called by:** [[game_state#_refresh_temp_stats]] (`game_state.gd:54`), [[item_shop#equip]] (`item_shop.gd:149`, `:150`), [[item_shop#unequip]] (`item_shop.gd:161`), [[character_resource#reroll_stats]] (`character_resource.gd:142`), [[hall_debug#heal_everyone]] (`hall_debug.gd:107`), [[hall_save#apply_snapshot]] (`hall_save.gd:346`), [[hall_style#quest_stat_value]] (`hall_style.gd:389`), [[quest_resource#calcSuccessChance]] (`quest_resource.gd:271`).

**Calls:** [[character_resource#add_pluck_temp_stats]], [[character_resource#add_passive_item_stats]].

### get_quest_stat
`func get_quest_stat(_stat: StatType) -> int` · `Scripts/Character Generator/character_resource.gd:231`

The stat value quests use: base stat plus temp stats (Pluck, gear).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_stat` | `StatType` | Stat index 0-3 | loop constants, [[quest_resource#region_favored_stat]], [[quest_resource#favored_components]] |

**Returns:** `int`. [[quest_resource#calcSuccessChance]] sums it over the party; [[hall_style#quest_stat_value]] shows it.

**Side effects:** none.

**Called by:** [[hall_style#quest_stat_value]] (`hall_style.gd:390`), [[quest_resource#calcSuccessChance]] (`quest_resource.gd:273`, `:275`, `:283`).

**Calls:** none.

### add_passive_item_stats
`func add_passive_item_stats()` · `Scripts/Character Generator/character_resource.gd:236`

Adds every equipped [[passive_item]]'s `stat_amount` to its `affected_stat` in `temp_stats`.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** writes `temp_stats`.

**Called by:** [[character_resource#reset_temp_stats]] (`character_resource.gd:227`).

**Calls:** [[character_resource#increase_temp_stat]].

### add_pluck_temp_stats
`func add_pluck_temp_stats()` · `Scripts/Character Generator/character_resource.gd:244`

Gives every stat its Pluck bonus (see [[character_resource#get_pluck_stat_bonus]]) in `temp_stats`.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** writes `temp_stats`.

**Called by:** [[character_resource#_init]] (`character_resource.gd:118`), [[character_resource#reset_temp_stats]] (`character_resource.gd:226`).

**Calls:** [[character_resource#get_pluck_stat_bonus]], [[character_resource#increase_temp_stat]].

### get_pluck_stat_bonus
`func get_pluck_stat_bonus(_stat: StatType) -> int` · `Scripts/Character Generator/character_resource.gd:252`

How much a stat is raised by Pluck: `max(pluck, int(stats[_stat] * pluck / 10.0))`, i.e. 10% of the base stat per level, rounded down, but at least +1 per level.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_stat` | `StatType` | Stat to read | the pluck loop / `stat_index` in [[screen_character#_show_stats]] |

**Returns:** `int`. Used by [[character_resource#add_pluck_temp_stats]] and shown by [[screen_character#_show_stats]] (`screen_character.gd:227`).

**Side effects:** none.

**Called by:** [[character_resource#add_pluck_temp_stats]] (`character_resource.gd:246`), [[screen_character#_show_stats]] (`screen_character.gd:227`).

**Calls:** none.

### try_add_item
`func try_add_item(_item: StandardItem) -> bool` · `Scripts/Character Generator/character_resource.gd:257`

Appends the item to `equipped_items` when there is room (`size < max_items`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_item` | `StandardItem` | The item to wear | no caller |

**Returns:** `bool`, true if added.

**Side effects:** changes `equipped_items`.

**Called by:** nothing found. Dead code (equipping goes through [[item_container]] and [[item_shop#equip]]).

**Calls:** none.

## Suspected issues
- `character_resource.gd:208` `level_up_random_stat` and `:257` `try_add_item` have no callers.
- `character_resource.gd:146` `generate_stat_spread` assigns a float into `int` stat slots, truncating, so the stats usually sum to a few points under `_total_points` (before the +3 role bonus).
- `character_resource.gd:80`: `status` (`CharacterStatus`) is only ever set to `IDLE` in `_init`; nothing in `Globals/`, `Scripts/` or `Scenes/` reads or writes it, so the enum is unused.
