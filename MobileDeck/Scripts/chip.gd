## Small label badge (Components/chip.tscn). Everything about it is an export,
## so chips placed in scenes preview in the editor. At runtime, call set_chip /
## set_icon_chip / set_injury to recolour it for what it means.
@tool
extends PanelContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")

@export var text := "Chip":
	set(v):
		text = v
		_update()
## A name from deck_style.gd ICON_FILES ("" = no icon).
@export var icon_name := "":
	set(v):
		icon_name = v
		_update()
@export var bg := Color("#30323F"):
	set(v):
		bg = v
		_update()
@export var fg := Color("#EEEFF3"):
	set(v):
		fg = v
		_update()
@export var font_size := 20:
	set(v):
		font_size = v
		_update()
## Plain chips: thin border in the text colour (grey for plain text).
@export var border := true:
	set(v):
		border = v
		_update()
## Icon-chip look: always a grey border, unless `outlined`.
@export var icon_style := false:
	set(v):
		icon_style = v
		_update()
## Heavier 2px border in the text colour (used for the quest's favored stat).
@export var outlined := false:
	set(v):
		outlined = v
		_update()


func _ready() -> void:
	_update()


func _update() -> void:
	if not is_node_ready():
		return
	var tex := S.icon_tex(icon_name)
	$Row/Icon.texture = tex
	$Row/Icon.visible = tex != null
	$Row/Icon.custom_minimum_size = Vector2.ONE * (font_size + 6) * 0.75
	S.tint_icon($Row/Icon, fg)
	$Row/Text.text = text
	$Row/Text.add_theme_font_size_override("font_size", font_size)
	if icon_style:
		S.style_icon_chip(self, $Row/Text, bg, fg, outlined)
	else:
		S.style_chip(self, $Row/Text, bg, fg, border, outlined)


func set_chip(t: String, bg_color: Color = S.BOX_ALT, fg_color: Color = S.INK, size_px: int = -1, bordered: bool = true) -> void:
	_set_all(t, "", bg_color, fg_color, size_px, false, false, bordered)


## Chip with an icon ("" = none); `is_outlined` = heavier border in the text colour.
func set_icon_chip(icon: String, t: String, bg_color: Color = S.BOX_ALT, fg_color: Color = S.INK, size_px: int = -1, is_outlined: bool = false) -> void:
	_set_all(t, icon, bg_color, fg_color, size_px, true, is_outlined, true)


## GuildCharacter.InjuryLevel badge (green -> red -> grey).
func set_injury(level: int, size_px: int = -1) -> void:
	var info: Array = S.INJURY[clampi(level, 0, 4)]
	set_chip(info[0], info[1], info[2], size_px)


func _set_all(t: String, icon: String, bg_color: Color, fg_color: Color, size_px: int, is_icon_style: bool, is_outlined: bool, bordered: bool) -> void:
	text = t
	icon_name = icon
	bg = bg_color
	fg = fg_color
	if size_px > 0:
		font_size = size_px
	icon_style = is_icon_style
	outlined = is_outlined
	border = bordered
