## Welcome card: the intro blurb from the home screen, split into four short steps.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

const STEPS := [
	["nav_characters", "Hire", "Recruit adventurers for free under Characters, then For Hire."],
	["nav_quests", "Accept or deny", "Every quest needs a decision. Accept one by picking its party."],
	["sun", "End the day", "Parties set out and come back with gold, treasure and injuries."],
	["nav_upgrades", "Grow the guild", "Spend gold on upgrades. Get rich, and one day defeat the Demon King."],
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
	p.custom_minimum_size.x = 640
	center.add_child(p)
	var v := S.vbox(14)
	p.add_child(v)
	var k := S.caps("Welcome, Guild Master", 24)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(k)
	var t := S.title("Your guild awaits", 32)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for s in STEPS:
		var row := S.hbox(18)
		var ic := S.icon(s[0], 44)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(ic)
		var tv := S.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(S.title(s[1], 26))
		tv.add_child(S.wrap(S.label(s[2], 22, S.INK_SOFT)))
		row.add_child(tv)
		v.add_child(row)
	var b := S.button("Open the Ledger", "green")
	b.pressed.connect(ui.close_welcome)
	v.add_child(b)
	return root
