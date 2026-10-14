## Characters tab: "Your Guild" (the roster) and "For Hire" (today's recruits),
## as two clearly different halves of one tab.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


static func build(ui) -> Control:
	var v := S.vbox(12)
	var roster: Array = CharacterContainer.active_characters
	var hires: Array = CharacterContainer.hireable_characters
	var cap: int = CharacterContainer.max_characters

	# --- segmented switch
	var seg := S.hbox(0)
	for s in [["guild", "Your Guild  %d/%d" % [roster.size(), cap], "nav_characters"], ["hire", "For Hire  ·  %d" % hires.size(), "plus"]]:
		var on: bool = ui.seg == s[0]
		var b := S.button(s[1], "", 27, 92)
		b.icon = S.icon_tex(s[2])
		b.toggle_mode = true
		b.button_pressed = on
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			ui.seg = s[0]
			ui.queue_refresh())
		seg.add_child(b)
	v.add_child(seg)

	if ui.seg == "guild":
		var hint := S.wrap(S.label("Tap an adventurer to open their codex.", 25, S.INK_SOFT))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(hint)
		for c in roster:
			v.add_child(_roster_card(ui, c))
		if roster.is_empty():
			var p := S.panel("card", Vector4(30, 26, 30, 26))
			var pv := S.vbox(16)
			p.add_child(pv)
			var ic := S.icon("nav_characters", 72)
			ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			pv.add_child(ic)
			var l := S.wrap(S.label("Your guild is empty. Hire adventurers before you accept quests.", 28))
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pv.add_child(l)
			var go := S.button("See who's for hire", "blue", 30)
			go.pressed.connect(func():
				ui.seg = "hire"
				ui.queue_refresh())
			pv.add_child(go)
			v.add_child(p)
		else:
			for i in maxi(0, cap - roster.size()):
				var slot := PanelContainer.new()
				slot.add_theme_stylebox_override("panel", S.box("inset"))
				slot.custom_minimum_size.y = 60
				var sl := S.caps("Empty bunk", 24)
				sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				slot.add_child(sl)
				v.add_child(slot)
	else:
		var full := roster.size() >= cap
		var note := S.panel("inset", Vector4(24, 16, 24, 18))
		var nh := S.hbox(14)
		note.add_child(nh)
		nh.add_child(S.icon("coins", 48))
		var msg := "Your guild is full (%d/%d). Upgrade the Barracks for more room." % [roster.size(), cap] if full else "Hiring is free. Room for %d more. New faces arrive every morning." % (cap - roster.size())
		nh.add_child(S.wrap(S.label(msg, 25)))
		v.add_child(note)
		for c in hires:
			v.add_child(_hire_card(ui, c, full))
		if hires.is_empty():
			var p2 := S.panel("inset")
			var l2 := S.wrap(S.label("Everyone's been hired. New faces arrive tomorrow morning.", 26, S.INK_SOFT))
			l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			p2.add_child(l2)
			v.add_child(p2)
	return v


## Five small stat cells: icon, value, short name.
static func stat_grid(c: GuildCharacter) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 8)
	for i in 5:
		var st: Dictionary = S.STATS[i]
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", S.flat(st.bg, 0, 1, st.color, Vector4(4, 6, 4, 6)))
		var cv := S.vbox(0)
		var vl := S.label(str(val), 26, st.color)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(vl)
		var nl := S.label(st.short, 18, st.color)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(nl)
		cell.add_child(cv)
		g.add_child(cell)
	return g


static func _roster_card(ui, c: GuildCharacter) -> Control:
	var p := S.panel("card", Vector4(22, 18, 22, 20))
	var v := S.vbox(14)
	p.add_child(v)
	var h := S.hbox(16)
	h.add_child(S.portrait(c, 96))
	var info := S.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(S.title(c.name, 34))
	info.add_child(S.label("the %s" % S.role_name(c), 26, S.INK_SOFT))
	var e: Dictionary = ui.entry_of(c)
	if not e.is_empty():
		info.add_child(S.trim(S.label("Questing: %s" % e.quest.questTitle, 22, S.INFO)))
	h.add_child(info)
	h.add_child(S.injury_chip(c.injury_level, 22))
	v.add_child(h)
	v.add_child(stat_grid(c))
	var tap := S.tap_area(p)
	tap.pressed.connect(ui.open_codex.bind(c))
	return tap


static func _hire_card(ui, c: GuildCharacter, full: bool) -> Control:
	var p := S.panel("card", Vector4(22, 18, 22, 20))
	var v := S.vbox(14)
	p.add_child(v)
	var h := S.hbox(16)
	h.add_child(S.portrait(c, 96))
	var info := S.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(S.title(c.name, 34))
	var total: int = c.stats[0] + c.stats[1] + c.stats[2] + c.stats[3]
	info.add_child(S.label("the %s · stat total %d" % [S.role_name(c), total], 25, S.INK_SOFT))
	h.add_child(info)
	var more := S.button("Codex", "", 24, 72)
	more.pressed.connect(ui.open_codex.bind(c))
	more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(more)
	v.add_child(h)
	v.add_child(stat_grid(c))
	var first: String = c.description.strip_edges().split("\n")[0]
	var blurb := S.wrap(S.label(first, 25, S.INK_SOFT))
	blurb.max_lines_visible = 3
	v.add_child(blurb)
	var b := S.button("Guild full · upgrade Barracks" if full else "Hire %s (free)" % c.name, "green", 30, 90)
	b.disabled = full
	b.pressed.connect(ui.hire.bind(c))
	v.add_child(b)
	return p
