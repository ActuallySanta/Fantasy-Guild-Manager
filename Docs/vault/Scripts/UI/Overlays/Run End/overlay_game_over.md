---
source: Scripts/UI/Overlays/Run End/overlay_game_over.gd
class_name: ""
extends: Control
scene: "[[overlay_game_over (scene)]]"
systems: ["[[Run End]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_game_over.gd

## Purpose
The Game Over guild ledger, shown when nobody is left alive and no recruit can ever be afforded (`HallMain.is_run_over`). A big Days tile, a 2 x 3 grid of the run's numbers (plus the Bone Drake tile), a roll call of every hero and what became of them, and the "Found a New Guild" button. Reads `hall.run_over_stats` ([[hall_main#build_run_over_stats]]). Scene: [[overlay_game_over (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `RollCallRowScene` | preload | `Scenes/Rows/Day End/roll_call_row.tscn` ([[roll_call_row (scene)]]). |
| `DAYS_FONT_SIZE` | const | Font size of the number on the big Days tile (the other tiles keep the scene's). |
| `TEXT_*` | const | Captions and strings. `TEXT_DRAKE_UNMET` shows in the Drake tile when the run ended before the milestone quest went out. |
| `_days_tile`, `_gold_tile`, `_quests_tile`, `_hired_tile`, `_fallen_tile`, `_standing_tile`, `_drake_tile` | onready | [[stat_tile]] nodes (`%DaysTile` ... `%DrakeTile`). |
| `_roll_call`, `_empty_label`, `_scroll`, `_new_run_button` | onready | `%RollCall`, `%Empty`, `%Scroll`, `%NewRunButton`. |
| `hall` | var | The [[hall_main]] node. |
| `_built_stats` | var | The stats currently on screen. They are frozen once the run ends, so the ledger is built once. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Run End/overlay_game_over.gd:48`

Stores the hall, connects `pressed` on `%NewRunButton` to [[hall_main#start_new_run]], styles it gold (size 46).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in `view.setup(self)` ([[hall_main#_ready]], `hall_main.gd:427`) |

**Returns:** nothing.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_style#style_button]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Run End/overlay_game_over.gd:54`

Builds the ledger from `hall.run_over_stats`. Does nothing if the stats are empty or equal to `_built_stats`. Scrolls back to the top.

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1891`) while visible (the overlay is shown when `run_over_stats` is non-empty and no credits are open, `hall_main.gd:1876-1852`).

**Calls:** [[overlay_game_over#_show_tiles]], [[overlay_game_over#_show_roll_call]].

### _show_tiles
`func _show_tiles(stats: Dictionary) -> void` · `Scripts/UI/Overlays/Run End/overlay_game_over.gd:65`

Fills the Days tile and the grid of the run's numbers. Days caption is singular for 1. Fallen uses the dead-injury ink, negative standing is red. The Drake tile shows the result in green (slain), red (lost) or soft "Unmet" (`HallMain.DRAKE_RESULT_SLAIN` / `DRAKE_RESULT_LOST`).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `stats` | `Dictionary` | `hall.run_over_stats` (keys `days`, `gold_earned`, `quests_won`, `quests_sent`, `heroes_hired`, `fallen`, `standing`, `drake_result`) | [[overlay_game_over#refresh]] |

**Called by:** [[overlay_game_over#refresh]] (`:59`).

**Calls:** [[stat_tile#setup]] (`stat_tile.gd:14`).

### _show_roll_call
`func _show_roll_call(heroes: Array, released: Array) -> void` · `Scripts/UI/Overlays/Run End/overlay_game_over.gd:89`

Clears `%RollCall` and adds one [[roll_call_row (scene)]] per hero (already in roll-call order); shows "No hero ever joined this guild." if empty.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `heroes` | `Array` | Every hero ever in the guild | `stats.roll_call` in [[overlay_game_over#refresh]] |
| `released` | `Array` | Those who were released | `stats.released` |

**Called by:** [[overlay_game_over#refresh]] (`:60`).

**Calls:** [[hall_style#clear_children]], [[hall_style#add_row]], [[roll_call_row#setup]] (`roll_call_row.gd:23`).

## Suspected issues
- None found.
