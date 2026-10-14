## Numbered square per quest on today's board: grey = undecided, green = party
## set, red = denied. The current one has a thick blue border. Tap to jump to it.
## Scene: MobileFlow/Scenes/Rows/quest_dot.tscn
extends Button

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")

## Fill colour per quest state.
const FILLS := {"open": S.BOX, "ready": S.GOOD_BG, "denied": S.BAD_BG}


func setup(ui: Main, i: int) -> void:
	var current: bool = i == ui.quest_index
	text = str(i + 1)
	var sb := S.flat(FILLS[ui.entries[i].state], 0, 1, S.INFO if current else S.LINE, Vector4.ZERO)
	sb.set_border_width_all(3 if current else 1)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		add_theme_stylebox_override(st, sb)
	pressed.connect(ui.show_quest.bind(i))
