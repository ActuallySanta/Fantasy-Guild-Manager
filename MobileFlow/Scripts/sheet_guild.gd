## Guild sheet (header "Guild" button): roster, today's recruits and upgrades,
## reachable from any step without losing your place.
extends RefCounted

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const StepHire := preload("res://MobileFlow/Scripts/step_hire.gd")
const StepEnd := preload("res://MobileFlow/Scripts/step_end.gd")


static func frame(title_text: String, close: Callable, extra: Control = null) -> Array:
	var root := ColorRect.new()
	root.color = S.BG
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := S.vbox(0)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(col)
	var head := S.panel("panel", Vector4(14, 8, 14, 8))
	var hh := S.hbox(12)
	head.add_child(hh)
	var t := S.title(title_text, 28)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hh.add_child(t)
	hh.add_child(S.spacer())
	if extra:
		hh.add_child(extra)
	var x := S.button("Close", "", 22, 52)
	x.pressed.connect(close)
	hh.add_child(x)
	col.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var v := S.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := S.margin(v, 16, 14, 16, 24)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(m)
	return [root, v]


static func build(ui) -> Control:
	var help := S.button("How to play", "", 20, 52)
	help.pressed.connect(func():
		ui.show_intro = true
		ui.queue_refresh())
	var parts := frame("Guild", ui.close_sheet, help)
	var v: VBoxContainer = parts[1]
	var roster: Array = CharacterContainer.active_characters
	var cap: int = CharacterContainer.max_characters
	var seg: String = ui.sheet.get("seg", "roster")

	var tabs := S.hbox(0)
	for s in [["roster", "Roster %d/%d" % [roster.size(), cap]], ["hire", "For hire (%d)" % CharacterContainer.hireable_characters.size()], ["upgrades", "Upgrades"]]:
		var b := S.button(s[1], "", 20, 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.button_pressed = seg == s[0]
		if seg == s[0]:
			b.add_theme_stylebox_override("pressed", S.flat(S.INFO_BG, 0, 2, S.INFO))
			b.add_theme_color_override("font_pressed_color", S.INFO)
		b.pressed.connect(func():
			ui.sheet.seg = s[0]
			ui.queue_refresh())
		tabs.add_child(b)
	v.add_child(tabs)

	match seg:
		"roster":
			for c in roster:
				v.add_child(_member(ui, c))
			if roster.is_empty():
				v.add_child(S.wrap(S.label("Nobody in the guild yet. Check For hire.", 22, S.INK_SOFT)))
		"hire":
			var full := roster.size() >= cap
			for c in CharacterContainer.hireable_characters:
				v.add_child(StepHire._recruit(ui, c, full))
			if CharacterContainer.hireable_characters.is_empty():
				v.add_child(S.wrap(S.label("Nobody is for hire right now.", 22, S.INK_SOFT)))
		_:
			v.add_child(S.label("%d gold, Standing %d" % [GameState.gold, GameState.standing], 22, S.INK_SOFT))
			var order: Array = GuildUpgrades.Building.values()
			order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
			for b in order:
				v.add_child(StepEnd.upgrade_row(ui, b))
	return parts[0]


static func _member(ui, c: GuildCharacter) -> Control:
	var p := S.panel("card")
	var h := S.hbox(12)
	p.add_child(h)
	h.add_child(S.portrait(c, 80))
	var mid := S.vbox(4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nr := S.hbox(8)
	nr.add_child(S.label(c.name, 24))
	nr.add_child(S.label(S.role_name(c), 20, S.INK_SOFT))
	nr.add_child(S.spacer())
	nr.add_child(S.injury_chip(c.injury_level, 18))
	mid.add_child(nr)
	mid.add_child(S.stat_row(c, -1, true, 18))
	var e: Dictionary = ui.entry_of(c)
	if not e.is_empty():
		mid.add_child(S.trim(S.label("On quest: %s" % e.quest.questTitle, 18, S.INFO)))
	h.add_child(mid)
	var tap := S.tap_area(p)
	tap.pressed.connect(ui.open_character.bind(c))
	return tap
