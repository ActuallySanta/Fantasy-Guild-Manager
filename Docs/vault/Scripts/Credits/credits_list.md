---
source: Scripts/Credits/credits_list.gd
class_name: CreditsList
extends: Resource
scene: null
systems: ["[[Run End]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# credits_list.gd

## Purpose
`CreditsList`: the team credits shown at the end of the final battle's credits roll ([[overlay_credits]]), for both the victory and the defeat versions. Data: `Data/credits.tres`, loaded by `TEAM_CREDITS` in [[overlay_credits]] (`overlay_credits.gd:21`). To add credits (no code): open `Data/credits.tres`, expand Entries, Add Element, choose "New CreditEntry" ([[credit_entry]]), fill Section, Name and Contribution, reorder by dragging (sections appear in the order their first entry appears), save. See it by winning or losing the final battle, or running `Scenes/Playtest/scenario_final_battle.tscn`.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `entries` | `@export var Array[CreditEntry]` | Every credited person, in on-screen order. |

## Functions

### sections
`func sections() -> Array` · `Scripts/Credits/credits_list.gd:25`

The entries grouped by section, keeping the order each section first appears in. Entries that are null or have an empty name (after `strip_edges`) are skipped, so a half-filled slot never shows a blank line.

**Returns:** `Array` of `{section: String, entries: Array[CreditEntry]}`. [[overlay_credits#_show_team]] reads it (`overlay_credits.gd:229`, `[]` if `TEAM_CREDITS` is null) to build the team credits page.

**Side effects:** none.

**Called by:** [[overlay_credits#_show_team]] (`overlay_credits.gd:229`).

**Calls:** nothing.

## Suspected issues
- None found.
