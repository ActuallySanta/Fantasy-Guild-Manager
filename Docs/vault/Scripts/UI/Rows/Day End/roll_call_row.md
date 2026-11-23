---
source: Scripts/UI/Rows/Day End/roll_call_row.gd
class_name: ""
extends: HBoxContainer
scene: "[[roll_call_row (scene)]]"
systems: ["[[Run End]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# roll_call_row.gd

## Purpose
One hero on the Game Over ledger's (and the credits') roll call: an icon for their fate (skull = fell, back arrow = released, heart = still on the roster), their name and role, and a line saying what became of them. Scene: [[roll_call_row (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TEXT_NAME`, `TEXT_FELL`, `TEXT_RELEASED`, `TEXT_REMAINS` | const | UI strings. |
| `TEXT_FELL_UNKNOWN` | const | "Fell in service": a fallen hero whose quest wasn't recorded (e.g. a playtest scenario's roster). |
| `_icon`, `_name`, `_fate` | onready | `%Icon`, `%Name`, `%Fate`. |

## Functions

### setup
`func setup(character: GuildCharacter, was_released: bool) -> void` · `Scripts/UI/Rows/Day End/roll_call_row.gd:23`

Fills the row. Dead: skull, Dead ink, "Fell at <quest>, Day N" (or "Fell in service" when `died_on_quest` or `died_on_day` is missing). Released: back arrow, soft ink. Otherwise: heart, green, "Still with the guild (<injury label>)".

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | loop over `heroes` in [[overlay_game_over#_show_roll_call]] and [[overlay_credits#_show_roll_call]] |
| `was_released` | `bool` | They were let go this run (living or not) | `released.has(character)` in the same loops |

**Returns:** nothing.

**Called by:** [[overlay_game_over#_show_roll_call]] (`overlay_game_over.gd:92`), [[overlay_credits#_show_roll_call]] (`overlay_credits.gd:220`).

**Calls:** [[hall_style#role_name]], [[hall_style#is_dead]], [[hall_style#injury_look]], [[hall_style#icon_texture]], [[hall_style#set_font_color]].

## Suspected issues
- A hero who is both dead and released shows as fallen (the dead branch is checked first); that matches the `was_released` doc ("living or not") only for the ink, not the text.
