## Adventurer Codex: one character's portrait, health, backstory and stats.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Charter := preload("res://MobileLedger/Scripts/screen_charter.gd")


static func build(ui) -> Control:
	var c: GuildCharacter = ui.page.character
	var hired: bool = CharacterContainer.active_characters.has(c)

	var root := TextureRect.new()
	root.texture = S.tex("page_bg.png")
	root.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.stretch_mode = TextureRect.STRETCH_SCALE
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
	var v := S.vbox(24)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := S.margin(v, 24, 8, 24, 30)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(m)

	# --- portrait in the ornate frame, name and health ribbon
	var head := S.hbox(18)
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(270, 324)
	var oval := Panel.new()
	oval.position = Vector2(34, 40)
	oval.size = Vector2(202, 256)
	var osb := S.flat(S.ROLE_GROUNDS[c.role], 0, 0)
	osb.corner_radius_top_left = 101
	osb.corner_radius_top_right = 101
	osb.corner_radius_bottom_left = 101
	osb.corner_radius_bottom_right = 101
	osb.corner_detail = 20
	oval.add_theme_stylebox_override("panel", osb)
	oval.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var art := TextureRect.new()
	art.texture = ExternalContentContainer.get_character_icon(c.role)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_top = 20
	oval.add_child(art)
	frame.add_child(oval)
	var ring := S.picture("frame_oval.png", Vector2(270, 324))
	frame.add_child(ring)
	head.add_child(frame)

	var info := S.vbox(8)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nm := S.wrap(S.title(c.name, 56))
	nm.add_theme_font_override("font", S.display_black)
	info.add_child(nm)
	info.add_child(S.title("the %s" % S.role_name(c), 30, S.INK_SOFT))
	var inj: Array = S.INJURY[clampi(c.injury_level, 0, 4)]
	info.add_child(S.ribbon_label(inj[0], inj[1], inj[2], 30))
	info.add_child(S.label("No injuries yet" if c.injury_count == 0 else "%d injur%s taken" % [c.injury_count, "y" if c.injury_count == 1 else "ies"], 24, S.INK_SOFT))
	var e: Dictionary = ui.entry_of(c)
	if not e.is_empty():
		info.add_child(S.wrap(S.label("Questing: %s" % e.quest.questTitle, 23, S.BLUE_TEXT, S.body_bold)))
	head.add_child(info)
	v.add_child(head)

	# --- backstory (collapsible)
	var story := S.panel("card", Vector4(24, 16, 24, 18))
	var sv := S.vbox(10)
	story.add_child(sv)
	var sh := S.hbox(12)
	sh.add_child(S.icon("wisdom", 40))
	sh.add_child(S.title("Backstory", 32))
	sh.add_child(S.spacer())
	sh.add_child(S.icon("chev_up" if ui.story_open else "chev_down", 34, S.INK))
	var toggle := S.tap_area(sh, 64)
	toggle.pressed.connect(func():
		ui.story_open = not ui.story_open
		ui.queue_refresh())
	sv.add_child(toggle)
	if ui.story_open:
		for line in c.description.strip_edges().split("\n"):
			if line.strip_edges() == "":
				continue
			sv.add_child(S.wrap(S.label(line.strip_edges(), 26, Color("#4E3D26"))))
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
		r.custom_minimum_size.y = 76
		r.add_child(S.icon(st.icon, 50))
		var n := S.label(st.name, 30, st.color, S.body_bold)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		var vl := S.title(str(val - bonus), 38)
		vl.add_theme_font_override("font", S.display_black)
		r.add_child(vl)
		var bx := PanelContainer.new()
		bx.custom_minimum_size = Vector2(64, 46)
		bx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if bonus > 0:
			bx.add_theme_stylebox_override("panel", S.flat(Color("#E3EFD2"), 8, 2, Color("#4F7A3A"), Vector4(4, 0, 4, 2)))
			var bl := S.label("+%d" % bonus, 26, S.GREEN_TEXT, S.body_bold)
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bx.add_child(bl)
		else:
			bx.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			var dl := S.label("—", 26, Color("#A08A66"), S.body_bold)
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bx.add_child(dl)
		r.add_child(bx)
		stv.add_child(r)
		if i < 4:
			stv.add_child(S.hline())
	if hired:
		var note := S.wrap(S.label("Green bonuses come from the Armory (level %d) and already count toward quest odds." % GuildUpgrades.get_level(GuildUpgrades.Building.ARMORY), 22, S.INK_SOFT))
		stv.add_child(S.margin(note, 0, 10, 0, 0))
	v.add_child(stats)

	# --- actions
	var foot := PanelContainer.new()
	foot.add_theme_stylebox_override("panel", S.sbtex("inset_parchment.png", 26, Vector4(24, 14, 24, 14), 8))
	var fh := S.hbox(14)
	foot.add_child(fh)
	if hired:
		var a := S.button("Assign to Quest", "green", 32, 96)
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
