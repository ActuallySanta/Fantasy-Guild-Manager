---
source: Scripts/Credits/credit_entry.gd
class_name: CreditEntry
extends: Resource
scene: null
systems: ["[[Run End]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# credit_entry.gd

## Purpose
`CreditEntry`: one line of the team credits at the end of the story ([[overlay_credits]]). A `Resource` that lives inside [[credits_list]]`.entries`; edit it in the Godot inspector (data in `Data/credits.tres`). No functions.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `section` | `@export var String` | The heading this person is listed under ("Programming", "Art", "Special Thanks"). Entries with the same section show together under one heading. |
| `name` | `@export var String` | The person's (or group's) name as shown on screen. |
| `contribution` | `@export_multiline var String` | What they did, shown under the name; empty for a name-only line. |

## Functions
None.

## Suspected issues
- None found.
