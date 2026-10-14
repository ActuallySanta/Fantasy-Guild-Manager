## Five small stat cells: icon, value, short name (Scenes/Components/stat_grid.tscn).
extends GridContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func show_stats(c: GuildCharacter) -> void:
	for i in 5:
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		get_node("Stat%d/Column/Value" % i).text = str(val)
