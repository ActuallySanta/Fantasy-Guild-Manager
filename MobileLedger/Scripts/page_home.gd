## Home tab: what to do today, who's hurt, and last night's results.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


static func build(ui) -> Control:
	var v := S.vbox(12)
	var roster: Array = CharacterContainer.active_characters

	# --- day card
	var day := S.panel("card", Vector4(26, 22, 26, 22))
	var dh := S.hbox(20)
	day.add_child(dh)
	dh.add_child(S.icon("sun", 64))
	var dv := S.vbox(0)
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.add_child(S.caps("The ledger reads", 22))
	var dt := S.title("Day %d" % GameState.day, 34)
	dv.add_child(dt)
	var d := GameState.day
	var drake := "The Bone Drake attacks on Day 10 · %d day%s left" % [10 - d, "" if 10 - d == 1 else "s"]
	if d == 10:
		drake = "The Bone Drake is attacking today!"
	elif d > 10:
		drake = "The Bone Drake has come and gone."
	dv.add_child(S.wrap(S.label(drake, 25, S.WAX if d == 10 else S.INK_SOFT)))
	dh.add_child(dv)
	v.add_child(day)

	# --- today's checklist
	v.add_child(S.divider("Today's Ledger", 32))
	var out: int = ui.outstanding()
	var ready: int = ui.ready_entries().size()
	var denied: int = ui.entries.filter(func(e): return e.state == "denied").size()
	var ups := 0
	for b in GuildUpgrades.Building.values():
		if GuildUpgrades.get_upgrade_status(b) == GuildUpgrades.UpgradeStatus.READY:
			ups += 1
	var rows := [
		["nav_characters", Color("#E2D9EF"),
			"Hire your first adventurers" if roster.is_empty() else "%d of %d adventurers" % [roster.size(), CharacterContainer.max_characters],
			"%d for hire today · hiring is free" % CharacterContainer.hireable_characters.size(),
			"Start here" if roster.is_empty() else "", S.INJURY[3],
			func(): ui.open_tab("characters", "hire" if roster.is_empty() else "guild")],
		["nav_quests", Color("#F2D5CB"),
			"%d quest%s need%s a decision" % [out, "" if out == 1 else "s", "s" if out == 1 else ""] if out > 0 else "Every quest decided",
			"%d accepted · %d denied" % [ready, denied],
			"To do" if out > 0 else "Done", S.INJURY[1] if out > 0 else S.INJURY[0],
			func(): ui.open_tab("quests")],
		["nav_upgrades", Color("#D3E1EE"),
			"%d upgrade%s ready to buy" % [ups, "" if ups == 1 else "s"] if ups > 0 else "No upgrades affordable",
			"%d gold · Standing %d" % [GameState.gold, GameState.standing],
			"", S.INJURY[0],
			func(): ui.open_tab("upgrades")],
		["sun", Color("#F4E5AC"),
			"End the day" if out > 0 else "Ready to end Day %d" % GameState.day,
			"Decide every quest first" if out > 0 else ("%d part%s set out tonight" % [ready, "y" if ready == 1 else "ies"] if ready > 0 else "Nobody is going out"),
			"", S.INJURY[0],
			func(): ui.end_day()],
	]
	for r in rows:
		v.add_child(_todo(r))

	# --- adventurer health (injury levels at a glance)
	v.add_child(S.divider("Adventurer Health", 32))
	var hp := S.panel("card", Vector4(22, 12, 22, 14))
	var hv := S.vbox(0)
	hp.add_child(hv)
	for i in roster.size():
		var c: GuildCharacter = roster[i]
		var row := S.hbox(14)
		row.custom_minimum_size.y = 96
		row.add_child(S.portrait(c, 64))
		var nv := S.vbox(-2)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nv.add_child(S.title(c.name, 28))
		nv.add_child(S.label("%s · %s" % [S.role_name(c), "no injuries yet" if c.injury_count == 0 else "%d injur%s" % [c.injury_count, "y" if c.injury_count == 1 else "ies"]], 23, S.INK_SOFT))
		row.add_child(nv)
		row.add_child(S.injury_chip(c.injury_level, 22))
		var tap := S.tap_area(row, 96)
		tap.pressed.connect(ui.open_codex.bind(c))
		hv.add_child(tap)
		if i < roster.size() - 1:
			hv.add_child(S.hline())
	if roster.is_empty():
		hv.add_child(S.margin(S.wrap(S.label("No adventurers yet. Hire your first party from Characters.", 25, S.INK_SOFT)), 0, 12, 0, 12))
	v.add_child(hp)

	# --- last night's report
	if not ui.last_report.is_empty():
		v.add_child(S.divider("Last Night", 32))
		var lp := S.panel("card", Vector4(24, 18, 24, 20))
		var lv := S.vbox(12)
		lp.add_child(lv)
		for res in ui.last_report.results:
			var r := S.hbox(12)
			r.add_child(S.label("[OK]" if res.succeeded else "[FAIL]", 22, S.GOOD if res.succeeded else S.BAD))
			r.add_child(S.trim(S.label(res.quest.questTitle, 25)))
			r.add_child(S.title("+%dg" % res.gold if res.gold > 0 else "0g", 26, S.GOLD_TEXT))
			lv.add_child(r)
		if ui.last_report.results.is_empty():
			lv.add_child(S.label("No quests went out last night.", 25, S.INK_SOFT))
		var b := S.button("Read the full report", "", 27, 84)
		b.pressed.connect(ui.open_last_report)
		lv.add_child(b)
		v.add_child(lp)
	return v


static func _todo(r: Array) -> Control:
	var p := S.panel("card", Vector4(20, 16, 20, 18))
	var h := S.hbox(16)
	p.add_child(h)
	h.add_child(S.icon(r[0], 44))
	var tv := S.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_child(S.wrap(S.title(r[2], 27)))
	tv.add_child(S.wrap(S.label(r[3], 24, S.INK_SOFT)))
	h.add_child(tv)
	if r[4] != "":
		h.add_child(S.chip(r[4], r[5][1], r[5][2], 20))
	var tap := S.tap_area(p)
	tap.pressed.connect(r[6])
	return tap
