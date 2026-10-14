## Row of coloured stat chips for a character ("Str 5", "Def 7", ...).
## The five chips are in Components/stat_row.tscn; this fills in the numbers.
@tool
extends HFlowContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")

@export var font_size := 20:
	set(v):
		font_size = v
		if is_node_ready():
			_apply_size()


## Hide the fifth stat (Pluck), e.g. where only the four quest stats matter.
@export var show_pluck := true:
	set(v):
		show_pluck = v
		if is_node_ready():
			_apply_size()


func _ready() -> void:
	_apply_size()


func _apply_size() -> void:
	for i in 5:
		get_node("Stat%d" % i).font_size = font_size
	get_node("Stat4").visible = show_pluck


## `fav` (0-4) gets a heavier outline; `with_pluck` shows the fifth stat.
func show_stats(c: GuildCharacter, fav: int = -1, with_pluck: bool = true) -> void:
	for i in 5:
		var chip := get_node("Stat%d" % i)
		chip.visible = i < 4 or (with_pluck and show_pluck)
		var st: Dictionary = S.STATS[i]
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		chip.set_icon_chip("", "%s %d" % [st.short, val], st.bg, st.color, -1, i == fav)
