---
source: Globals/game_state.gd
class_name: null
extends: Node
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, autoload]
---

# game_state.gd

## Purpose
Autoload `GameState`. Holds the day counter and the freeplay flag, and forwards `gold` and `standing` to `GuildUpgrades` (the real wallet). `start_new_day` is where a new day begins: the hire pool refreshes, temp stats rebuild, and `day_started` fires for other systems (for example `ItemShop` restocks).

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `day_started` | signal | `day_started(day: int)`. Emitted after the day number goes up. [[item_shop#_on_day_started]] listens (`item_shop.gd:37`). |
| `resources_changed` | signal | Re-emitted from `GuildUpgrades.resources_changed` (connected in `_ready`). |
| `day` | var (int) | The current day, starts at 1. The getter just returns it. |
| `gold` | var (int) | Read-only view of `GuildUpgrades.gold`. |
| `standing` | var (int) | Read-only view of `GuildUpgrades.standing`. |
| `is_freeplay` | var (bool) | True once the main story is over and the player chose Begin Freeplay (`HallMain.start_freeplay`). Days go on forever and quests keep scaling. |

## Functions

### _ready
`func _ready() -> void` · `Globals/game_state.gd:29`

Engine callback. Connects `GuildUpgrades.resources_changed` to this node's `resources_changed`.

### start_new_day
`func start_new_day() -> void` · `Globals/game_state.gd:34`

Adds 1 to `day`, refreshes the For Hire pool, rebuilds every hero's temp stats, then emits `day_started(day)`.

**Returns:** nothing.

**Side effects:** changes `day`, the hire pool, hero `temp_stats`, emits `day_started`.

**Called by:** [[hall_main#start_new_day]] (`hall_main.gd:1634`).

**Calls:** [[character_container#refresh_hireable_characters]], [[game_state#_refresh_temp_stats]].

### reset
`func reset() -> void` · `Globals/game_state.gd:47`

Back to day 1 and `is_freeplay = false` for a new run. It doesn't emit `day_started`: the hall scene is reloaded right after and builds day 1 itself.

**Called by:** [[hall_main#reset_autoloads]] (`hall_main.gd:1689`).

### _refresh_temp_stats
`func _refresh_temp_stats()` · `Globals/game_state.gd:52`

Calls `reset_temp_stats()` on every hero in `CharacterContainer.active_characters`. No return type is declared.

**Called by:** [[game_state#start_new_day]] (line 40).

**Calls:** [[character_resource#reset_temp_stats]].

### add_gold
`func add_gold(amount: int) -> void` · `Globals/game_state.gd:57`

Forwards to `GuildUpgrades.add_gold`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `amount` | `int` | Gold to add (negative spends) | hero price in [[character_container#add_character_to_guild]]; quest payout in [[hall_rules#play_quest]] (`hall_rules.gd:372`) |

**Called by:** [[character_container#add_character_to_guild]] (`character_container.gd:124`), [[hall_rules#play_quest]] (`hall_rules.gd:372`).

**Calls:** [[guild_upgrades#add_gold]].

### add_standing
`func add_standing(amount: int) -> void` · `Globals/game_state.gd:61`

Forwards to `GuildUpgrades.add_standing`. `amount` is the standing earned by a quest, from [[hall_rules#play_quest]] (`hall_rules.gd:373`).

**Called by:** [[hall_rules#play_quest]] (`hall_rules.gd:373`).

**Calls:** [[guild_upgrades#add_standing]].

### reduce_standing
`func reduce_standing(amount: int) -> void` · `Globals/game_state.gd:65`

Forwards to `GuildUpgrades.reduce_standing`. `amount` is a standing penalty chosen by the hall.

**Called by:** [[hall_main#deny_quest]] (`hall_main.gd:1013`), [[hall_main#release]] (`hall_main.gd:1137`).

**Calls:** [[guild_upgrades#reduce_standing]].

## Suspected issues
- `Globals/game_state.gd:37` `CharacterContainer.has_method("refresh_hireable_characters")` is always true (a leftover check).
- `day`, `gold`, `standing` and the signals have plain `#` comments, not `##`.
