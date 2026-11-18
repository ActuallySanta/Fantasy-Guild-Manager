## One pinned note in the Board's "Today" checklist (Recruits / Decided / Upgrades).
## Green ink when done, dark ink when it wants a visit, faded otherwise.
## Scene: Scenes/Rows/Quests/today_item.tscn
extends TapPanel


# ---- NODES
@onready var _title: Label = %Title
@onready var _value: Label = %Value


## look: "done" (green) | "todo" (dark ink) | "idle" (faded) |
## "locked" (blank and greyed: Pip hasn't taught it yet).
## icon_name is unused now (the notes are pinned paper, no icon); kept for callers.
func set_item(title: String, value: String, _icon_name: String, look: String) -> void:
	var is_locked := look == "locked"
	_title.text = "" if is_locked else title
	_value.text = "" if is_locked else value
	HallStyle.set_locked(self, is_locked)
	match look:
		"done":
			HallStyle.set_font_color(_value, HallStyle.GREEN_TEXT)
		"todo":
			HallStyle.set_font_color(_value, HallStyle.TEXT_MAIN)
		_:
			HallStyle.set_font_color(_value, HallStyle.TEXT_SOFT)
