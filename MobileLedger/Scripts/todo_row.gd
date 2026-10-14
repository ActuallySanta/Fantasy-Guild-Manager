## One line of the Home tab's "Today's Ledger" checklist. Tap to go there.
## Scene: MobileLedger/Scenes/Rows/todo_row.tscn
## Icon and tile colour are exports, set on each of the four rows in page_home.tscn.
@tool
extends "res://MobileLedger/Scripts/tap_area.gd"

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

## An icon name from MobileLedger/Art/Icons.
@export var icon_name := "nav_quests":
	set(v):
		icon_name = v
		_apply_tile()
@export var tile_color := Color("#F2D5CB"):
	set(v):
		tile_color = v
		_apply_tile()

@onready var _tile: PanelContainer = %Tile
@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %TodoTitle
@onready var _sub: Label = %TodoSub
@onready var _status = %Status


func _ready() -> void:
	_apply_tile()
	if not Engine.is_editor_hint():
		super()


## chip_colors: one of ledger_style.gd INJURY rows ([label, bg, fg]); only the
## colours are used. Empty chip_text hides the chip.
func show_todo(title: String, sub: String, chip_text: String, chip_colors: Array) -> void:
	_title.text = title
	_sub.text = sub
	_status.visible = chip_text != ""
	if chip_text != "":
		_status.set_chip(chip_text, chip_colors[1], chip_colors[2])


func _apply_tile() -> void:
	if not is_node_ready():
		return
	_icon.texture = S.icon_tex(icon_name)
	_tile.add_theme_stylebox_override("panel", S.flat(tile_color, 16, 3, S.INK, Vector4(12, 12, 12, 12)))
