## Bottom sheets over the deck: upgrades, character details, and the how-to-play card.
extends RefCounted

const S := preload("res://MobileDeck/Scripts/deck_style.gd")


static func build(ui) -> Control:
	match ui.sheet.get("kind", ""):
		"upgrades":
			return _upgrades(ui)
		"character":
			return _character(ui, ui.sheet.character)
	return _intro(ui)


## Dimmed backdrop + a rounded sheet rising from the bottom. Returns [root, content vbox].
static func _sheet(ui, title_text: String) -> Array:
	var root := ColorRect.new()
	root.color = Color(0, 0, 0, 0.6)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	var sb := S.flat(S.BOX, 28, 0, S.LINE, Vector4(20, 16, 20, 0))
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_top = 110
	root.add_child(panel)
	var col := S.vbox(10)
	panel.add_child(col)
	var head := S.hbox(10)
	var t := S.title(title_text, 30)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(t)
	head.add_child(S.spacer())
	var x := S.button("Close", "", 22, 52)
	x.pressed.connect(ui.close_sheet)
	head.add_child(x)
	col.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var v := S.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(S.margin(v, 0, 0, 6, 24))
	v.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return [root, v]


static func _upgrades(ui) -> Control:
	var parts := _sheet(ui, "Upgrades")
	var v: VBoxContainer = parts[1]
	v.add_child(S.label("%d gold  ·  Standing %d" % [GameState.gold, GameState.standing], 22, S.INK_SOFT))
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	for b in order:
		v.add_child(_upgrade_row(ui, b))
	return parts[0]


static func _upgrade_row(ui, b: int) -> Control:
	var lvl := GuildUpgrades.get_level(b)
	var status := GuildUpgrades.get_upgrade_status(b)
	var soon := status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED
	var p := S.panel("card")
	if soon:
		p.modulate = Color(1, 1, 1, 0.5)
	var v := S.vbox(6)
	p.add_child(v)
	var top := S.hbox(10)
	top.add_child(S.title(GuildUpgrades.get_building_name(b), 26))
	var lv := S.label("Lv %d/%d" % [lvl, GuildUpgrades.MAX_LEVEL], 20, S.INK_SOFT)
	lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(lv)
	top.add_child(S.spacer())
	if soon:
		top.add_child(S.chip("Coming soon", S.INFO_BG, S.INFO, 18, false))
	v.add_child(top)
	var g := S.gauge(float(lvl) / GuildUpgrades.MAX_LEVEL, S.INFO, 200)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(g)
	v.add_child(S.rich("[b]Now:[/b] %s" % GuildUpgrades.get_effect_text(b, lvl), 20))
	if not GuildUpgrades.is_max_level(b):
		v.add_child(S.rich("[color=#%s][b]Next:[/b] %s[/color]" % [S.GOOD.to_html(false), GuildUpgrades.get_effect_text(b, lvl + 1)], 20))
	var bottom := S.hbox(8)
	if not GuildUpgrades.is_max_level(b):
		var cost := GuildUpgrades.get_next_gold_cost(b)
		var req := GuildUpgrades.get_next_standing_req(b)
		bottom.add_child(S.icon_chip("coins", "%d" % cost, S.GOLD_BG if GameState.gold >= cost else S.BAD_BG, S.GOLD if GameState.gold >= cost else S.BAD, 18))
		bottom.add_child(S.icon_chip("rook", "%d" % req, S.BOX_ALT if GameState.standing >= req else S.BAD_BG, S.INK if GameState.standing >= req else S.BAD, 18))
	bottom.add_child(S.spacer())
	var label := "Upgrade"
	match status:
		GuildUpgrades.UpgradeStatus.NOT_ENOUGH_GOLD:
			label = "Need gold"
		GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW:
			label = "Need Standing"
		GuildUpgrades.UpgradeStatus.MAX_LEVEL:
			label = "Max level"
		GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED:
			label = "Coming soon"
	var btn := S.button(label, "green" if status == GuildUpgrades.UpgradeStatus.READY else "", 20, 52)
	btn.disabled = status != GuildUpgrades.UpgradeStatus.READY
	btn.pressed.connect(ui.upgrade.bind(b))
	bottom.add_child(btn)
	v.add_child(bottom)
	return p


