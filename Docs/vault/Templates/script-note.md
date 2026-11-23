---
source: Scripts/Folder/file_name.gd
class_name: ClassName
extends: Node
scene: "[[file_name (scene)]]"
systems: ["[[System Name]]"]
last_verified: <commit hash>
tags: [script]
---

# file_name.gd

## Purpose
2-4 lines: the script's one job, who uses it, and its scene (if any). Start from the class `##` doc comment.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `CONSTANT_NAME` | const | From its `##` comment. Link to systems it tunes. |
| `_member` | var | What it holds and who changes it. |
| `something_changed` | signal | When it's emitted, its args, who listens. |

## Functions

### function_name
`static func function_name(day: int, roster: Array) -> int` · `Scripts/Folder/file_name.gd:42`

Start from the function's `##` doc comment and tidy it into 1-3 lines.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | The current day | `GameState.day` in [[hall_main#_generate_quests]] |

**Returns:** `int`, meaning … (special values: -1 when …). Used by [[caller#func]] to …

**Side effects:** none / changes `GuildUpgrades.gold` / emits `day_started` / starts a tween.

**Called by:** [[other_script#caller_function]] (`other_script.gd:120`), signal `pressed` on `%HireButton`.

**Calls:** [[hall_rules#standing_rank_for]], [[guild_upgrades#get_stat_bonus]].

> [!note] How it works
> Only when the logic isn't obvious.

## Suspected issues
- Doc comment and code disagree, dead code, and so on. Reported only, never fixed.
