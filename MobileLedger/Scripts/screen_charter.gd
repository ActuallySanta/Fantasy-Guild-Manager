## Mission Charter: pick the party for one quest and see the odds live.
## Every adventurer's four quest stats are on screen while you choose, with
## the quest's favored stat outlined, plus how much each one adds to the odds.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const PageQuests := preload("res://MobileLedger/Scripts/page_quests.gd")


static func build(ui) -> Control:
	var e: Dictionary = ui.page.entry
	var q: CreatedQuest = e.quest
	var draft: Array = ui.page.draft
	var n: int = ui.slot_count(e)
	var key := PageQuests.type_key(e)

	var root := TextureRect.new()
	root.texture = S.tex("page_bg.png")
	root.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.stretch_mode = TextureRect.STRETCH_SCALE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := S.vbox(0)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(col)
	col.add_child(top_bar(ui, "Mission Charter", ui.close_page))

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

	# --- the charter itself
	var head := S.panel("card", Vector4(26, 22, 26, 20))
	var hv := S.vbox(8)
	head.add_child(hv)
	var t := S.wrap(S.title(q.questTitle, 38, S.TYPE_COLORS[key]))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(t)
	var type_name: String = "Milestone" if e.get("milestone", false) else S.TYPE_NAMES.get(int(q.type), "Quest")
	var sub := S.rich("[center][color=#6B5537]%s ·[/color] [b]%d Gold[/b] [color=#6B5537]· Rank %s[/color][/center]" % [type_name, q.goldReward, S.rank_letter(q)], 27)
	hv.add_child(sub)
	var pic := S.picture(S.TYPE_SCENES[key], Vector2(440, 210))
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hv.add_child(pic)
	var fav := PageQuests.favored_row(q, 27)
	fav.alignment = BoxContainer.ALIGNMENT_CENTER
	hv.add_child(fav)
	v.add_child(head)

	# --- party slots
	v.add_child(S.divider("Select 1 Adventurer" if n == 1 else "Select up to %d" % n, 30))
	var slots := S.hbox(40)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in n:
		if i < draft.size():
			var c: GuildCharacter = draft[i]
			var sv := S.vbox(6)
			var circle := Control.new()
			circle.custom_minimum_size = Vector2(196, 196)
			var por := S.portrait(c, 172, "circle")
			por.position = Vector2(12, 12)
			circle.add_child(por)
			var ring := S.picture("slot_ring.png", Vector2(196, 196))
			circle.add_child(ring)
			sv.add_child(circle)
			var nl := S.title(c.name, 28)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(nl)
			var rl := S.caps("Tap to remove", 21, S.WAX)
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(rl)
			var tap := S.tap_area(sv)
			tap.custom_minimum_size.x = 196
			tap.pressed.connect(toggle.bind(ui, c))
			slots.add_child(tap)
		else:
			var sv2 := S.vbox(6)
			var circle2 := Control.new()
			circle2.custom_minimum_size = Vector2(196, 196)
			circle2.add_child(S.picture("slot_circle.png", Vector2(196, 196)))
			var inner := S.vbox(0)
			inner.alignment = BoxContainer.ALIGNMENT_CENTER
			inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			inner.offset_bottom = -8
			var plus := S.icon("plus", 56)
			plus.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			inner.add_child(plus)
			for word in ["Add", "Adventurer"]:
				var wl := S.label(word, 26, S.WHITE, S.body_bold)
				wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				wl.add_theme_color_override("font_outline_color", Color(0.1, 0.2, 0.05, 0.8))
				wl.add_theme_constant_override("outline_size", 5)
				inner.add_child(wl)
			circle2.add_child(inner)
			sv2.add_child(circle2)
			var pl := S.caps("Pick below", 21)
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv2.add_child(pl)
			slots.add_child(sv2)
	v.add_child(slots)

	# --- success estimate
	var ch: int = ui.chance_for(e, draft)
	var o: Array = S.odds(ch)
	var est := S.panel("inset", Vector4(26, 18, 26, 20))
	var ev := S.vbox(8)
	est.add_child(ev)
	var cap := S.title("Success Estimate", 28)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(cap)
	var row := S.hbox(18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var pct := S.title("-- %" if ch < 0 else "%d%%" % mini(ch, 100), 68, o[1])
	pct.add_theme_font_override("font", S.display_black)
	row.add_child(pct)
	var word := S.title(o[0], 30)
	word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(word)
	ev.add_child(row)
	var g := S.gauge(0.0 if ch < 0 else minf(ch, 100) / 100.0, o[2], 560)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ev.add_child(g)
	var total := 0
	for c in draft:
		total += _score(q, c)
	var hit := _hit(q)
	var note := "Pick adventurers to see the odds" if draft.is_empty() else "Party stat total %d · %d needed for 100%%" % [total, hit]
	var nl2 := S.wrap(S.label(note, 24, S.INK_SOFT))
	nl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev.add_child(nl2)
	v.add_child(est)

	var emblem := S.icon("emblem", 110)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(emblem)

	# --- roster to pick from
	v.add_child(S.divider("Your Adventurers", 30))
	var fav_name: String = S.STATS[S.favored_index(q)].name
	var fn := S.wrap(S.label("Each adventurer adds all four stats, plus %s again.%s" % [fav_name, " Solo quests need half as much." if n == 1 else ""], 24, S.INK_SOFT))
	fn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(fn)
	var roster: Array = CharacterContainer.active_characters.duplicate()
	roster.sort_custom(func(a, b): return _score(q, a) > _score(q, b))
	for c in roster:
		v.add_child(_pick_row(ui, e, c, draft, n))
	if roster.is_empty():
		var empty := S.panel("inset")
		var ev2 := S.vbox(14)
		empty.add_child(ev2)
		var el := S.wrap(S.label("Nobody to send yet. Hire adventurers first. It's free.", 26))
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ev2.add_child(el)
		var go := S.button("Go to For Hire", "green", 28)
		go.pressed.connect(ui.open_tab.bind("characters", "hire"))
		ev2.add_child(go)
		v.add_child(empty)

	# --- dispatch
	var foot := PanelContainer.new()
	foot.add_theme_stylebox_override("panel", S.sbtex("inset_parchment.png", 26, Vector4(24, 14, 24, 14), 8))
	var fv := S.vbox(4)
	foot.add_child(fv)
	var label := "Pick an adventurer"
	if not draft.is_empty():
		label = "Update Party" if e.state == "ready" else "Dispatch Party"
	var b := S.button(label, "red", 36, 100)
	b.icon = S.tex("seal.png")
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 74)
	b.disabled = draft.is_empty()
	b.pressed.connect(dispatch.bind(ui))
	fv.add_child(b)
	var fl := S.label("The party sets out when you end the day.", 22, S.INK_SOFT, S.body_bold)
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fv.add_child(fl)
	col.add_child(foot)
	return root


