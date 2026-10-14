## Adventurer Codex: one character's portrait, health, backstory and stats.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Charter := preload("res://MobileLedger/Scripts/screen_charter.gd")


static func build(ui) -> Control:
	var c: GuildCharacter = ui.page.character
	var hired: bool = CharacterContainer.active_characters.has(c)

	var root := ColorRect.new()
	root.color = S.BG
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := S.vbox(0)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(col)
	col.add_child(Charter.top_bar(ui, "Adventurer Codex", ui.close_page))

	var scroll := ScrollContainer.new()
	scroll.name = "PageScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var v := S.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := S.margin(v, 24, 8, 24, 30)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(m)

	# --- portrait in the ornate frame, name and health ribbon
	var head := S.hbox(18)
	head.add_child(S.portrait(c, 200))

	var info := S.vbox(8)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nm := S.wrap(S.title(c.name, 34))
	info.add_child(nm)
	info.add_child(S.label("the %s" % S.role_name(c), 24, S.INK_SOFT))
	var inj: Array = S.INJURY[clampi(c.injury_level, 0, 4)]
	info.add_child(S.chip(inj[0], inj[1], inj[2], 24))
	info.add_child(S.label("No injuries yet" if c.injury_count == 0 else "%d injur%s taken" % [c.injury_count, "y" if c.injury_count == 1 else "ies"], 24, S.INK_SOFT))
	var e: Dictionary = ui.entry_of(c)
	if not e.is_empty():
		info.add_child(S.wrap(S.label("Questing: %s" % e.quest.questTitle, 23, S.INFO)))
	head.add_child(info)
	v.add_child(head)

	# --- backstory (collapsible)
	var story := S.panel("card", Vector4(24, 16, 24, 18))
	var sv := S.vbox(10)
	story.add_child(sv)
	var sh := S.hbox(12)
	sh.add_child(S.title("Backstory", 32))
	sh.add_child(S.spacer())
	sh.add_child(S.label("[-]" if ui.story_open else "[+]", 24))
	var toggle := S.tap_area(sh, 64)
	toggle.pressed.connect(func():
		ui.story_open = not ui.story_open
		ui.queue_refresh())
	sv.add_child(toggle)
	if ui.story_open:
		for line in c.description.strip_edges().split("\n"):
			if line.strip_edges() == "":
				continue
			sv.add_child(S.wrap(S.label(line.strip_edges(), 22)))
	v.add_child(story)

	# --- stats
	v.add_child(S.divider("Stats", 34))
	var stats := S.panel("card", Vector4(24, 10, 24, 16))
	var stv := S.vbox(0)
	stats.add_child(stv)
	for i in 5:
		var st: Dictionary = S.STATS[i]
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		var bonus := 0
		if hired and i < 4:
			bonus = GuildUpgrades.get_stat_bonus(c, i)
		var r := S.hbox(14)
		r.custom_minimum_size.y = 48
		var n := S.label(st.name, 24, st.color)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		var vl := S.label(str(val - bonus), 26, st.color)
		r.add_child(vl)
		var bx := PanelContainer.new()
		bx.custom_minimum_size = Vector2(64, 46)
		bx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if bonus > 0:
			bx.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			var bl := S.label("+%d" % bonus, 24, S.GOOD)
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bx.add_child(bl)
		else:
			bx.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			var dl := S.label("-", 24, S.INK_SOFT)
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bx.add_child(dl)
		r.add_child(bx)
		stv.add_child(r)
		if i < 4:
			stv.add_child(S.hline())
	if hired:
		var note := S.wrap(S.label("Bonuses (+N) come from the Armory (level %d) and already count toward quest odds." % GuildUpgrades.get_level(GuildUpgrades.Building.ARMORY), 22, S.INK_SOFT))
		stv.add_child(S.margin(note, 0, 10, 0, 0))
	v.add_child(stats)

	# --- actions
	var foot := S.panel("bar", Vector4(16, 10, 16, 10))
	var fh := S.hbox(14)
	foot.add_child(fh)
	if hired:
		var a := S.button("Assign to Quest", "blue", 32, 96)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		a.pressed.connect(ui.open_tab.bind("quests"))
		fh.add_child(a)
	else:
		var full: bool = CharacterContainer.active_characters.size() >= CharacterContainer.max_characters
		var hb := S.button("Guild full" if full else "Hire %s (free)" % c.name, "green", 30, 96)
		hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.disabled = full
		hb.pressed.connect(func():
			ui.hire(c)
			ui.close_page())
		fh.add_child(hb)
	col.add_child(foot)
	return root
