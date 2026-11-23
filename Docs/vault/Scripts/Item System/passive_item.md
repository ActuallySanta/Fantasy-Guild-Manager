---
source: Scripts/Item System/passive_item.gd
class_name: PassiveItem
extends: StandardItem
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, resource]
---

# passive_item.gd

## Purpose
`PassiveItem`: an item that adds a flat bonus to one hero stat while worn. This is the only concrete item type the game creates. The shop ([[item_shop#_make_item]]), quest loot ([[quest_resource#_find_equipment]], [[quest_resource#_roll_reward_items]]), the debug tools and the save loader all construct it. The bonus is applied through the wearer's temp stats ([[character_resource#add_passive_item_stats]]), never to `stats`. Base class: [[standard_item]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `affected_stat` | export var (`GuildCharacter.StatType`) | The stat it raises. Random in `_init`. |
| `stat_amount` | export var (int) | Points added. From `stat_addition_table[rarity]`. |
| `stat_addition_table` | var (`Dictionary[Rarity, int]`) | Points by rarity: Common 2, Uncommon 4, Rare 6, Legendary 8, Mythic 10, Named 12. |

## Functions

### _init
`func _init(_role: GuildCharacter.CharacterRole, _difficulty: int = 0) -> void` · `Scripts/Item System/passive_item.gd:22`

Builds a passive stat item for a hero role. It runs [[standard_item#_init]] (rarity, name, cost), then picks a random `affected_stat` and sets `stat_amount` from the rarity.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_role` | `CharacterRole` | Role that can equip the item | random role in [[item_shop#_make_item]] (`item_shop.gd:66`) and [[hall_debug#add_random_item]] (`hall_debug.gd:76`); the finder's role in [[quest_resource#_find_equipment]] (`quest_resource.gd:732`); a random role in [[quest_resource#_roll_reward_items]] (`quest_resource.gd:793`); the saved `role` field in the `RefReader` inner class of [[hall_save]] (`hall_save.gd:465`) |
| `_difficulty` | `int` | `QuestDifficulty` the item was found on (0 for Shop stock), so harder quests roll better rarities | `difficulty` in the two quest callers; default 0 elsewhere |

**Returns:** nothing (constructor).

**Side effects:** consumes the RNG.

**Called by:** `PassiveItem.new(...)` in [[item_shop#_make_item]] (`item_shop.gd:66`), [[hall_debug#add_random_item]] (`hall_debug.gd:76`), [[quest_resource#_find_equipment]] (`quest_resource.gd:732`), [[quest_resource#_roll_reward_items]] (`quest_resource.gd:793`), the `RefReader` inner class of [[hall_save]] (`hall_save.gd:465`; fields are overwritten after).

**Calls:** [[standard_item#_init]] (`super._init`, `passive_item.gd:23`).

## Suspected issues
- `passive_item.gd:22` `StandardItem._init` already sets `role = _role`, so the "set `item.role` again" comments in `item_shop.gd`, `hall_debug.gd` and `quest_resource.gd` look stale (`item_shop.gd:67` says `_init` "doesn't store the role"). Harmless.