## Back button + small banner title, shared by the full-screen pages.
static func top_bar(_ui, text: String, back: Callable) -> Control:
	var h := S.hbox(12)
	var bb := Button.new()
	bb.focus_mode = Control.FOCUS_NONE
	bb.custom_minimum_size = Vector2(88, 88)
	bb.icon = S.icon_tex("back")
	bb.expand_icon = true
	bb.add_theme_color_override("icon_normal_color", S.INK)
	bb.add_theme_color_override("icon_hover_color", S.INK)
	bb.add_theme_color_override("icon_pressed_color", S.INK)
	var round := S.flat(S.CREAM, 44, 3, S.INK, Vector4(20, 20, 20, 20))
	for s in ["normal", "hover", "pressed", "hover_pressed"]:
		bb.add_theme_stylebox_override(s, round)
	bb.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	bb.tooltip_text = "Back"
	bb.pressed.connect(back)
	h.add_child(bb)
	h.add_child(S.spacer())
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", S.sbtex("inset_parchment.png", 26, Vector4(28, 8, 28, 10), 8))
	tag.add_child(S.title(text, 30))
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tag)
	h.add_child(S.spacer())
	var seal := S.picture("seal.png", Vector2(88, 88))
	h.add_child(seal)
	return S.margin(h, 24, 16, 24, 10)


