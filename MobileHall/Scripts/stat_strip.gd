## A row of stat chips ("Str 6", "Def 4", ...). The quest's favored stat gets a
## heavy outline so you can see who fits without reading numbers.
## Scene: MobileHall/Scenes/Components/stat_strip.tscn
extends HBoxContainer


## favored = index into hall_style STATS (-1 = none). Pluck isn't used by
## quests yet, so it's only shown where `with_pluck` is on.
func show_stats(c: GuildCharacter, favored: int = -1, with_pluck: bool = true) -> void:
	for i in 5:
		var chip := get_child(i)
		chip.visible = i < 4 or with_pluck
		if chip.visible:
			chip.set_stat(c, i, i == favored)
