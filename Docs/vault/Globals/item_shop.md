---
source: Globals/item_shop.gd
class_name: null
extends: Node
scene: null
systems: ["[[Boot and Autoload Order]]", "[[Day Cycle]]", "[[Success Chance]]", "[[Items and Shop]]", "[[Economy and Wallet]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script, autoload]
---

# item_shop.gd

## Purpose
Autoload `ItemShop`. The Shop tab's stock, and the glue between the Item-System scripts (`StandardItem`, `PassiveItem`, `ItemContainer`) and heroes. It generates `STOCK_SIZE` PassiveItems and rerolls them every dawn (`GameState.day_started`). Buying pays from the `GuildUpgrades` wallet and moves the item to `ItemContainer.owned_items`. Equipping is role-locked and capped by `character.max_items`, goes through `ItemContainer`, then rebuilds the hero's `temp_stats`. Gear never touches `stats`. The UI reaches it through `hall_main.gd` (`buy_item` / `equip_item` / `unequip_item`), which shows the toasts.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `stock_changed` | signal | The stock was rerolled or something was bought. |
| `gear_changed` | signal | An item was put on or taken off a hero. |
| `EquipResult` | enum | `OK, NOT_OWNED, ALREADY_ON, WRONG_ROLE, SLOTS_FULL, DEAD`. The outcome of `can_equip` and `equip`. |
| `UNLOCK_DAY` | const | The day the Items tab (Pack + Shop) opens (5). Locked before this whether or not the tutorial is on. |
| `STOCK_SIZE` | const | Goods on the counter each day (6, the Shop tab's 3 x 2 grid). |
| `APPLIED_META` | const | Item metadata key `"item_bonus_applied"`: `Vector2i(stat, amount)` this item added to its wearer. |
| `stock` | var (`Array[Dictionary]`) | Today's goods: `[{"item": StandardItem, "sold": bool}, ...]`. |

## Functions

### _ready
`func _ready() -> void` · `Globals/item_shop.gd:36`

Engine callback. Connects `GameState.day_started` to `_on_day_started` and defers `_first_restock` so the other autoloads (`ExternalContentContainer` names items) are ready.

**Calls:** [[item_shop#_on_day_started]] (as a connection), [[item_shop#_first_restock]].

### _first_restock
`func _first_restock() -> void` · `Globals/item_shop.gd:45`

The opening stock. A saved run (`HallSave.load_run`, in `HallMain._ready`) has already put its own stock on the counter by the time this deferred call runs, so it only rolls when `stock` is empty.

**Called by:** `_ready` (deferred, line 39).

**Calls:** [[item_shop#restock]].

### _on_day_started
`func _on_day_started(_day: int) -> void` · `Globals/item_shop.gd:50`

Rerolls the stock on a new day.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `_day` | `int` | The new day (unused) | `day_started(day)` from [[game_state#start_new_day]] |

**Called by:** signal `GameState.day_started` (connected at line 37).

**Calls:** [[item_shop#restock]].

### restock
`func restock() -> void` · `Globals/item_shop.gd:57`

Fresh goods on the counter (yesterday's unsold goods are gone): clears `stock` and adds `STOCK_SIZE` entries from `_make_item`.

**Side effects:** rewrites `stock`, emits `stock_changed`.

**Called by:** [[item_shop#_first_restock]] (line 47), [[item_shop#_on_day_started]] (line 51), [[hall_main#reset_autoloads]] (`hall_main.gd:1717`).

**Calls:** [[item_shop#_make_item]].

### _make_item
`func _make_item() -> StandardItem` · `Globals/item_shop.gd:64`

Makes a `PassiveItem` for a random role and stores that role on it (`StandardItem._init` names the item for the role but doesn't keep it, and equipping is role-locked).

**Returns:** `StandardItem`. Put in `stock` by [[item_shop#restock]].

**Called by:** [[item_shop#restock]] (line 60).

### get_item
`func get_item(index: int) -> StandardItem` · `Globals/item_shop.gd:73`

The item at that stock slot, or null when `index` is out of range.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `index` | `int` | Slot in `stock` (0-5) | the card index in [[tab_shop#_show_goods]] and [[tab_shop#_show_buy_bar]], the action argument in [[hall_main#buy_item]] |

**Returns:** `StandardItem` or null.

**Called by:** [[item_shop#can_buy]] (line 88), [[item_shop#buy]] (line 95), [[hall_main#buy_item]] (`hall_main.gd:1183`), [[hall_wallet#cheapest_gear_price]] (`hall_wallet.gd:135`), [[agent_bridge_actions#_buy]] (`:135`), [[agent_bridge_state#_shop]] (`:107`), [[tab_shop#_show_goods]] (`tab_shop.gd:81`), [[tab_shop#_show_buy_bar]] (`:110`).

### is_sold
`func is_sold(index: int) -> bool` · `Globals/item_shop.gd:79`

True when the slot exists and its `sold` flag is set. Out-of-range counts as not sold.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `index` | `int` | Slot in `stock` | as for `get_item` |

**Returns:** `bool`. Callers hide or grey out sold cards.

**Called by:** [[item_shop#can_buy]] (line 89), [[hall_main#buy_item]] (`hall_main.gd:1184`), [[hall_wallet#cheapest_gear_price]] (`:133`), [[agent_bridge_actions#_buy]] (`:137`, `:140`), [[agent_bridge_state#_shop]] (`:115`), [[tab_items#_unsold_count]] (`tab_items.gd:85`), [[tab_shop#_show_goods]] (`tab_shop.gd:89`), [[tab_shop#_show_buy_bar]] (`:117`).

### can_afford
`func can_afford(item: StandardItem) -> bool` · `Globals/item_shop.gd:83`

`GuildUpgrades.gold >= item.cost`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item to price | `get_item(index)` |

**Called by:** [[item_shop#can_buy]] (line 89), [[tab_shop#_show_buy_bar]] (`tab_shop.gd:120`).

### can_buy
`func can_buy(index: int) -> bool` · `Globals/item_shop.gd:87`

True when the slot has an item, it isn't sold and the guild can afford it.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `index` | `int` | Slot in `stock` | the selected card |

**Called by:** [[item_shop#buy]] (line 93), [[overlay_tutorial#_any_affordable]] (`overlay_tutorial.gd:961`), [[tab_shop#_show_buy_bar]] (`tab_shop.gd:124`).

**Calls:** [[item_shop#get_item]], [[item_shop#is_sold]], [[item_shop#can_afford]].

### buy
`func buy(index: int) -> bool` · `Globals/item_shop.gd:92`

Buys a stock item: takes `item.cost` gold, appends the item to `ItemContainer.owned_items`, marks the slot sold.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `index` | `int` | Slot in `stock` | the item chosen in [[hall_main#buy_item]] |

**Returns:** `bool`. false if `can_buy` fails. [[hall_main#buy_item]] uses it to show a toast and play the sound.

**Side effects:** `GuildUpgrades.add_gold(-cost)` (which emits `resources_changed`), changes `owned_items`, `stock`, emits `stock_changed`.

**Called by:** [[hall_main#buy_item]] (`hall_main.gd:1187`).

**Calls:** [[item_shop#can_buy]], [[item_shop#get_item]], [[guild_upgrades#add_gold]].

### items_for
`func items_for(character: GuildCharacter) -> Array[StandardItem]` · `Globals/item_shop.gd:107`

Owned items this hero could wear: same role and not already on them. Items worn by someone else are included (equipping moves them).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | the hero shown on [[screen_character#_show_gear]] |

**Returns:** `Array[StandardItem]`. [[screen_character#_show_gear]] lists them.

**Called by:** [[screen_character#_show_gear]] (`screen_character.gd:291`).

### unworn_count
`func unworn_count() -> int` · `Globals/item_shop.gd:116`

How many owned items have no wearer (`curr_user == null`).

**Returns:** `int`. [[tab_pack#_show_grid]] and [[tab_shop#_show_restock_note]] show it.

**Called by:** [[tab_pack#_show_grid]] (`tab_pack.gd:137`), [[tab_shop#_show_restock_note]] (`tab_shop.gd:103`).

### can_equip
`func can_equip(item: StandardItem, character: GuildCharacter) -> EquipResult` · `Globals/item_shop.gd:124`

Checks in order: owned (`NOT_OWNED`), already on this hero (`ALREADY_ON`), hero dead (`DEAD`), role mismatch (`WRONG_ROLE`), slots full (`equipped_items.size() >= max_items`, `SLOTS_FULL`), else `OK`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item | passed through from [[item_shop#equip]] |
| `character` | `GuildCharacter` | The hero | passed through |

**Returns:** `EquipResult`. Used by [[item_shop#equip]].

**Called by:** [[item_shop#equip]] (line 139).

### equip
`func equip(item: StandardItem, character: GuildCharacter) -> EquipResult` · `Globals/item_shop.gd:138`

Equips if `can_equip` is `OK`. If the item is on another hero, its bonus metadata is removed first. Then `ItemContainer.give_item_to_character`, `_apply_bonus`, and `reset_temp_stats()` on the old and new wearer.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The item | the pick in [[hall_main#equip_item]] / [[hall_main#swap_gear]] |
| `character` | `GuildCharacter` | New wearer | the hero on the screen |

**Returns:** `EquipResult`. Any value other than `OK` means nothing changed. The hall uses it to choose a toast.

**Side effects:** changes `equipped_items`, `curr_user`, item metadata, both heroes' `temp_stats`, emits `gear_changed`.

**Called by:** [[hall_main#equip_item]] (`hall_main.gd:1203`), [[hall_main#swap_gear]] (`:1238`, `:1239`).

**Calls:** [[item_shop#can_equip]], [[item_shop#_remove_bonus]], [[item_container#give_item_to_character]], [[item_shop#_apply_bonus]], [[character_resource#reset_temp_stats]].

### unequip
`func unequip(item: StandardItem) -> void` · `Globals/item_shop.gd:155`

Takes the item off its wearer (does nothing if nobody wears it), drops its bonus metadata and rebuilds their temp stats.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `item` | `StandardItem` | The worn item | the gear row in [[hall_main#unequip_item]], each item of a leaving hero in [[character_container#remove_character_from_guild]] |

**Side effects:** emits `gear_changed`.

**Called by:** [[character_container#remove_character_from_guild]] (`character_container.gd:156`), [[hall_main#unequip_item]] (`hall_main.gd:1223`), [[hall_main#swap_gear]] (`:1237`).

**Calls:** [[item_shop#_remove_bonus]], [[item_container#remove_item_from_character]], [[character_resource#reset_temp_stats]].

### get_item_bonus
`func get_item_bonus(character: GuildCharacter, stat: int) -> int` · `Globals/item_shop.gd:166`

How much of a hero's stat comes from gear (it lives in `temp_stats`), summed from each equipped item's `APPLIED_META`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `GuildCharacter` | The hero | shown hero in [[screen_character#_show_stats]] |
| `stat` | `int` | A `GuildCharacter.StatType` | the stat row being drawn |

**Returns:** `int`. Shown beside the stat as the gear part.

**Called by:** [[screen_character#_show_stats]] (`screen_character.gd:222`).

### _apply_bonus
`func _apply_bonus(item: StandardItem) -> void` · `Globals/item_shop.gd:177`

Records `Vector2i(passive.affected_stat, passive.stat_amount)` as the item's `APPLIED_META` so the UI can show it. Skips non-`PassiveItem`s. The stat itself is added by the wearer's `reset_temp_stats()` through `add_passive_item_stats()`.

**Called by:** [[item_shop#equip]] (line 147).

### _remove_bonus
`func _remove_bonus(item: StandardItem) -> void` · `Globals/item_shop.gd:184`

Removes the `APPLIED_META` metadata if present.

**Called by:** [[item_shop#equip]] (line 145), [[item_shop#unequip]] (line 159).

## Suspected issues
- `can_buy`, `buy`, `get_item`, `is_sold`, `can_afford`, `can_equip`, `equip`, `unequip`, `_make_item`, `_on_day_started`, `_remove_bonus` have no `##` comment.
