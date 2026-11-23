---
source: Scripts/Playtest/playtest_scenario.gd
extends: Control
scene: "[[scenario_final_battle (scene)]]"
systems: ["[[Playtest Bridge]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# playtest_scenario.gd

## Purpose
Playtest scenario loader. Puts the game into a set state (day, standing, gold, a small hurt roster, optional dead heroes), then the `HallMain` child starts from there. It only sets values on the autoloads (`GameState`, `GuildUpgrades`, `CharacterContainer`). Used by the four scenes [[scenario_final_battle (scene)]], [[scenario_game_over (scene)]], [[scenario_low_standing (scene)]] and [[scenario_milestone_day (scene)]]; run one with F6. Day, gold and standing are set in `_enter_tree` (before the hall's `_ready`), the roster in `_ready` (the autoloads must be ready for `GuildCharacter.new()`).

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `start_day` | export var | Day to start on (default 8). 10 = Bone Drake day, `HallMain.FINAL_DAY` (50) = final battle. |
| `start_standing` | export var | Guild standing (default -10 = `GuildUpgrades.MINIMUM_STANDING`; nobody new shows up For Hire). |
| `start_gold` | export var | Starting gold (default 120). |
| `member_injuries` | export var | One injury level (0-3) per living hero (default [2, 3]). |
| `fallen_members` | export var | Number of dead heroes added for the Game Over roll call (default 0). |
| `show_welcome` | export var | Show the welcome card at the start (default true). |
| `intro_toast` | export var | Toast shown on load ("" = none). |
| `FALLEN_QUEST_NAME` | const | Where the fallen heroes "died": `"a playtest skirmish"`. |
| `_hall` | onready var | The `HallMain` child. |

## Functions

### _enter_tree
`func _enter_tree() -> void` · `Scripts/Playtest/playtest_scenario.gd:44`

Sets `GameState.day`, resets `GuildUpgrades`, then sets its gold and standing from the exports. Called by the engine, before the `HallMain` child's `_ready`, so the hall builds the day's quests from this state.

**Side effects:** changes `GameState.day`, `GuildUpgrades.gold` and `standing`.

**Calls:** [[guild_upgrades#reset]].

### _ready
`func _ready() -> void` · `Scripts/Playtest/playtest_scenario.gd:51`

Called by the engine. Clears `CharacterContainer.active_characters` and `released_characters`, builds one `GuildCharacter` per `member_injuries` entry (injury clamped to 0..GRAVELY_INJURED, `injury_count` set to match) and `fallen_members` dead ones (`died_on_day` = start_day - 1, min 1). Re-rolls the For Hire pool, syncs characters, sets `hall.is_welcome_open`, shows the toast and queues a refresh.

**Side effects:** replaces the roster, changes the hire pool, toast, hall refresh.

**Calls:** [[character_container#refresh_hireable_characters]], [[guild_upgrades#sync_characters]], [[hall_main#show_toast]], [[hall_main#queue_refresh]].

## Suspected issues
- None found. (The `-10` for `MINIMUM_STANDING` in the comment was not re-checked against `guild_upgrades.gd`.)
