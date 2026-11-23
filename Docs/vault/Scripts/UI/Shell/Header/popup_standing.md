---
source: Scripts/UI/Shell/Header/popup_standing.gd
class_name: ""
extends: HeaderPopup
scene: "[[popup_standing (scene)]]"
systems: ["[[Economy and Wallet]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# popup_standing.gd

## Purpose
The standing popup that drops from the header's shield ([[header_popup]]). It shows the guild's standing, which quest rank it brings, what standing is, and a two-way meter: the red half fills as standing nears the floor where recruits stop coming (`GuildUpgrades.MINIMUM_STANDING`), the green half fills toward the next milestone (a quest rank or a building level, from [[hall_wallet]]). A red note shows once standing is close to the floor. Scene: [[popup_standing (scene)]]. No `class_name`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TITLE`, `RANK_LINE`, `DESCRIPTION`, `LOSS_*`, `GAIN_*`, `MILESTONE_*`, `WARNING_*` | const | Text strings and formats (see the script's TEXT section). |
| `_title`, `_value`, `_rank`, `_description`, `_loss_bar`, `_gain_bar`, `_loss_*`, `_gain_*`, `_warning*`, `_mark` | var | `@onready` nodes by unique name, see [[popup_standing (scene)]]. |

## Functions

### _ready
`func _ready() -> void` · `Scripts/UI/Shell/Header/popup_standing.gd:51`

Called by the engine. Runs `super()` ([[header_popup#_ready]]), writes the fixed texts, colors the center mark, styles both bars and the labels, and styles the warning.

**Called by:** the engine. **Calls:** [[header_popup#_ready]], [[popup_standing#_style_bar]], [[hall_style#set_font_color]], [[hall_style#flat_box]].

### refresh
`func refresh() -> void` · `Scripts/UI/Shell/Header/popup_standing.gd:66`

Fills the card: the standing value and rank letter, the red half (room above the floor), the green half (progress to the next milestone and what it unlocks, or "Top"), and the warning.

**Returns:** nothing.

**Side effects:** sets label texts, `value` of `%LossBar` and `%GainBar`, and the warning's visibility.

**Called by:** [[header_popup#open]] (`header_popup.gd:72`), [[hall_header#refresh]] (`hall_header.gd:179`, while open).

**Calls:** [[hall_wallet#standing_rank_letter]], [[hall_wallet#standing_above_floor]], [[hall_wallet#loss_fill]], [[hall_wallet#next_standing_milestone]], [[hall_wallet#gain_fill]], [[popup_standing#_milestone_text]], [[hall_ledger#is_standing_near_floor]], [[hall_style#count_text]].

### _milestone_text
`func _milestone_text(milestone: Dictionary) -> String` · `Scripts/UI/Shell/Header/popup_standing.gd:91`

What a milestone from `HallWallet.standing_milestones` unlocks, in words.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `milestone` | `Dictionary` | `kind` (`rank_appears`, `rank` or a building level) and `value`, plus `at` | `next` from [[hall_wallet#next_standing_milestone]] in [[popup_standing#refresh]] |

**Returns:** `String`, e.g. "Rank B quests appear". Used as the green half's caption.

**Called by:** [[popup_standing#refresh]] (`popup_standing.gd:81`). **Calls:** [[hall_wallet#rank_name]].

### _style_bar
`func _style_bar(bar: ProgressBar, fill: Color) -> void` · `Scripts/UI/Shell/Header/popup_standing.gd:102`

A meter half: a parchment track with a solid `fill` color, range 0..1, no percentage text.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `bar` | `ProgressBar` | `%LossBar` or `%GainBar` | [[popup_standing#_ready]] |
| `fill` | `Color` | Fill color | `HallStyle.RED` / `HallStyle.GREEN` |

**Called by:** [[popup_standing#_ready]] (`popup_standing.gd:56`, `:57`). **Calls:** [[hall_style#flat_box]].

## Suspected issues
- None found.
