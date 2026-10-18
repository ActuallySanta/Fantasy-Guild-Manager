## Small rounded label, optionally with an icon.
## Scene: MobileHall/Scenes/Components/chip.tscn
extends PanelContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

@onready var _icon: TextureRect = $Row/Icon
@onready var _label: Label = $Row/Text


## icon = a name from hall_style ICON_FILES ("" or unknown = no icon).
## outlined = heavier border (the quest's favored stat).
func set_chip(text: String, bg: Color, fg: Color, icon: String = "", outlined: bool = false) -> void:
	_label.text = text
	S.color(_label, fg)
	_icon.texture = S.icon_tex(icon)
	_icon.visible = _icon.texture != null
	var border := 3 if outlined else 0
	var left := 8 if _icon.visible else 12
	add_theme_stylebox_override("panel", S.flat(bg, 16, border, fg, Vector4(left, 2, 12, 3)))


## Health chip from a character's injury level.
func set_health(c: GuildCharacter) -> void:
	var row := S.injury(c)
	set_chip(row[0], row[1], row[2], "heart" if c.injury_level == 0 else "injury")


## One stat as "Str 6" in that stat's colours.
func set_stat(c: GuildCharacter, i: int, favored: bool = false) -> void:
	var st: Dictionary = S.STATS[i]
	set_chip("%s %d" % [st.short, S.stat_value(c, i)], st.bg, st.color, "", favored)
