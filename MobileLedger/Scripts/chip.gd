## Small rounded badge, optionally with an icon.
## Scene: MobileLedger/Scenes/Components/chip.tscn
##
## Every look setting is an export, so chips placed in scenes preview in the
## editor. At runtime call set_chip / set_icon_chip / set_injury instead.
@tool
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

@export var text := "Chip":
	set(v):
		text = v
		_update()
## An icon name from MobileLedger/Art/Icons ("" = none).
@export var icon_name := "":
	set(v):
		icon_name = v
		_update()
@export var bg := Color("#EAD6A8"):
	set(v):
		bg = v
		_update()
@export var fg := Color("#3A2816"):
	set(v):
		fg = v
		_update()
## Text size; the icon scales with it.
@export var font_size := 22:
	set(v):
		font_size = v
		_update()
## Plain chips: 2px border in the text colour.
@export var border := true:
	set(v):
		border = v
		_update()
## Icon-chip look (tighter left padding, no border unless `outlined`).
@export var icon_style := false:
	set(v):
		icon_style = v
		_update()
## Heavier 3px border (the quest's favored stat).
@export var outlined := false:
	set(v):
		outlined = v
		_update()

@onready var _icon: TextureRect = $Row/Icon
@onready var _label: Label = $Row/Text


func _ready() -> void:
	_update()


## Plain text chip. size_px = -1 keeps the size set in the scene.
func set_chip(t: String, bg_color: Color, fg_color: Color, size_px: int = -1, bordered: bool = true) -> void:
	_set_look(t, "", bg_color, fg_color, size_px, false, false, bordered)


## Chip with an icon ("" = none); `is_outlined` = heavier border in the text colour.
func set_icon_chip(icon: String, t: String, bg_color: Color, fg_color: Color, size_px: int = -1, is_outlined: bool = false) -> void:
	_set_look(t, icon, bg_color, fg_color, size_px, true, is_outlined, true)


## GuildCharacter.InjuryLevel badge.
func set_injury(level: int, size_px: int = -1) -> void:
	var info: Array = S.INJURY[clampi(level, 0, 4)]
	set_chip(info[0], info[1], info[2], size_px)


func _set_look(t: String, icon: String, bg_color: Color, fg_color: Color, size_px: int, is_icon_style: bool, is_outlined: bool, bordered: bool) -> void:
	text = t
	icon_name = icon
	bg = bg_color
	fg = fg_color
	if size_px > 0:
		font_size = size_px
	icon_style = is_icon_style
	outlined = is_outlined
	border = bordered


## Apply every export to the nodes.
func _update() -> void:
	if not is_node_ready():
		return
	var tex := S.icon_tex(icon_name)
	_icon.texture = tex
	_icon.visible = tex != null
	_icon.custom_minimum_size = Vector2.ONE * (font_size + 6)
	_label.text = text
	_label.add_theme_font_size_override("font_size", font_size)
	if icon_style:
		S.style_icon_chip(self, _label, bg, fg, outlined)
	else:
		S.style_chip(self, _label, bg, fg, border)
