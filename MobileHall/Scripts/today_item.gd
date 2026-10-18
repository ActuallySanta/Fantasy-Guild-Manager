## One box in the Board's "Today" checklist (Recruits / Quests / Upgrades).
## Green when done, blue when it wants a visit, plain otherwise.
## Scene: MobileHall/Scenes/Rows/today_item.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const S := preload("res://MobileHall/Scripts/hall_style.gd")

@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _value: Label = %Value


## look: "done" | "todo" | "idle"
func set_item(title: String, value: String, icon: String, look: String) -> void:
	_title.text = title
	_value.text = value
	_icon.texture = S.icon_tex(icon)
	match look:
		"done":
			S.style_panel(self, S.GREEN_BG, S.GREEN, 3)
			S.color(_value, S.GREEN_TEXT)
		"todo":
			S.style_panel(self, S.BLUE_BG, S.BLUE_TEXT, 3)
			S.color(_value, S.BLUE_TEXT)
		_:
			S.style_panel(self, S.CREAM, S.LINE, 2)
			S.color(_value, S.INK_SOFT)
