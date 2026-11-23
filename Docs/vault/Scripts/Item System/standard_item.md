---
source: Scripts/Item System/standard_item.gd
class_name: StandardItem
extends: Resource
scene: null
systems: ["[[Items and Shop]]", "[[Economy and Wallet]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, resource]
---

# standard_item.gd

## Purpose
`StandardItem`: the abstract base of every item. It rolls a rarity (Legendary and Mythic odds come from the guild's standing rank, see `Docs/hall_design.md` "Gear rarity"), names the item for a hero role, and sets its cost. Items are role-locked: `role` says which hero role can wear it. [[passive_item]] (a stat bonus) and [[active_items]] extend it. Items live in [[item_container]] and are sold by [[item_shop]]. No scene.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `Rarity` | enum | `COMMON=35, UNCOMMON=25, RARE=20, LEGENDARY=15, MYTHIC=4, NAMED=1`. The values are saved, so they must not change. They are no longer used as roll weights. |
| `LOW_TIER_WEIGHTS` | const | Relative weights for the low tiers (Common 35, Uncommon 25, Rare 20). What Legendary and Mythic don't take is split between these. `NAMED` never rolls from the Shop or quests. |
| `LEGENDARY_PERCENT_BY_RANK` | const | `[0, 0, 1, 5, 5, 10]` percent by guild standing rank ([[hall_rules#standing_rank_for]]: F..S). Ranks past the end use the last entry. |
| `MYTHIC_PERCENT_BY_RANK` | const | `[0, 0, 0, 1, 2, 5]` percent by guild standing rank. |
| `name`, `description` | export var (String) | Display name (`"RARITY Title"`, set in `_init`) and description. |
| `mean_cost`, `max_cost_deviation` | export var (int) | Mean cost for the rarity, and the cost spread (default 50). |
| `icon` | export var (`Texture2D`) | Item icon. |
| `role` | export var (`GuildCharacter.CharacterRole`) | The role that can equip it. Callers set it again after construction (see [[passive_item#_init]]). |
| `total_rarity` | var (int) | 100. Not read in this file. |
| `rarity` | export var (`Rarity`) | The rolled rarity. |
| `initial_cost` | var | 250. The Common cost. |
| `rarity_cost_step` | var (float) | 0.4. Each rarity tier costs 40% more than the one below. |
| `cost_rounding` | var (int) | 50. Prices are rounded to a multiple of this (237 to 250). |
| `cost` | var (int) | Final price in gold. |
| `rarity_difficulty_shift` | var (float) | 0.3. How strongly quest difficulty pushes the low-tier roll toward Rare: each low tier's weight is multiplied by `1 + difficulty * tier * this`. |
| `curr_user` | var (`GuildCharacter`) | The hero wearing it, or null. Set by [[item_container]]. |

## Functions

### _init
`func _init(_role: GuildCharacter.CharacterRole, _difficulty: int = 0) -> void` · `Scripts/Item System/standard_item.gd:71`

Builds a new item for a hero role: sets `role`, rolls `rarity`, names it `"<RARITY> <title for role>"`, sets `mean_cost = round(250 * 1.4^tier)` and a `cost` drawn around it (`randfn`), snapped to 50 and at least 50. `curr_user` starts null.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_role` | `CharacterRole` | Role that can equip the item | random role in [[item_shop#_make_item]], [[hall_debug#add_random_item]], [[quest_resource#_roll_reward_items]]; the finder's role in [[quest_resource#_find_equipment]]; the saved role in the save loader |
| `_difficulty` | `int` | `QuestDifficulty` the item came from (0 for Shop stock) | `difficulty` in [[quest_resource]]; default 0 elsewhere |

**Returns:** nothing (constructor).

**Side effects:** consumes the RNG. Needs [[external_content_container]] loaded for the title.

**Called by:** [[passive_item#_init]] through `super._init(_role, _difficulty)` (`passive_item.gd:23`). `StandardItem` is abstract, so items are created through `PassiveItem.new(...)`.

**Calls:** [[standard_item#get_rarity]], [[external_content_container#get_item_title]].

### get_rarity
`func get_rarity(difficulty: int = 0) -> Rarity` · `Scripts/Item System/standard_item.gd:95`

Rolls a random rarity. Legendary and Mythic come first, at the flat chances for the guild's standing rank (so they are locked until C and B rank): one roll under `mythic_percent` is Mythic, then under `mythic + legendary` is Legendary. Otherwise a weighted pick among Common, Uncommon and Rare, where each tier's weight is `LOW_TIER_WEIGHTS * (1 + difficulty * tier_index * rarity_difficulty_shift)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `difficulty` | `int` | `QuestDifficulty` the item comes from (0 = no shift) | `_difficulty` of [[standard_item#_init]] |

**Returns:** the rolled `Rarity` (never `NAMED`), assigned to `rarity` in `_init`.

**Side effects:** consumes the RNG; reads `GameState.standing`.

**Called by:** [[standard_item#_init]] (`standard_item.gd:73`).

**Calls:** [[hall_rules#standing_rank_for]].

## Suspected issues
- `standard_item.gd:23` `total_rarity` is never read (the `Rarity` values no longer act as weights, per the comment at `:38`).
