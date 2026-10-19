## One box in the Board's "Today" checklist (Recruits / Quests / Upgrades).
## Green when done, blue when it wants a visit, plain otherwise.
## Scene: MobileHall/Scenes/Rows/today_item.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- NODES
@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _value: Label = %Value


## look: "done" (green) | "todo" (blue) | "idle" (plain).
func set_item(title: String, value: String, icon_name: String, look: String) -> void:
	_title.text = title
	_value.text = value
	_icon.texture = Style.icon_texture(icon_name)
	match look:
		"done":
			Style.style_panel(self, Style.GREEN_BG, Style.GREEN, 3)
			Style.set_font_color(_value, Style.GREEN_TEXT)
		"todo":
			Style.style_panel(self, Style.BLUE_BG, Style.BLUE_TEXT, 3)
			Style.set_font_color(_value, Style.BLUE_TEXT)
		_:
			Style.style_panel(self, Style.CARD_BG, Style.BORDER, 2)
			Style.set_font_color(_value, Style.TEXT_SOFT)
