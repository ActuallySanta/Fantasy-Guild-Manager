## Small square per quest on today's board: grey = undecided, green = party set,
## red = denied; the current one has a thick blue border (Rows/quest_dot.tscn).
extends Button

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


func setup(ui, i: int) -> void:
	var e: Dictionary = ui.entries[i]
	var fill: Color = {"open": S.BOX, "ready": S.GOOD_BG, "denied": S.BAD_BG}[e.state]
	var current: bool = i == ui.quest_index
	text = str(i + 1)
	var sb := S.flat(fill, 0, 1, S.INFO if current else S.LINE, Vector4(0, 0, 0, 0))
	sb.set_border_width_all(3 if current else 1)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		add_theme_stylebox_override(st, sb)
	pressed.connect(ui.show_quest.bind(i))
