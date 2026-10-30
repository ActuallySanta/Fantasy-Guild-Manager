## One pinned note in the Board's "Today" checklist (Recruits / Decided / Upgrades).
## Green ink when done, dark ink when it wants a visit, faded otherwise.
## Scene: MobileHall/Scenes/Rows/today_item.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- NODES
@onready var _title: Label = %Title
@onready var _value: Label = %Value


## look: "done" (green) | "todo" (dark ink) | "idle" (faded).
## icon_name is unused now (the notes are pinned paper, no icon); kept for callers.
func set_item(title: String, value: String, _icon_name: String, look: String) -> void:
	_title.text = title
	_value.text = value
	match look:
		"done":
			Style.set_font_color(_value, Style.GREEN_TEXT)
		"todo":
			Style.set_font_color(_value, Style.TEXT_MAIN)
		_:
			Style.set_font_color(_value, Style.TEXT_SOFT)
