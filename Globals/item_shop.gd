## Autoload "ItemShop" — the Shop tab's stock, and the glue between the
## Item-System scripts (StandardItem / PassiveItem / ItemContainer) and heroes.
##   - Stock: STOCK_SIZE generated PassiveItems, rerolled every dawn
##     (GameState.day_started). Bought items go to ItemContainer.owned_items.
##   - Buying pays from the GuildUpgrades wallet.
##   - Equipping is role-locked (item.role must match the hero's role) and
##     capped by character.max_items. It goes through ItemContainer, then the
##     hero's temp_stats are rebuilt (character.reset_temp_stats(), which adds
##     pluck and add_passive_item_stats()). Gear never touches character.stats,
##     so pluck (10% of the base stats) doesn't stack on top of gear. What each
##     item gives is stored on it as metadata for the UI (get_item_bonus).
## The MobileHall UI calls these through hall_main.gd (buy_item / equip_item /
## unequip_item), which shows the toasts.
extends Node

## The stock was rerolled or something was bought.
signal stock_changed
## An item was put on or taken off a hero.
signal gear_changed

enum EquipResult { OK, NOT_OWNED, ALREADY_ON, WRONG_ROLE, SLOTS_FULL, DEAD }

## How many goods are on the counter each day (the Shop tab's 3 x 2 grid).
const STOCK_SIZE := 6
## Item metadata: Vector2i(stat, amount) this item added to its wearer's stats.
const APPLIED_META := "item_bonus_applied"

## Today's goods: [{"item": StandardItem, "sold": bool}, ...]
var stock: Array[Dictionary] = []


func _ready() -> void:
	GameState.day_started.connect(_on_day_started)
	# deferred so the other autoloads (ExternalContentContainer names items) are ready
	restock.call_deferred()


func _on_day_started(_day: int) -> void:
	restock()

# ---------------------------------------------------------------- shop


## Fresh goods on the counter (yesterday's unsold goods are gone).
func restock() -> void:
	stock.clear()
	for i in STOCK_SIZE:
		stock.append({"item": _make_item(), "sold": false})
	stock_changed.emit()


func _make_item() -> StandardItem:
	var role: GuildCharacter.CharacterRole = GuildCharacter.CharacterRole.values().pick_random()
	var item := PassiveItem.new(role)
	# StandardItem._init names the item for this role but doesn't store the
	# role, so keep it here: equipping is role-locked.
	item.role = role
	return item


func get_item(index: int) -> StandardItem:
	if index < 0 or index >= stock.size():
		return null
	return stock[index].item


func is_sold(index: int) -> bool:
	return index >= 0 and index < stock.size() and stock[index].sold


func can_afford(item: StandardItem) -> bool:
	return GuildUpgrades.gold >= item.cost


func can_buy(index: int) -> bool:
	var item := get_item(index)
	return item != null and not is_sold(index) and can_afford(item)


func buy(index: int) -> bool:
	if not can_buy(index):
		return false
	var item := get_item(index)
	GuildUpgrades.add_gold(-item.cost)
	ItemContainer.owned_items.append(item)
	stock[index].sold = true
	stock_changed.emit()
	return true

# ---------------------------------------------------------------- gear


## Owned items this hero could wear: their role, not already on them.
## Items worn by someone else are included (equipping moves them).
func items_for(character: GuildCharacter) -> Array[StandardItem]:
	var items: Array[StandardItem] = []
	for item in ItemContainer.owned_items:
		if item.role == character.role and item.curr_user != character:
			items.append(item)
	return items


## Unworn items in the pack.
func unworn_count() -> int:
	var count := 0
	for item in ItemContainer.owned_items:
		if item.curr_user == null:
			count += 1
	return count


func can_equip(item: StandardItem, character: GuildCharacter) -> EquipResult:
	if not ItemContainer.owned_items.has(item):
		return EquipResult.NOT_OWNED
	if item.curr_user == character:
		return EquipResult.ALREADY_ON
	if character.injury_level >= GuildCharacter.InjuryLevel.DEAD:
		return EquipResult.DEAD
	if item.role != character.role:
		return EquipResult.WRONG_ROLE
	if character.equipped_items.size() >= character.max_items:
		return EquipResult.SLOTS_FULL
	return EquipResult.OK


func equip(item: StandardItem, character: GuildCharacter) -> EquipResult:
	var result := can_equip(item, character)
	if result != EquipResult.OK:
		return result
	# moving it off another hero takes their bonus away first
	var previous_user: GuildCharacter = item.curr_user
	if previous_user != null:
		_remove_bonus(item)
	ItemContainer.give_item_to_character(item, character)
	_apply_bonus(item)
	if previous_user != null:
		previous_user.reset_temp_stats()
	character.reset_temp_stats()
	gear_changed.emit()
	return result


func unequip(item: StandardItem) -> void:
	var user: GuildCharacter = item.curr_user
	if user == null:
		return
	_remove_bonus(item)
	ItemContainer.remove_item_from_character(item, user)
	user.reset_temp_stats()
	gear_changed.emit()


## How much of a hero's stat comes from their gear (it lives in temp_stats).
func get_item_bonus(character: GuildCharacter, stat: int) -> int:
	var total := 0
	for item in character.equipped_items:
		var applied: Vector2i = item.get_meta(APPLIED_META, Vector2i(-1, 0))
		if applied.x == stat:
			total += applied.y
	return total


## Records what the item gives so the UI can show it. The stat itself is added
## by the wearer's reset_temp_stats() -> add_passive_item_stats().
func _apply_bonus(item: StandardItem) -> void:
	if not (item is PassiveItem):
		return
	var passive := item as PassiveItem
	item.set_meta(APPLIED_META, Vector2i(passive.affected_stat, passive.stat_amount))


func _remove_bonus(item: StandardItem) -> void:
	if item.has_meta(APPLIED_META):
		item.remove_meta(APPLIED_META)
