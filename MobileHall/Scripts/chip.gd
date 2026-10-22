## A small ink label: text, an optional icon, an optional outline.
## Scene: MobileHall/Scenes/Components/chip.tscn
extends PanelContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

## box -> theme variation drawn around the chip (white art, tinted the ink colour).
const BOXES := { "": &"", "pill": &"Pill", "box": &"InkBox" }

@onready var _icon: TextureRect = $Row/Icon
@onready var _label: Label = $Row/Text


## icon = a name from hall_style ICONS ("" = no icon).
## box = "" (just ink) | "pill" (rounded outline) | "box" (square outline).
func set_chip(text: String, ink: Color, icon: String = "", box: String = "") -> void:
	_label.text = text
	S.color(_label, ink)
	_icon.texture = S.icon_tex(icon)
	_icon.visible = _icon.texture != null
	_icon.modulate = ink
	theme_type_variation = BOXES.get(box, &"")
	S.tint(self, ink)


## Health from a character's injury level, e.g. "Healthy" in green.
func set_health(c: GuildCharacter) -> void:
	var row := S.injury(c)
	set_chip(row[0], row[1])


## One stat as "Str 6". The quest's favored stat gets a pill in its colour.
func set_stat(c: GuildCharacter, i: int, favored: bool = false) -> void:
	var st: Dictionary = S.STATS[i]
	set_chip("%s %d" % [st.short, S.stat_value(c, i)], st.color if favored else S.INK, "", "pill" if favored else "")
