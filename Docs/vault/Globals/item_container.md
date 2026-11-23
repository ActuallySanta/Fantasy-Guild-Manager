---
source: Globals/item_container.gd
class_name: null
extends: Node
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, autoload]
---

# item_container.gd

## Purpose
Autoload `ItemContainer`. Holds every owned item (`owned_items`) and does the raw link between an item and its wearer (`curr_user` and `equipped_items`). It checks no rules (role, slot cap). `ItemShop` does that, then calls this.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `owned_items` | var (`Array[StandardItem]`) | Every item the guild owns, worn or not. `ItemShop.buy` appends to it. |

## Functions

### _ready
`func _ready() -> void` · `Globals/item_container.gd:7`

Engine callback. Empty (`pass`).

### give_item_to_character
`func give_item_to_character(_item: StandardItem, _character: GuildCharacter) -> void` · `Globals/item_container.gd:11`

Moves an item onto a hero. If someone else already wears it, they lose it first. Then it's appended to the hero's `equipped_items` and `curr_user` is set.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_item` | `StandardItem` | Item to equip | `item` of [[item_shop#equip]] |
| `_character` | `GuildCharacter` | New wearer | `character` of [[item_shop#equip]] |

**Returns:** nothing.

**Side effects:** edits `equipped_items` and `curr_user`. Doesn't rebuild temp stats (the caller does).

**Called by:** [[item_shop#equip]] (`item_shop.gd:146`).

**Calls:** [[item_container#remove_item_from_character]].

### remove_item_from_character
`func remove_item_from_character(_item: StandardItem, _character: GuildCharacter) -> bool` · `Globals/item_container.gd:19`

Removes an item from a hero's `equipped_items` and clears `curr_user`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_item` | `StandardItem` | Item to take off | as above |
| `_character` | `GuildCharacter` | The wearer | `item.curr_user` in [[item_shop#unequip]] and [[item_container#give_item_to_character]] |

**Returns:** `bool`. false if the hero wasn't wearing it. Neither caller reads it.

**Called by:** [[item_container#give_item_to_character]] (line 13), [[item_shop#unequip]] (`item_shop.gd:160`).

## Suspected issues
- `Globals/item_container.gd:26` unreachable `return false` after the if/else.
- No `##` doc comments on any function.
