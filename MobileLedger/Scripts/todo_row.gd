## One line of the Home tab's "Today's Ledger" checklist (Scenes/Rows/todo_row.tscn).
## Tile colour and icon are exports so each row previews in the editor.
@tool
extends "res://MobileLedger/Scripts/tap_area.gd"

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

@export var icon_name := "nav_quests":
	set(v):
		icon_name = v
		if is_node_ready():
			_apply()
@export var tile_color := Color("#F2D5CB"):
	set(v):
		tile_color = v
		if is_node_ready():
			_apply()


func _ready() -> void:
	_apply()
	if not Engine.is_editor_hint():
		super()


func _apply() -> void:
	%Icon.texture = S.icon_tex(icon_name)
	%Tile.add_theme_stylebox_override("panel", S.flat(tile_color, 16, 3, S.INK, Vector4(12, 12, 12, 12)))


## chip_info = one of S.INJURY ([label, bg, fg]); only its colours are used.
func show_todo(title: String, sub: String, chip_text: String, chip_info: Array) -> void:
	%TodoTitle.text = title
	%TodoSub.text = sub
	%Status.visible = chip_text != ""
	if chip_text != "":
		%Status.set_chip(chip_text, chip_info[1], chip_info[2])