static func _score(q: CreatedQuest, c: GuildCharacter) -> int:
	var s: Dictionary = c.stats
	var total: int = s[0] + s[1] + s[2] + s[3]
	var f := S.favored_index(q)
	if f < 4:
		total += s[f]
	return total


## CreatedQuest.calcSuccessChance's target for 100%.
static func _hit(q: CreatedQuest) -> int:
	var hit := 60.0 + 20 * q.difficulty
	if q.maxAdventurers == 1:
		hit = hit / 2
	return int(hit)


static func _pick_row(ui, e: Dictionary, c: GuildCharacter, draft: Array, n: int) -> Control:
	var chosen := draft.has(c)
	var full := not chosen and n > 1 and draft.size() >= n
	var elsewhere: Dictionary = ui.entry_of(c)
	if not elsewhere.is_empty() and elsewhere == e:
		elsewhere = {}
	var p := S.panel("ready" if chosen else "card", Vector4(18, 14, 18, 14))
	var h := S.hbox(14)
	p.add_child(h)
	h.add_child(S.portrait(c, 96, "rounded"))
	var mid := S.vbox(6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nr := S.hbox(10)
	nr.add_child(S.title(c.name, 28))
	nr.add_child(S.injury_chip(c.injury_level, 20))
	mid.add_child(nr)
	var stats := HFlowContainer.new()
	stats.add_theme_constant_override("h_separation", 6)
	stats.add_theme_constant_override("v_separation", 6)
	var fav := S.favored_index(e.quest)
	for i in 4:
		var st: Dictionary = S.STATS[i]
		stats.add_child(S.icon_chip(st.icon, str(c.stats[i]), st.bg, st.color, 22, i == fav))
	mid.add_child(stats)
	if not elsewhere.is_empty():
		mid.add_child(S.wrap(S.label("On \"%s\" · picking moves them" % elsewhere.quest.questTitle, 21, S.BLUE_TEXT, S.body_bold)))
	elif full:
		mid.add_child(S.label("Party is full", 21, S.INK_SOFT, S.body_bold))
	h.add_child(mid)
	var right := S.vbox(6)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var contrib: int = ui.chance_for(e, [c])
	var cl := S.title("+%d%%" % contrib, 30, S.GREEN_TEXT)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(cl)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(50, 50)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_theme_stylebox_override("panel", S.flat(Color("#3F7A2E") if chosen else S.CREAM, 10, 3, S.INK, Vector4(6, 6, 6, 6)))
	if chosen:
		box.add_child(S.icon("check", 34))
	right.add_child(box)
	h.add_child(right)
	var tap := S.tap_area(p)
	tap.disabled = full
	if full:
		p.modulate = Color(1, 1, 1, 0.55)
	tap.pressed.connect(toggle.bind(ui, c))
	return tap


static func toggle(ui, c: GuildCharacter) -> void:
	var e: Dictionary = ui.page.entry
	var n: int = ui.slot_count(e)
	var draft: Array = ui.page.draft
	if draft.has(c):
		draft.erase(c)
	elif n == 1:
		ui.page.draft = [c]
	elif draft.size() < n:
		draft.append(c)
	ui.queue_refresh()


static func dispatch(ui) -> void:
	var e: Dictionary = ui.page.entry
	if ui.page.draft.is_empty():
		return
	ui.set_party(e, ui.page.draft)
	ui.page = {}
	ui.toast("Party ready for %s" % e.quest.questTitle)
	ui.queue_refresh()
