## What's printed on each card in the deck: a recruit, a quest, or the end of the day.
extends RefCounted

const S := preload("res://MobileDeck/Scripts/deck_style.gd")


static func build(ui) -> Control:
	var c: Dictionary = ui.current()
	match c.kind:
		"hire":
			return _hire(ui, c.character)
		"quest":
			return _quest(ui, c.entry)
	return _end(ui)


static func _center(n: Control) -> Control:
	n.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return n


static func _hint(text: String) -> Label:
	var l := S.wrap(S.label(text, 20, S.INK_SOFT))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


# ---------------------------------------------------------------- recruit

static func _hire(ui, c: GuildCharacter) -> Control:
	var v := S.vbox(12)
	v.add_child(_center(S.chip("RECRUIT  ·  free to hire", S.INFO_BG, S.INFO, 18, false)))
	v.add_child(_center(S.portrait(c, 230)))
	var n := S.title(c.name, 38)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var r := S.label("the %s" % S.role_name(c), 24, S.INK_SOFT)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	var stats := S.stat_row(c, -1, true, 22)
	stats.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(stats)
	var lines := c.description.strip_edges().split("\n")
	var story := S.wrap(S.label(lines[0] if lines.size() > 0 else "", 21))
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.max_lines_visible = 4
	v.add_child(story)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
	if ui.room() > 0:
		v.add_child(_hint("Swipe right to hire, left to pass.\nRoom for %d more in your guild." % ui.room()))
	else:
		var full := S.wrap(S.label("Your guild is full. Swipe left to pass.", 20, S.WARN))
		full.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(full)
	return v


# ---------------------------------------------------------------- quest

static func _quest(ui, e: Dictionary) -> Control:
	var q: CreatedQuest = e.quest
	var n: int = ui.slot_count(e)
	var milestone: bool = e.get("milestone", false)
	var v := S.vbox(12)

	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 6)
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	var type_name: String = "MILESTONE" if milestone else S.TYPE_NAMES.get(int(q.type), "Quest").to_upper()
	chips.add_child(S.chip(type_name, S.BAD_BG if milestone else S.BOX_ALT, S.BAD if milestone else S.INK_SOFT, 18, false))
	chips.add_child(S.chip("Rank %s" % S.rank_letter(q), S.BOX_ALT, S.INK, 18, false))
	chips.add_child(S.icon_chip("coins", "%d gold" % q.goldReward, S.GOLD_BG, S.GOLD, 18))
	v.add_child(chips)

	var t := S.wrap(S.title(q.questTitle, 36, S.BAD if milestone else S.INK))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var fi := S.favored_index(q)
	var st: Dictionary = S.STATS[fi]
	var fav := S.hbox(8)
	fav.alignment = BoxContainer.ALIGNMENT_CENTER
	fav.add_child(S.label("Favors", 22, S.INK_SOFT))
	fav.add_child(S.icon_chip("", st.name, st.bg, st.color, 22, true))
	fav.add_child(S.label("(counts twice)" if fi < 4 else "(doesn't change odds)", 18, S.INK_SOFT))
	v.add_child(fav)
	if milestone:
		v.add_child(_hint("The Bone Drake is attacking. This is today's only quest."))

	v.add_child(S.hline())

	# party slots: tap a filled one to remove that adventurer
	var party_lbl := S.label("Solo quest" if n == 1 else "Party of up to %d" % n, 20, S.INK_SOFT)
	party_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(party_lbl)
	var slots := S.hbox(14)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	var size := 150.0 if n <= 2 else 120.0
	for i in n:
		if i < ui.draft.size():
			var ch: GuildCharacter = ui.draft[i]
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.flat = true
			b.custom_minimum_size = Vector2(size, size + 30)
			for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
				b.add_theme_stylebox_override(s, StyleBoxEmpty.new())
			var sv := S.vbox(2)
			sv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			sv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var p := S.portrait(ch, size)
			sv.add_child(p)
			var nl := S.label("%s  x" % ch.name, 18)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(nl)
			b.add_child(sv)
			b.pressed.connect(ui.toggle_draft.bind(ch))
			slots.add_child(b)
		else:
			var empty := PanelContainer.new()
			empty.custom_minimum_size = Vector2(size, size)
			empty.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			var esb := S.flat(S.BOX_ALT, int(size * 0.18), 2, S.LINE)
			empty.add_theme_stylebox_override("panel", esb)
			var el := S.label("+", 48, S.INK_SOFT)
			el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			el.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.add_child(el)
			slots.add_child(empty)
	v.add_child(slots)

	var ch_pct: int = ui.chance_for(e, ui.draft)
	var o: Array = S.odds(ch_pct)
	var pr := S.hbox(12)
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	pr.add_child(S.title("--" if ch_pct < 0 else "%d%%" % mini(ch_pct, 100), 44, o[1]))
	var wl := S.label("chance of success" if ch_pct < 0 else o[0], 22, o[1])
	wl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pr.add_child(wl)
	v.add_child(pr)
	var g := S.gauge(0.0 if ch_pct < 0 else minf(ch_pct, 100) / 100.0, o[2], 420)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(g)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
	if CharacterContainer.active_characters.is_empty():
		v.add_child(_hint("No adventurers yet. Press Back to see the recruits, or swipe left to deny."))
	elif ui.draft.is_empty():
		v.add_child(_hint("Tap adventurers in the tray below to add them.\nThen swipe right to send, or left to deny."))
	else:
		v.add_child(_hint("Swipe right to send this party, left to deny the quest."))
	return v


# ---------------------------------------------------------------- end of day

static func _end(ui) -> Control:
	var v := S.vbox(12)
	var t := S.title("End of Day %d" % GameState.day, 36)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(_hint("Tap a quest to change your decision."))
	for e in ui.entries:
		var row := S.hbox(10)
		row.custom_minimum_size.y = 52
		var tl := S.trim(S.label(e.quest.questTitle, 22))
		tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tl)
		match e.state:
			"ready":
				var names := []
				for c in e.party:
					names.append(c.name)
				row.add_child(S.chip("%s · %d%%" % [", ".join(PackedStringArray(names)), mini(ui.chance_for(e, e.party), 100)], S.GOOD_BG, S.GOOD, 18, false))
			"denied":
				row.add_child(S.chip("Denied", S.BAD_BG, S.BAD, 18, false))
			_:
				row.add_child(S.chip("Undecided", S.WARN_BG, S.WARN, 18, false))
		var tap := S.tap_area(row, 52)
		tap.pressed.connect(ui.jump_to_entry.bind(e))
		v.add_child(tap)
		v.add_child(S.hline())

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)

	var ready_ups := 0
	for b in GuildUpgrades.Building.values():
		if GuildUpgrades.get_upgrade_status(b) == GuildUpgrades.UpgradeStatus.READY:
			ready_ups += 1
	var ub := S.button("Upgrades  (%d ready to buy)" % ready_ups if ready_ups > 0 else "Upgrades", "blue" if ready_ups > 0 else "", 22, 60)
	ub.pressed.connect(ui.open_sheet.bind("upgrades"))
	v.add_child(ub)
	if not ui.last_report.is_empty():
		var lr := S.button("Read last night's report", "", 22, 60)
		lr.pressed.connect(ui.open_last_report)
		v.add_child(lr)
	var going: int = ui.ready_entries().size()
	v.add_child(_hint("%d part%s will set out tonight." % [going, "y" if going == 1 else "ies"] if going > 0 else "Nobody is going out today."))
	var b := S.button("End Day %d" % GameState.day, "green", 28, 72)
	b.pressed.connect(ui.end_day)
	v.add_child(b)
	return v
