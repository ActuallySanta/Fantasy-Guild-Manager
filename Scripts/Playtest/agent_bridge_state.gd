## Builds the rules-mode `state` snapshot the agent bridge returns.
## Used by: Scripts/Playtest/agent_bridge.gd (the `state` command). No scene.
##
## Static functions only, no state. Every value comes from the hall's own
## queries (HallMain) and the autoloads, never recomputed here. Instance ids
## (`get_instance_id()`) identify heroes and items; they are stable for the
## life of the process and are what action commands take.
## This script is excluded from exports (export_presets.cfg exclude_filter).
class_name AgentBridgeState
extends RefCounted

## Features whose lock the snapshot reports: bottom tabs, then Pip's tutorial gates.
const LOCKABLE_FEATURES: Array[String] = ["upgrades", "shop", "hire", "hero_page", "deny"]
## `kind` values of a quest entry.
const KIND_NORMAL := "normal"
const KIND_MILESTONE := "milestone"
const KIND_FINAL := "final"


## The whole rules-mode state as a JSON-ready dictionary.
## hall: the running hall. Returns the dictionary described in the playtester design.
static func build(hall: HallMain) -> Dictionary:
	return {
		"day": GameState.day,
		"days_until_drake": hall.days_until_drake(),
		"gold": GameState.gold,
		"standing": GameState.standing,
		"run_over": hall.is_run_over(),
		"locked": _locked(hall),
		"roster": hall.roster().map(func(character): return _hero(hall, character)),
		"hires": CharacterContainer.hireable_characters.map(_hire),
		"quests": _quests(hall),
		"shop": _shop(),
		"items": ItemContainer.owned_items.map(_owned_item),
		"buildings": HallStyle.buildings_in_order().filter(GuildUpgrades.is_implemented).map(_building),
	}


## {feature: bool} for LOCKABLE_FEATURES, from HallMain.is_locked.
static func _locked(hall: HallMain) -> Dictionary:
	var locked := {}
	for feature in LOCKABLE_FEATURES:
		locked[feature] = hall.is_locked(feature)
	return locked


## One roster hero. `injury` is the InjuryLevel name, `stats` uses StatType names.
static func _hero(hall: HallMain, character: GuildCharacter) -> Dictionary:
	return {
		"id": character.get_instance_id(),
		"name": character.name,
		"role": GuildCharacter.CharacterRole.keys()[character.role],
		"injury": GuildCharacter.InjuryLevel.keys()[character.injury_level],
		"pluck": character.pluck,
		"stats": _stats(character.stats),
		"gear": character.equipped_items.map(func(item): return item.get_instance_id()),
		"can_quest": hall.can_go_on_quests(character),
		"training": GuildUpgrades.is_training(character),
	}


## One For Hire applicant. `cost` is the hire price in gold.
static func _hire(character: GuildCharacter) -> Dictionary:
	return {
		"id": character.get_instance_id(),
		"name": character.name,
		"role": GuildCharacter.CharacterRole.keys()[character.role],
		"cost": character.cost,
		"stats": _stats(character.stats),
	}


## Today's Board. `chance` is -1 for an empty party (HallMain.success_chance).
static func _quests(hall: HallMain) -> Array:
	var quests := []
	for index in hall.quest_entries.size():
		var entry: Dictionary = hall.quest_entries[index]
		var kind := KIND_NORMAL
		if entry.final:
			kind = KIND_FINAL
		elif entry.milestone:
			kind = KIND_MILESTONE
		quests.append({
			"index": index,
			"name": entry.quest.questTitle,
			"kind": kind,
			"slots": hall.party_size_limit(entry),
			"party": entry.party.map(func(character): return character.get_instance_id()),
			"chance": hall.success_chance(entry, entry.party),
			"decided": entry.state != HallStyle.QUEST_STATE_OPEN,
			"denied": entry.state == HallStyle.QUEST_STATE_DENIED,
		})
	return quests


## Today's Shop stock, by stock index (what ItemShop.buy takes).
static func _shop() -> Array:
	var shop := []
	for index in ItemShop.stock.size():
		var item: StandardItem = ItemShop.get_item(index)
		shop.append({
			"index": index,
			"name": item.name,
			"rarity": StandardItem.Rarity.keys()[StandardItem.Rarity.values().find(item.rarity)],
			"cost": item.cost,
			"stat_bonus": _stat_bonus(item),
			"sold": ItemShop.is_sold(index),
		})
	return shop


## One owned item. `worn_by` is the wearer's id, or 0 when it is in the pack.
static func _owned_item(item: StandardItem) -> Dictionary:
	return {
		"id": item.get_instance_id(),
		"name": item.name,
		"worn_by": item.curr_user.get_instance_id() if item.curr_user != null else 0,
	}


## One building. `upgrade_cost` is the next level's gold cost (0 at max level).
static func _building(building: int) -> Dictionary:
	return {
		"id": building,
		"name": GuildUpgrades.get_building_name(building),
		"level": GuildUpgrades.get_level(building),
		"upgrade_cost": GuildUpgrades.get_next_gold_cost(building),
	}


## {STAT_NAME: value} from a hero's stats dictionary.
static func _stats(stats: Dictionary) -> Dictionary:
	var named := {}
	for stat in stats:
		named[GuildCharacter.StatType.keys()[stat]] = stats[stat]
	return named


## {"stat": STAT_NAME, "amount": N} for a passive item, {} for anything else.
static func _stat_bonus(item: StandardItem) -> Dictionary:
	if item is PassiveItem:
		return {"stat": GuildCharacter.StatType.keys()[item.affected_stat], "amount": item.stat_amount}
	return {}
