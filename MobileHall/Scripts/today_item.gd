## One pinned note in the Board's "Today" checklist (Recruits / Decided / Upgrades).
## Green ink when done, dark ink when it wants a visit, faded otherwise.
## Scene: MobileHall/Scenes/Rows/today_item.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const S := preload("res://MobileHall/Scripts/hall_style.gd")

@onready var _title: Label = %Title
@onready var _value: Label = %Value


## look: "done" | "todo" | "idle"
func set_item(title: String, value: String, look: String) -> void:
	_title.text = title
	_value.text = value
	match look:
		"done":
			S.color(_value, S.GREEN_TEXT)
		"todo":
			S.color(_value, S.INK)
		_:
			S.color(_value, S.INK_SOFT)
