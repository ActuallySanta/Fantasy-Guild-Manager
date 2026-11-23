---
source: Globals/character_container.gd
class_name: null
extends: Node2D
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, autoload]
---

# character_container.gd

## Purpose
Autoload `CharacterContainer`. Holds the guild's roster (`active_characters`), today's For Hire pool (`hireable_characters`) and living heroes who were released and may return (`released_characters`). Released heroes can come back to For Hire on a later day for a higher price. It has no scene. Hall code and UI call it directly.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `RETURN_CHANCE` | const | Chance (0-1) each released hero has of showing up in For Hire on a new day. Value 0.15. |
| `RETURN_COST_MULTIPLIER` | const | A returning hero costs this many times the day's normal recruit price (value 2). |
| `RETURN_MIN_COST` | const | The recruit price is counted from at least this much (gold, value 100), so returners are never free on days 1-2. |
| `max_characters` | var (`@export`, int) | Bed cap for living heroes, default 5. `GuildUpgrades._apply_effects` sets it from the Barracks level. |
| `active_characters` | var (`@export`, `Array[GuildCharacter]`) | The roster, dead heroes included. |
| `max_hireable_characters` | var (`@export`, int) | How many new faces the hiring screen shows. `refresh_hireable_characters` overwrites it by day. |
| `hireable_characters` | var (`Array[GuildCharacter]`) | Today's For Hire pool. |
| `released_characters` | var (`Array[GuildCharacter]`) | Living heroes who were released. Hiring one removes them from this list. |
| `on_hireables_refreshed` | signal | Emitted at the end of `refresh_hireable_characters`. Listened to by [[hall_main#queue_refresh]] (connected at `hall_main.gd:433`). |
| `on_character_added` | signal | Emitted by `add_character_to_guild`. `GuildUpgrades` connects it to `sync_characters` ([[guild_upgrades#_ready]]). |
| `on_character_removed` | signal | Emitted by `remove_character_from_guild`. |

## Functions

### _ready
`func _ready() -> void` · `Globals/character_container.gd:29`

Engine callback. Rolls the first For Hire pool. The commented-out lines would have generated starting characters.

**Calls:** [[character_container#refresh_hireable_characters]].

### refresh_hireable_characters
`func refresh_hireable_characters() -> void` · `Globals/character_container.gd:37`

Replaces the For Hire pool. Sets `max_hireable_characters` by day (day 1: 2, days 2-3: 1, days 4-10: 2, later: 3). Fills the pool only when `GameState.standing > GuildUpgrades.MINIMUM_STANDING`. Otherwise the pool stays empty.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** clears and refills `hireable_characters`, writes `max_hireable_characters`, emits `on_hireables_refreshed`.

**Called by:** [[character_container#_ready]] (line 32), [[character_container#reset]] (line 93), [[game_state#start_new_day]] (`game_state.gd:38`), [[hall_debug#reroll_hires]] (`hall_debug.gd:120`), [[playtest_scenario#_ready]] (`playtest_scenario.gd:68`).

**Calls:** [[character_container#_add_new_recruits]], [[character_container#_add_returning_characters]].

### _add_new_recruits
`func _add_new_recruits() -> void` · `Globals/character_container.gd:59`

Adds `max_hireable_characters` new `GuildCharacter`s. Their stat points come from `HireScaling.recruit_budget(day, standing, active_characters)`. With chance `HireScaling.STANDOUT_CHANCE`, one random applicant gets `HireScaling.standout_budget(budget)`. Each recruit is rolled with `reroll_stats(points, HireScaling.deviation_for(points))`, and its `cost` is `HireScaling.recruit_cost(day, standing, points)`.

**Parameters:** none. Reads `GameState.day` and `GameState.standing`.

**Returns:** nothing.

**Side effects:** appends to `hireable_characters`.

**Called by:** [[character_container#refresh_hireable_characters]] (line 50).

**Calls:** [[hire_scaling#recruit_budget]], [[hire_scaling#standout_budget]], [[hire_scaling#deviation_for]], [[hire_scaling#recruit_cost]], [[character_resource#reroll_stats]].

### _add_returning_characters
`func _add_returning_characters() -> void` · `Globals/character_container.gd:77`

Each released hero rolls `RETURN_CHANCE`. Winners get `cost = max(GuildCharacter.recruit_cost_for_day(day), RETURN_MIN_COST) * RETURN_COST_MULTIPLIER` and are appended to the pool on top of the normal recruits. They stay in `released_characters` until hired.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** writes `cost` on the returning heroes, appends to `hireable_characters`.

**Called by:** [[character_container#refresh_hireable_characters]] (line 51).

**Calls:** [[character_resource#recruit_cost_for_day]].

### reset
`func reset() -> void` · `Globals/character_container.gd:89`

Empties the roster, For Hire and the released list for a new run, then rolls a fresh pool. Must run after `GameState.reset()` so the pool is sized for day 1.

**Returns:** nothing.

**Side effects:** clears the three arrays, refills the pool, emits `on_hireables_refreshed`.

**Called by:** [[hall_main#reset_autoloads]] (`hall_main.gd:1694`).

**Calls:** [[character_container#refresh_hireable_characters]].

### living_count
`func living_count() -> int` · `Globals/character_container.gd:98`

Number of heroes whose `injury_level < InjuryLevel.DEAD`. The dead stay on the roster so they can be revived, but they take no bed.

**Returns:** `int`. Used by [[hall_ledger#is_run_over]] and [[hall_ledger#is_one_death_from_falling]] for the Game Over checks, by [[tab_board#_show_recruits_box]], and by [[tab_guild#_show_section_buttons]] and [[tab_guild#_show_beds]] for bed counts.

**Called by:** [[character_container#has_free_bed]] (line 105), [[hall_ledger#is_run_over]] (`hall_ledger.gd:24`), [[hall_ledger#is_one_death_from_falling]] (`:37`), [[tab_board#_show_recruits_box]] (`tab_board.gd:79`), [[tab_guild#_show_section_buttons]] (`tab_guild.gd:110`), [[tab_guild#_show_beds]] (`tab_guild.gd:129`).

### has_free_bed
`func has_free_bed() -> bool` · `Globals/character_container.gd:104`

True when `living_count() < max_characters`.

**Returns:** `bool`. Used by hire/add/revive gates and the debug overlay.

**Called by:** [[character_container#generate_new_character]] (line 109), [[character_container#add_character_to_guild]] (line 119), [[guild_upgrades#revive]] (`guild_upgrades.gd:377`), [[hall_debug#add_hero]] (`hall_debug.gd:62`), [[hall_debug#heal_everyone]] (`:95`), [[hall_main#is_roster_full]] (`hall_main.gd:521`), [[overlay_debug#refresh]] (`overlay_debug.gd:147`).

**Calls:** [[character_container#living_count]].

### generate_new_character
`func generate_new_character() -> void` · `Globals/character_container.gd:108`

Creates a random `GuildCharacter` straight onto the roster if there is a free bed, and prints its name. No doc comment.

**Side effects:** appends to `active_characters`, prints. It doesn't emit `on_character_added` (which is why `GuildUpgrades._process` also re-syncs on roster size changes).

**Called by:** nothing found (the only mention is the `_ready` comment). See Suspected issues.

**Calls:** [[character_container#has_free_bed]].

### add_character_to_guild
`func add_character_to_guild(_character: GuildCharacter) -> bool` · `Globals/character_container.gd:118`

Hires a hero. Fails (returns false) when there's no free bed, or when the hero has a price (`cost > 0`) the wallet can't pay. If they cost anything, the price is paid with `GameState.add_gold(-cost)`. Then the hero joins the roster with `joined_on_day = GameState.day` and is erased from `hireable_characters` and `released_characters`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_character` | `GuildCharacter` | The hero to hire | the For Hire pick in [[hall_main#hire]] (`hall_main.gd:1089`), a fresh starting hero in [[hall_main#_add_starting_hero]] (`:490`), a new hero in [[hall_debug#add_hero]] (`hall_debug.gd:67`) |

**Returns:** `bool`. true when hired. Callers use it to decide whether the hire went through.

**Side effects:** spends gold, edits the three arrays, prints, emits `on_character_added`.

**Called by:** [[hall_main#hire]], [[hall_main#_add_starting_hero]], [[hall_debug#add_hero]].

**Calls:** [[character_container#has_free_bed]], [[game_state#add_gold]].

### remove_character_from_guild
`func remove_character_from_guild(_character: GuildCharacter) -> bool` · `Globals/character_container.gd:142`

Takes a hero off the roster for good: all their gear goes back to the pack (`ItemShop.unequip` on a copy of `equipped_items`), and they leave the Training Yard and the Hospital. Living heroes are added to `released_characters`. Leaving a quest party is the hall's job (see [[hall_main#release]]).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_character` | `GuildCharacter` | The hero to remove | the hero chosen in [[hall_main#release]] |

**Returns:** `bool`. false if they weren't on the roster.

**Side effects:** unequips items, ends training and hospital stay, edits arrays, prints, emits `on_character_removed`.

**Called by:** [[hall_main#release]] (`hall_main.gd:1133`).

**Calls:** [[item_shop#unequip]], [[guild_upgrades#stop_training]], [[guild_upgrades#discharge]].

## Suspected issues
- `Globals/character_container.gd:108` `generate_new_character` has no callers and no doc comment (dead code).
- `Globals/character_container.gd:33` the trailing `pass` is redundant.
