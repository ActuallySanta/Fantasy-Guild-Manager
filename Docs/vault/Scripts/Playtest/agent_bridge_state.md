---
source: Scripts/Playtest/agent_bridge_state.gd
class_name: AgentBridgeState
extends: RefCounted
scene: ""
systems: ["[[Playtest Bridge]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# agent_bridge_state.gd

## Purpose
Builds the rules-mode `state` snapshot the agent bridge returns. Static functions only. Every value comes from the hall's queries (`HallMain`) and the autoloads. Heroes and items are identified by `get_instance_id()` as a string (ids can exceed 2^53, which JSON numbers can't hold); action commands take those ids. Used by [[agent_bridge]] and [[agent_bridge_actions]]. No scene. Excluded from exports.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `LOCKABLE_FEATURES` | const | Features whose lock is reported: upgrades, shop, hire, hero_page, deny (tabs, then Pip's tutorial gates). |
| `KIND_NORMAL`, `KIND_MILESTONE`, `KIND_FINAL` | const | `kind` values of a quest entry. |

## Functions

### build
`static func build(hall: HallMain) -> Dictionary` · `Scripts/Playtest/agent_bridge_state.gd:25`

The whole snapshot: day, days_until_drake, next_boss_day, gold, hospital_fee, standing, run_over, locked, roster, hires, quests, shop, items, buildings (only implemented ones, in display order).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The running hall | `_hall` in [[agent_bridge#_dispatch]]; the `hall` argument in [[agent_bridge_actions#plan]], [[agent_bridge_actions#end_day]], [[agent_bridge_actions#debug]] |

**Returns:** the snapshot dictionary. Used by the `state` command ([[agent_bridge#_dispatch]], `agent_bridge.gd:231`, which adds `ok`) and embedded as `state` in the `plan`, `end_day` and `debug` answers.

**Called by:** [[agent_bridge#_dispatch]] (`agent_bridge.gd:231`), [[agent_bridge_actions#plan]] (`agent_bridge_actions.gd:103`), [[agent_bridge_actions#end_day]] (`agent_bridge_actions.gd:257`), [[agent_bridge_actions#debug]] (`agent_bridge_actions.gd:337`).

**Calls:** [[hall_main#days_until_drake]], [[hall_rules#next_boss_day]], [[guild_upgrades#nightly_fee]], [[agent_bridge_actions#is_run_over]], [[agent_bridge_state#_locked]], [[agent_bridge_state#_hero]], [[agent_bridge_state#_quests]], [[agent_bridge_state#_shop]], [[hall_style#buildings_in_order]], [[guild_upgrades#is_implemented]].

### _locked
`static func _locked(hall: HallMain) -> Dictionary` · `Scripts/Playtest/agent_bridge_state.gd:45`

**Returns:** `{feature: bool}` for each of `LOCKABLE_FEATURES`. Used in [[agent_bridge_state#build]] (`agent_bridge_state.gd:34`).

**Calls:** [[hall_main#is_locked]].

### _hero
`static func _hero(hall: HallMain, character: GuildCharacter) -> Dictionary` · `Scripts/Playtest/agent_bridge_state.gd:53`

One roster hero: id, name, role, injury (InjuryLevel name), pluck, stats, gear (item ids), can_quest, training. `character` comes from `hall.roster()` mapped in [[agent_bridge_state#build]] (`agent_bridge_state.gd:35`).

**Calls:** [[agent_bridge_state#id_of]], [[agent_bridge_state#_stats]], [[hall_main#can_go_on_quests]], [[guild_upgrades#is_training]].

### _hire
`static func _hire(character: GuildCharacter) -> Dictionary` · `Scripts/Playtest/agent_bridge_state.gd:68`

One For Hire applicant: id, name, role, `cost` (gold), stats. Used as a mapped callable over `CharacterContainer.hireable_characters` in [[agent_bridge_state#build]] (`agent_bridge_state.gd:36`; passed as a Callable, not a direct call).

**Calls:** [[agent_bridge_state#id_of]], [[character_container#hire_price]], [[agent_bridge_state#_stats]].

### _quests
`static func _quests(hall: HallMain) -> Array` · `Scripts/Playtest/agent_bridge_state.gd:79`

Today's Board, one dictionary per `hall.quest_entries`: index, name, kind, slots, party (ids), chance (-1 for an empty party), standing_win, standing_fail, decided, denied. Used in [[agent_bridge_state#build]] (`agent_bridge_state.gd:37`).

**Calls:** [[hall_main#party_size_limit]], [[hall_main#success_chance]], [[hall_rules#standing_for_win]], [[hall_rules#standing_for_loss]], [[agent_bridge_state#id_of]].

### _shop
`static func _shop() -> Array` · `Scripts/Playtest/agent_bridge_state.gd:105`

Today's Shop stock by stock index (what `ItemShop.buy` takes): index, name, role, rarity (enum name), cost, stat_bonus, sold. Used in [[agent_bridge_state#build]] (`agent_bridge_state.gd:38`).

**Calls:** [[item_shop#get_item]], [[item_shop#is_sold]], [[agent_bridge_state#_item_role]], [[agent_bridge_state#_stat_bonus]].

### _owned_item
`static func _owned_item(item: StandardItem) -> Dictionary` · `Scripts/Playtest/agent_bridge_state.gd:123`

One owned item: id, name, role, `worn_by` (wearer id or ""). Passed as a Callable to `ItemContainer.owned_items.map` in [[agent_bridge_state#build]] (`agent_bridge_state.gd:39`).

**Calls:** [[agent_bridge_state#id_of]], [[agent_bridge_state#_item_role]].

### _item_role
`static func _item_role(item: StandardItem) -> String`  · `Scripts/Playtest/agent_bridge_state.gd:134`

The `CharacterRole` name of the heroes who can wear `item` (gear is role-locked). Called by [[agent_bridge_state#_shop]] (`agent_bridge_state.gd:112`) and [[agent_bridge_state#_owned_item]] (`agent_bridge_state.gd:127`).

### _building
`static func _building(building: int) -> Dictionary` · `Scripts/Playtest/agent_bridge_state.gd:139`

One building: id, name, level, `upgrade_cost` (next level's gold, 0 at max). Passed as a Callable to `.map` in [[agent_bridge_state#build]] (`agent_bridge_state.gd:40`).

**Calls:** [[guild_upgrades#get_building_name]], [[guild_upgrades#get_level]], [[guild_upgrades#get_next_gold_cost]].

### _stats
`static func _stats(stats: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_state.gd:149`

`{STAT_NAME: value}` from a hero's stats dictionary (keys by `StatType` name). Called by [[agent_bridge_state#_hero]] (`agent_bridge_state.gd:60`) and [[agent_bridge_state#_hire]] (`agent_bridge_state.gd:74`).

### _stat_bonus
`static func _stat_bonus(item: StandardItem) -> Dictionary` · `Scripts/Playtest/agent_bridge_state.gd:157`

`{stat, amount}` for a `PassiveItem`, `{}` otherwise. Called by [[agent_bridge_state#_shop]] (`agent_bridge_state.gd:115`).

### id_of
`static func id_of(object: Object) -> String` · `Scripts/Playtest/agent_bridge_state.gd:165`

**Returns:** `str(object.get_instance_id())`, the id the snapshot uses for a hero or item.

**Called by:** [[agent_bridge_actions#_named_hero]] (`agent_bridge_actions.gd:289`), [[agent_bridge_state#_hero]], [[agent_bridge_state#_hire]], [[agent_bridge_state#_quests]], [[agent_bridge_state#_owned_item]], [[agent_bridge_state#find_by_id]].

### find_by_id
`static func find_by_id(candidates: Array, id: String) -> Object` · `Scripts/Playtest/agent_bridge_state.gd:172`

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `candidates` | `Array` | Heroes or items to search | `hall.roster()`, `ItemContainer.owned_items`, `CharacterContainer.hireable_characters` in [[agent_bridge_actions]] |
| `id` | `String` | A snapshot id | the plan arguments from the client |

**Returns:** the matching object, or null. Callers cast it and answer "no such hero/item/applicant" on null.

**Called by:** [[agent_bridge_actions#_hire]] (`agent_bridge_actions.gd:116`), [[agent_bridge_actions#_release]] (`:124`), [[agent_bridge_actions#_equip]] (`:147`, `:148`), [[agent_bridge_actions#_unequip]] (`:157`), [[agent_bridge_actions#_train]] (`:170`), [[agent_bridge_actions#_hero_step]] (`:180`), [[agent_bridge_actions#_assign]] (`:200`).

**Calls:** [[agent_bridge_state#id_of]].

## Suspected issues
- `agent_bridge_state.gd:12-14`: a `##` comment about string ids sits above a blank line and the next `##` block, so it documents nothing (cosmetic).
