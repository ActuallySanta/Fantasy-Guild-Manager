## A row of stat chips ("Pow 6", "Def 4+2", ...) that wraps when it runs out of
## room. The quest's favored stat gets a heavy outline so you can see who fits
## without reading numbers.
## Scene: MobileHall/Scenes/Components/stat_strip.tscn
## (The scene has one chip child per stat, in hall_style STATS order.)
extends HFlowContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")


## favored_stat_index = index into hall_style STATS (-1 = none).
## Pluck isn't rolled against directly (it boosts the other stats), so it's only shown when `include_pluck` is on.
func show_stats(character: GuildCharacter, favored_stat_index: int = -1, include_pluck: bool = true) -> void:
	for stat_index in Style.STAT_COUNT:
		var stat_chip := get_child(stat_index)
		stat_chip.visible = stat_index != Style.PLUCK_INDEX or include_pluck
		if stat_chip.visible:
			stat_chip.set_stat(character, stat_index, stat_index == favored_stat_index)
