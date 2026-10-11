## Quests tab: today's postings as parchment slips with wax seals.
## Accept opens the Mission Charter to pick a party; Deny turns the quest down.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


static func build(ui) -> Control:
	var v := S.vbox(30)
	v.add_child(S.divider("Quests", 40))
	var hint := S.wrap(S.label("Accept a quest by picking its party, or deny it. Every quest needs a decision before the day can end.", 25, S.INK_SOFT))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var denied := 0
	for e in ui.entries:
		if e.state == "denied":
			denied += 1
			continue
		v.add_child(card(ui, e))
	if denied > 0:
		var d := S.label("%d quest%s denied today" % [denied, "" if denied == 1 else "s"], 25, S.INK_SOFT, S.body_italic)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(d)
	if denied == ui.entries.size():
		var p := S.panel("inset")
		var l := S.wrap(S.label("Every quest is decided. End the day when you're ready.", 26, S.INK_SOFT))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		v.add_child(p)
	return v


static func type_key(e: Dictionary) -> int:
	return 5 if e.get("milestone", false) else int(e.quest.type)


## The wax seal with ribbon tails, stamped with the quest's rank letter.
static func seal(rank: String, dark: bool, size: float = 84.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size * 1.45)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := TextureRect.new()
	t.texture = S.tex("seal_dark.png" if dark else "seal_ribbon.png")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(t)
	var l := S.title(rank, int(size * 0.36), Color("#F6E2B0"))
	l.add_theme_font_override("font", S.display_black)
	l.add_theme_color_override("font_outline_color", Color("#5A0E12"))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(0, size * 0.06)
	l.size = Vector2(size, size * 0.86)
	c.add_child(l)
	return c


static func favored_row(q: CreatedQuest, size: int = 25) -> HBoxContainer:
	var st: Dictionary = S.STATS[S.favored_index(q)]
	var row := S.hbox(8)
	row.add_child(S.label("Favored:", size, S.INK))
	row.add_child(S.icon_chip(st.icon, st.name, st.bg, st.color, size - 3))
	return row


static func card(ui, e: Dictionary) -> Control:
	var q: CreatedQuest = e.quest
	var ready: bool = e.state == "ready"
	var key := type_key(e)
	var p := S.panel("ready" if ready else "card", Vector4(22, 20, 22, 18))
	var v := S.vbox(12)
	p.add_child(v)

	var top := S.hbox(14)
	v.add_child(top)
	top.add_child(seal(S.rank_letter(q), e.get("milestone", false)))

	var info := S.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := S.wrap(S.title(q.questTitle, 29, S.TYPE_COLORS[key]))
	info.add_child(t)
	var type_name: String = "Milestone" if e.get("milestone", false) else S.TYPE_NAMES.get(int(q.type), "Quest")
	info.add_child(S.rich("[color=#6B5537]%s ·[/color] [b]%d Gold[/b]" % [type_name, q.goldReward], 25))
	var n: int = ui.slot_count(e)
	info.add_child(S.label("1 adventurer (solo)" if n == 1 else "Up to %d adventurers" % n, 25))
	info.add_child(favored_row(q))
	var ch: int = ui.chance_for(e, e.party)
	var o: Array = S.odds(ch)
	var ch_text := "--" if ch < 0 else "%d%% · %s" % [mini(ch, 100), o[0]]
	info.add_child(S.rich("Success: [b][color=#%s]%s[/color][/b]" % [o[1].to_html(false), ch_text], 25))
	top.add_child(info)

	var pic := S.picture(S.TYPE_SCENES[key], Vector2(178, 132))
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(pic)

	v.add_child(S.hline())
	var bottom := S.hbox(12)
	v.add_child(bottom)
	if ready:
		for c in e.party:
			bottom.add_child(S.portrait(c, 76, "rounded"))
		var names := []
		for c in e.party:
			names.append(c.name)
		var nl := S.trim(S.label(" & ".join(PackedStringArray(names)), 26, S.INK, S.body_bold))
		nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bottom.add_child(nl)
		var edit := S.button("Edit", "wood", 26, 80)
		edit.pressed.connect(ui.open_charter.bind(e))
		bottom.add_child(edit)
		var cancel := S.button("Cancel", "paper", 26, 80)
		cancel.pressed.connect(ui.cancel.bind(e))
		bottom.add_child(cancel)
	else:
		var slots := S.hbox(10)
		for i in n:
			var slot := PanelContainer.new()
			slot.add_theme_stylebox_override("panel", S.sbtex("slot_dashed.png", 30, Vector4(0, 0, 0, 0)))
			slot.custom_minimum_size = Vector2(80, 80)
			var plus := S.icon("plus", 34, S.INK_SOFT)
			plus.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			slot.add_child(plus)
			slots.add_child(slot)
		var pick := S.tap_area(slots, 80)
		pick.custom_minimum_size.x = n * 90
		pick.tooltip_text = "Pick a party"
		pick.pressed.connect(ui.open_charter.bind(e))
		bottom.add_child(pick)
		bottom.add_child(S.spacer())
		var deny := S.button("Deny", "red", 28, 82)
		deny.pressed.connect(ui.deny.bind(e))
		bottom.add_child(deny)
		var accept := S.button("Accept", "green", 28, 82)
		accept.pressed.connect(ui.open_charter.bind(e))
		bottom.add_child(accept)
	return p
