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
	root.color = Color(0.16, 0.10, 0.05, 0.72)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var p := S.panel("panel", Vector4(36, 34, 36, 36))
	p.custom_minimum_size.x = 640
	center.add_child(p)
	var v := S.vbox(22)
	p.add_child(v)
	var seal := S.picture("seal_ribbon.png", Vector2(110, 150))
	seal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(seal)
	var k := S.caps("Welcome, Guild Master", 24)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(k)
	var t := S.title("Your guild awaits", 46)
	t.add_theme_font_override("font", S.display_black)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for s in STEPS:
		var row := S.hbox(18)
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(76, 76)
		tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		tile.add_theme_stylebox_override("panel", S.flat(Color("#EAD6A8"), 38, 3, S.INK, Vector4(12, 12, 12, 12)))
		tile.add_child(S.icon(s[0], 46))
		row.add_child(tile)
		var tv := S.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(S.title(s[1], 30))
		tv.add_child(S.wrap(S.label(s[2], 26, Color("#4E3D26"))))
		row.add_child(tv)
		v.add_child(row)
	var b := S.button("Open the Ledger", "green", 34, 100)
	b.pressed.connect(ui.close_welcome)
	v.add_child(b)
	return root