static func _character(ui, c: GuildCharacter) -> Control:
	var parts := _sheet(ui, c.name)
	var v: VBoxContainer = parts[1]
	var hired: bool = CharacterContainer.active_characters.has(c)
	var head := S.hbox(16)
	head.add_child(S.portrait(c, 170))
	var info := S.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(S.label("the %s" % S.role_name(c), 24, S.INK_SOFT))
	info.add_child(S.injury_chip(c.injury_level, 22))
	info.add_child(S.label("No injuries yet" if c.injury_count == 0 else "%d injur%s taken" % [c.injury_count, "y" if c.injury_count == 1 else "ies"], 20, S.INK_SOFT))
	var e: Dictionary = ui.entry_of(c)
	if not e.is_empty():
		info.add_child(S.wrap(S.label("On quest: %s" % e.quest.questTitle, 20, S.INFO)))
	head.add_child(info)
	v.add_child(head)

	var stats := S.panel("card")
	var sv := S.vbox(4)
	stats.add_child(sv)
	for i in 5:
		var st: Dictionary = S.STATS[i]
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		var bonus := 0
		if hired and i < 4:
			bonus = GuildUpgrades.get_stat_bonus(c, i)
		var r := S.hbox(10)
		r.custom_minimum_size.y = 40
		var n := S.label(st.name, 22, st.color)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		r.add_child(S.label(str(val - bonus), 24, st.color))
		var bl := S.label("+%d" % bonus if bonus > 0 else "", 20, S.GOOD)
		bl.custom_minimum_size.x = 44
		r.add_child(bl)
		sv.add_child(r)
	if hired:
		sv.add_child(S.wrap(S.label("+N = Armory bonus (level %d), already counted in quest odds." % GuildUpgrades.get_level(GuildUpgrades.Building.ARMORY), 18, S.INK_SOFT)))
	v.add_child(stats)

	var story := S.panel("card")
	var stv := S.vbox(6)
	story.add_child(stv)
	stv.add_child(S.title("Backstory", 24))
	for line in c.description.strip_edges().split("\n"):
		if line.strip_edges() != "":
			stv.add_child(S.wrap(S.label(line.strip_edges(), 20)))
	v.add_child(story)
	return parts[0]


static func _intro(ui) -> Control:
	var root := ColorRect.new()
	root.color = Color(0, 0, 0, 0.7)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", S.flat(S.BOX, 26, 1, S.LINE, Vector4(28, 24, 28, 24)))
	p.custom_minimum_size.x = 620
	center.add_child(p)
	var v := S.vbox(16)
	p.add_child(v)
	v.add_child(S.title("Each day is a deck of cards", 30))
	for row in [
		[S.GOOD, "Swipe right", "Hire a recruit, or send a party on a quest."],
		[S.BAD, "Swipe left", "Pass on a recruit, or deny a quest."],
		[S.INFO, "Tap your guild", "Tap adventurers in the bottom tray to put them on the quest card."],
		[S.GOLD, "Last card", "Buy upgrades, then end the day. Parties return with gold and injuries."],
	]:
		var h := S.hbox(14)
		var bar := ColorRect.new()
		bar.color = row[0]
		bar.custom_minimum_size = Vector2(8, 0)
		h.add_child(bar)
		var tv := S.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(S.title(row[1], 24, row[0]))
		tv.add_child(S.wrap(S.label(row[2], 20, S.INK_SOFT)))
		h.add_child(tv)
		v.add_child(h)
	v.add_child(S.wrap(S.label("Not a swiper? The buttons under each card do the same thing.", 20, S.INK_SOFT)))
	var b := S.button("Start", "green", 26, 64)
	b.pressed.connect(ui.close_sheet)
	v.add_child(b)
	return root
