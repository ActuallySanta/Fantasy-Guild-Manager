## A row of stat chips ("Pow 6", "Def 4+2", ...) that wraps when it runs out of
## room, led by an optional health chip. The quest's favored stat gets a heavy
## outline so you can see who fits without reading numbers.
## Scene: MobileHall/Scenes/Components/stat_strip.tscn
## (The scene has a Health chip, then one chip child per stat named Stat0..Stat4
## in hall_style STATS order.)
extends HFlowContainer


# ---- NODES
@onready var _health_chip = %Health           # chip.gd


## favored_stat_index = index into hall_style STATS (-1 = none).
## Pluck isn't rolled against directly (it boosts the other stats), so it's only
## shown when `include_pluck` is on.
## top_count = how many stats to show (0 = all): the hero's strongest quest
## stats by the value quests use (with Armory, gear and Pluck). Pluck is never
## one of them, and ties go to the stat listed first in STATS.
func show_stats(character: GuildCharacter, favored_stat_index: int = -1, include_pluck: bool = true, top_count: int = 0) -> void:
	var shown_stats := _top_stats(character, top_count) if top_count > 0 else []
	for stat_index in HallStyle.STAT_COUNT:
		var stat_chip := get_node("Stat%d" % stat_index)
		if top_count > 0:
			# shown chips keep STATS order, so a stat sits in the same place on every card
			stat_chip.visible = shown_stats.has(stat_index)
		else:
			stat_chip.visible = stat_index != HallStyle.PLUCK_INDEX or include_pluck
		if stat_chip.visible:
			stat_chip.set_stat(character, stat_index, stat_index == favored_stat_index)


## Show the health chip at the head of the strip (hidden until this is called).
func show_health(character: GuildCharacter) -> void:
	_health_chip.visible = true
	_health_chip.set_health(character)


## The `count` strongest quest stats, as STATS indexes.
func _top_stats(character: GuildCharacter, count: int) -> Array:
	var ranked := range(HallStyle.QUEST_STAT_COUNT)
	var values := {}
	for stat_index in ranked:
		values[stat_index] = HallStyle.quest_stat_value(character, stat_index)
	# sort_custom isn't stable, so break ties on the index to keep STATS order
	ranked.sort_custom(func(a, b): return values[a] > values[b] or (values[a] == values[b] and a < b))
	return ranked.slice(0, count)
