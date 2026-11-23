---
source: Scripts/UI/Components/stat_tile.gd
class_name: ""
extends: PanelContainer
scene: "[[stat_tile (scene)]]"
systems: ["[[Run End]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# stat_tile.gd

## Purpose
One number in an ink box with a caption under it ("1240" / "gold earned"). Used on the Game Over ledger's and the credits' stat grids and for their big Days tile. Scene: [[stat_tile (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `_value`, `_caption` | onready | `%Value`, `%Caption` (Labels). |

## Functions

### setup
`func setup(value_text: String, caption_text: String, ink: Color, value_font_size: int = 0) -> void` · `Scripts/UI/Components/stat_tile.gd:14`

Writes the number and caption, inks the number and tints the box outline with `ink`; a non-zero `value_font_size` overrides the scene's size (grown by the font scale).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `value_text` | `String` | The big number or word | `str(stats.gold_earned)` etc. from the run stats in [[overlay_game_over#_show_tiles]] and [[overlay_credits#_show_stats]] / [[overlay_credits#_show_records]] |
| `caption_text` | `String` | What it counts | the overlays' `TEXT_*_CAPTION` constants |
| `ink` | `Color` | Box outline and number colour | e.g. `HallStyle.GOLD_TEXT`, `HallStyle.RED` |
| `value_font_size` | `int` | 0 keeps the scene's size | `DAYS_FONT_SIZE` for the Days tile, else 0 |

**Returns:** nothing.

**Called by:** [[overlay_game_over#_show_tiles]] (`overlay_game_over.gd:68`, `70`-`76`, `81`, `83`, `85`), [[overlay_credits#_show_stats]] (`overlay_credits.gd:190`-`197`), [[overlay_credits#_show_records]] (`overlay_credits.gd:202`, `203`, `206`, `208`).

**Calls:** [[hall_style#set_font_color]], [[hall_style#tint_art]], [[hall_font_scale#set_size]].

## Suspected issues
- None found.
