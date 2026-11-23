---
source: Scripts/Item System/active_items.gd
class_name: ActiveItem
extends: StandardItem
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, resource]
---

# active_items.gd

## Purpose
`ActiveItem`: an abstract item type with limited uses (`@abstract class_name ActiveItem extends StandardItem`). It is a stub. Nothing extends it and nothing calls it, so it isn't used by the game today (Grep of `Globals/`, `Scripts/`, `Scenes/`). Base class: [[standard_item]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `max_uses` | export var (int) | Uses left. Decremented by [[active_items#use_item]]. |
| `on_item_used` | signal | Emitted by `use_item`. No `on_item_used.connect` found in `Globals/`, `Scripts/` or `Scenes/`, so no listeners. |

## Functions

### use_item
`func use_item() -> void` · `Scripts/Item System/active_items.gd:7`

Spends one use (`max_uses -= 1`) and emits `on_item_used`.

**Parameters:** none.

**Returns:** nothing.

**Side effects:** changes `max_uses`; emits `on_item_used`.

**Called by:** nothing found.

**Calls:** none.

## Suspected issues
- `active_items.gd:7` `use_item` has no callers, and no script extends `ActiveItem`. Unused stub. It doesn't stop at 0 uses.
