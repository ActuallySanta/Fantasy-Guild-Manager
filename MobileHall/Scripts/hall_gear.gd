## Gear rules for the Items tab's Pack (tab_pack.gd and its overlays): which
## heroes can wear an item, and how a hero's stats change when gear goes on or
## comes off. Static functions only: they read the roster and gear from the
## autoloads and change nothing. Equipping itself goes through HallMain
## (equip_item / unequip_item / swap_gear).
class_name HallGear
extends RefCounted


## Living heroes on the roster whose role matches the item, minus whoever is
## wearing it now. Heroes with a free gear slot come first.
## item: the item to put on. Returns the heroes, in roster order otherwise.
static func heroes_for(item: StandardItem) -> Array[GuildCharacter]:
	var free: Array[GuildCharacter] = []
	var full: Array[GuildCharacter] = []
	for character in CharacterContainer.active_characters:
		if HallStyle.is_dead(character) or character.role != item.role or item.curr_user == character:
			continue
		if has_free_slot(character):
			free.append(character)
		else:
			full.append(character)
	return free + full


## Living heroes on the roster who can't wear the item (wrong role).
static func heroes_wrong_role(item: StandardItem) -> Array[GuildCharacter]:
	var heroes: Array[GuildCharacter] = []
	for character in CharacterContainer.active_characters:
		if not HallStyle.is_dead(character) and character.role != item.role:
			heroes.append(character)
	return heroes


## True if the hero can take one more item without taking another off.
static func has_free_slot(character: GuildCharacter) -> bool:
	return character.equipped_items.size() < character.max_items


## What a passive item adds: Vector2i(stat index, amount), or (-1, 0) for
## an item that doesn't add a stat.
static func item_bonus(item: StandardItem) -> Vector2i:
	if item is PassiveItem:
		var passive := item as PassiveItem
		return Vector2i(passive.affected_stat, passive.stat_amount)
	return Vector2i(-1, 0)


## How the hero's quest stats change if item_on goes on and item_off comes off
## (either may be null). Only the stats that change are listed.
## Returns [{"stat": stat index, "before": int, "after": int}, ...], in stat order.
static func preview(character: GuildCharacter, item_on: StandardItem, item_off: StandardItem) -> Array[Dictionary]:
	var deltas := {}
	if item_on != null:
		var bonus_on := item_bonus(item_on)
		if bonus_on.x >= 0:
			deltas[bonus_on.x] = deltas.get(bonus_on.x, 0) + bonus_on.y
	if item_off != null:
		var bonus_off := item_bonus(item_off)
		if bonus_off.x >= 0:
			deltas[bonus_off.x] = deltas.get(bonus_off.x, 0) - bonus_off.y
	var changes: Array[Dictionary] = []
	for stat_index in HallStyle.QUEST_STAT_COUNT:
		var delta: int = deltas.get(stat_index, 0)
		if delta == 0:
			continue
		var before := HallStyle.quest_stat_value(character, stat_index)
		changes.append({"stat": stat_index, "before": before, "after": before + delta})
	return changes


## preview() as BBCode lines for a RichTextLabel: "Power  40 → 18", the new
## number green when it goes up and red when it goes down.
static func preview_text(changes: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	for change in changes:
		var ink: Color = HallStyle.GREEN_TEXT if change.after > change.before else HallStyle.RED
		lines.append("[b]%s[/b]   %d → [color=#%s][b]%d[/b][/color]" % [
			HallStyle.STATS[change.stat].name, change.before, ink.to_html(false), change.after])
	return "\n".join(lines)
