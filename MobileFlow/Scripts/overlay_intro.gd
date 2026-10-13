## First-launch card explaining the three steps of each day.
extends RefCounted

const S := preload("res://MobileFlow/Scripts/flow_style.gd")

const STEPS := [
	["nav_characters", "1. Hire", "Recruit adventurers for free. You need at least one to take quests."],
	["nav_quests", "2. Quests", "Quests come one at a time. Pick a party and send them, or deny the quest."],
	["sun", "3. End Day", "Spend gold on upgrades, then end the day. Parties come back with gold and injuries."],
]


static func build(ui) -> Control:
	var root := ColorRect.new()
	root.color = Color(0, 0, 0, 0.5)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var p := S.panel("panel", Vector4(24, 20, 24, 20))
	p.custom_minimum_size.x = 620
	center.add_child(p)
	var v := S.vbox(14)
	p.add_child(v)
	v.add_child(S.title("Every day has 3 steps", 30))
	for s in STEPS:
		var row := S.hbox(14)
		var ic := S.icon(s[0], 44)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(ic)
		var tv := S.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(S.title(s[1], 24))
		tv.add_child(S.wrap(S.label(s[2], 20, S.INK_SOFT)))
		row.add_child(tv)
		v.add_child(row)
	v.add_child(S.wrap(S.label("The Guild button (top right) shows your roster and upgrades any time.", 20, S.INFO)))
	var b := S.button("Start", "green")
	b.pressed.connect(ui.close_intro)
	v.add_child(b)
	return root
