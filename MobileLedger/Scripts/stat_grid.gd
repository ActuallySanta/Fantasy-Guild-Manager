## Five small stat cells: icon, value, short name.
## Scene: MobileLedger/Scenes/Components/stat_grid.tscn (cells Stat0..Stat4,
## in ledger_style.gd STATS order; their colours and icons are set in the scene).
extends GridContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


func show_stats(c: GuildCharacter) -> void:
	for i in 5:
		get_node("Stat%d/Column/Value" % i).text = str(S.stat_value(c, i))
