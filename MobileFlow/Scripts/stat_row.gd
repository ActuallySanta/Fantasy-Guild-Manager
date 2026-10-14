## Row of coloured stat chips for a character ("Str 5", "Def 7", ...).
## Scene: MobileFlow/Scenes/Components/stat_row.tscn (five chips: Stat0..Stat4,
## in flow_style.gd STATS order). Set font_size / show_pluck per instance.
@tool
extends HFlowContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")

const TEXT_STAT := "%s %d"

@export var font_size := 20:
	set(v):
		font_size = v
		_apply()
## Hide Pluck (the fifth stat), e.g. where only the four quest stats matter.
@export var show_pluck := true:
	set(v):
		show_pluck = v
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	for i in 5:
		_chip(i).font_size = font_size
	_chip(4).visible = show_pluck


## `fav` (0-4) gets a heavier outline; `with_pluck` = false hides Pluck too.
func show_stats(c: GuildCharacter, fav: int = -1, with_pluck: bool = true) -> void:
	for i in 5:
		var st: Dictionary = S.STATS[i]
		_chip(i).visible = i < 4 or (with_pluck and show_pluck)
		_chip(i).set_icon_chip("", TEXT_STAT % [st.short, S.stat_value(c, i)], st.bg, st.color, -1, i == fav)


func _chip(i: int) -> Node:
	return get_node("Stat%d" % i)
