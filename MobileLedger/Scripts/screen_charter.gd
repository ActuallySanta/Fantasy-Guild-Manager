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

	var root := ColorRect.new()
	root.color = S.BG
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
	var v := S.vbox(12)
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
	var sub := S.rich("[center]%s, %d Gold, Rank %s[/center]" % [type_name, q.goldReward, S.rank_letter(q)], 24)
	hv.add_child(sub)
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
			sv.add_child(S.portrait(c, 120))
			var nl := S.title(c.name, 28)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(nl)
			var rl := S.label("(tap to remove)", 20, S.INK_SOFT)
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(rl)
			var tap := S.tap_area(sv)
			tap.custom_minimum_size.x = 140
			tap.pressed.connect(toggle.bind(ui, c))
			slots.add_child(tap)
		else:
			var sv2 := S.vbox(6)
			var empty_slot := PanelContainer.new()
			empty_slot.custom_minimum_size = Vector2(120, 120)
			empty_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			empty_slot.add_theme_stylebox_override("panel", S.box("inset"))
			var el0 := S.label("Empty", 22, S.INK_SOFT)
			el0.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			el0.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_slot.add_child(el0)
			sv2.add_child(empty_slot)
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
	var pct := S.title("-- %" if ch < 0 else "%d%%" % mini(ch, 100), 40, o[1])
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
		var go := S.button("Go to For Hire", "blue", 28)
		go.pressed.connect(ui.open_tab.bind("characters", "hire"))
		ev2.add_child(go)
		v.add_child(empty)

	# --- dispatch
	var foot := S.panel("bar", Vector4(16, 10, 16, 10))
	var fv := S.vbox(4)
	foot.add_child(fv)
	var label := "Pick an adventurer"
	if not draft.is_empty():
		label = "Update Party" if e.state == "ready" else "Dispatch Party"
	var b := S.button(label, "green")
	b.disabled = draft.is_empty()
	b.pressed.connect(dispatch.bind(ui))
	fv.add_child(b)
	var fl := S.label("The party sets out when you end the day.", 22, S.INK_SOFT)
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fv.add_child(fl)
	col.add_child(foot)
	return root


## Back button + small banner title, shared by the full-screen pages.
static func top_bar(_ui, text: String, back: Callable) -> Control:
	var head := S.panel("panel", Vector4(16, 10, 16, 10))
	var h := S.hbox(16)
	head.add_child(h)
	var bb := S.button("< Back", "", 24, 56)
	bb.pressed.connect(back)
	h.add_child(bb)
	var t := S.title(text, 30)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	return head


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
	h.add_child(S.portrait(c, 80))
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
		stats.add_child(S.icon_chip(st.icon, "%s %d" % [st.short, c.stats[i]], st.bg, st.color, 20, i == fav))
	mid.add_child(stats)
	if not elsewhere.is_empty():
		mid.add_child(S.wrap(S.label("On \"%s\" · picking moves them" % elsewhere.quest.questTitle, 21, S.INFO)))
	elif full:
		mid.add_child(S.label("Party is full", 21, S.INK_SOFT))
	h.add_child(mid)
	var right := S.vbox(6)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var contrib: int = ui.chance_for(e, [c])
	var cl := S.label("+%d%%" % contrib, 24, S.GOOD)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(cl)
	var cb := CheckBox.new()
	cb.button_pressed = chosen
	cb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cb.focus_mode = Control.FOCUS_NONE
	cb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.add_child(cb)
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
