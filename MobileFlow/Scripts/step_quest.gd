## Step 2: Quests. One quest per screen with the party picker right under it.
## Send or Deny moves straight on to the next undecided quest.
extends RefCounted

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


static func build(ui) -> Dictionary:
	var v := S.vbox(14)
	var e: Dictionary = ui.current_entry()
	if e.is_empty():
		v.add_child(S.heading("No quests today"))
		var nb := S.button("Next: End Day  >", "green")
		nb.pressed.connect(ui.go_step.bind("end"))
		return {"body": v, "footer": nb}

	var q: CreatedQuest = e.quest
	var n: int = ui.slot_count(e)
	var decided: bool = e.state != "open"

	# --- which quest of today's board this is
	var nav := S.hbox(8)
	nav.add_child(S.label("Quest %d of %d" % [ui.quest_index + 1, ui.entries.size()], 22, S.INK_SOFT))
	nav.add_child(S.spacer())
	for i in ui.entries.size():
		nav.add_child(_dot(ui, i))
	v.add_child(nav)

	# --- the quest
	var card := S.panel("card")
	var cv := S.vbox(8)
	card.add_child(cv)
	var milestone: bool = e.get("milestone", false)
	cv.add_child(S.wrap(S.title(q.questTitle, 30, S.BAD if milestone else S.INK)))
	var type_name: String = "Milestone" if milestone else S.TYPE_NAMES.get(int(q.type), "Quest")
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	chips.add_child(S.chip("%s, Rank %s" % [type_name, S.rank_letter(q)]))
	chips.add_child(S.icon_chip("coins", "%d gold" % q.goldReward, S.GOLD_BG, S.GOLD))
	chips.add_child(S.chip("Solo" if n == 1 else "Party of up to %d" % n))
	cv.add_child(chips)
	var fi := S.favored_index(q)
	var st: Dictionary = S.STATS[fi]
	var fav := S.hbox(8)
	fav.add_child(S.label("Favored stat:", 22))
	fav.add_child(S.icon_chip("", st.name, st.bg, st.color, 22, true))
	fav.add_child(S.label("(counts twice)" if fi < 4 else "(Pluck doesn't change the odds)", 20, S.INK_SOFT))
	cv.add_child(fav)
	if milestone:
		cv.add_child(S.wrap(S.label("The Bone Drake is attacking. This is today's only quest.", 22, S.BAD)))
	v.add_child(card)

	# --- decision already made?
	if decided:
		var ok: bool = e.state == "ready"
		var dp := PanelContainer.new()
		dp.add_theme_stylebox_override("panel", S.flat(S.GOOD_BG if ok else S.BAD_BG, 0, 1, S.GOOD if ok else S.BAD, Vector4(14, 10, 14, 10)))
		var names := []
		for c in e.party:
			names.append(c.name)
		var txt := "Party set: %s. They leave when the day ends." % ", ".join(PackedStringArray(names)) if ok else "You denied this quest."
		dp.add_child(S.wrap(S.label(txt, 22, S.GOOD if ok else S.BAD)))
		v.add_child(dp)

	# --- party slots + odds
	var odds_box := S.panel("inset")
	var ov := S.vbox(8)
	odds_box.add_child(ov)
	var party: Array = e.party if decided else ui.draft
	var slots := S.hbox(10)
	for i in n:
		if i < party.size():
			var sv := S.vbox(2)
			sv.add_child(S.portrait(party[i], 76))
			var nl := S.label(party[i].name, 18)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(nl)
			slots.add_child(sv)
		else:
			var empty := PanelContainer.new()
			empty.custom_minimum_size = Vector2(76, 76)
			empty.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			empty.add_theme_stylebox_override("panel", S.flat(S.BOX, 0, 1, S.LINE))
			var el := S.label("Empty", 18, S.INK_SOFT)
			el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			el.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.add_child(el)
			slots.add_child(empty)
	var ch: int = ui.chance_for(e, party)
	var o: Array = S.odds(ch)
	var pv := S.vbox(4)
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_child(S.label("Chance of success", 20, S.INK_SOFT))
	var pr := S.hbox(10)
	pr.add_child(S.title("--" if ch < 0 else "%d%%" % mini(ch, 100), 36, o[1]))
	var wl := S.label(o[0], 22, o[1])
	wl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pr.add_child(wl)
	pv.add_child(pr)
	var g := S.gauge(0.0 if ch < 0 else minf(ch, 100) / 100.0, o[2], 200)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_child(g)
	slots.add_child(pv)
	ov.add_child(slots)
	v.add_child(odds_box)

	# --- party picker
	var roster: Array = CharacterContainer.active_characters.duplicate()
	if roster.is_empty():
		var p := S.panel("inset")
		var pv2 := S.vbox(8)
		p.add_child(pv2)
		pv2.add_child(S.wrap(S.label("You have nobody to send. Hire adventurers first (it's free).", 22)))
		var hb := S.button("Go to Hire", "blue", 22, 52)
		hb.pressed.connect(ui.go_step.bind("hire"))
		pv2.add_child(hb)
		v.add_child(p)
	elif not decided:
		v.add_child(S.heading("Pick your party", "Tap to add or remove. Best fit for this quest first."))
		roster.sort_custom(func(a, b): return _score(q, a) > _score(q, b))
		for c in roster:
			v.add_child(_pick_row(ui, e, c, n))

	# --- footer
	var f := S.hbox(10)
	if decided:
		var change := S.button("Change decision", "", 22)
		change.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		change.pressed.connect(ui.reopen_quest)
		f.add_child(change)
		var nxt := S.button("Next  >", "blue", 22)
		nxt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nxt.pressed.connect(ui._advance)
		f.add_child(nxt)
	else:
		var deny := S.button("Deny", "red", 24)
		deny.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		deny.pressed.connect(ui.deny_quest)
		f.add_child(deny)
		var send := S.button("Send party" if not ui.draft.is_empty() else "Pick a party first", "green" if not ui.draft.is_empty() else "", 24)
		send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		send.size_flags_stretch_ratio = 1.6
		send.disabled = ui.draft.is_empty()
		send.pressed.connect(ui.send_party)
		f.add_child(send)
	return {"body": v, "footer": f}


## Small square per quest: grey = undecided, green = party set, red = denied.
static func _dot(ui, i: int) -> Control:
	var e: Dictionary = ui.entries[i]
	var fill: Color = {"open": S.BOX, "ready": S.GOOD_BG, "denied": S.BAD_BG}[e.state]
	var current: bool = i == ui.quest_index
	var b := Button.new()
	b.text = str(i + 1)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(44, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := S.flat(fill, 0, 1, S.INFO if current else S.LINE, Vector4(0, 0, 0, 0))
	sb.set_border_width_all(3 if current else 1)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", 18)
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(st, S.INK)
	b.pressed.connect(ui.show_quest.bind(i))
	return b


static func _pick_row(ui, e: Dictionary, c: GuildCharacter, n: int) -> Control:
	var chosen: bool = ui.draft.has(c)
	var full: bool = not chosen and n > 1 and ui.draft.size() >= n
	var elsewhere: Dictionary = ui.entry_of(c)
	if not elsewhere.is_empty() and elsewhere == e:
		elsewhere = {}
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", S.flat(S.INFO_BG if chosen else S.BOX, 0, 1, S.INFO if chosen else S.LINE, Vector4(12, 10, 12, 10)))
	var h := S.hbox(12)
	p.add_child(h)
	var cb := CheckBox.new()
	cb.button_pressed = chosen
	cb.focus_mode = Control.FOCUS_NONE
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cb)
	h.add_child(S.portrait(c, 64))
	var mid := S.vbox(4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nr := S.hbox(8)
	nr.add_child(S.label(c.name, 24))
	nr.add_child(S.injury_chip(c.injury_level, 18))
	mid.add_child(nr)
	mid.add_child(S.stat_row(c, S.favored_index(e.quest), false, 18))
	if not elsewhere.is_empty():
		mid.add_child(S.wrap(S.label("Already on \"%s\". Picking moves them here." % elsewhere.quest.questTitle, 18, S.INFO)))
	elif full:
		mid.add_child(S.label("Party is full", 18, S.INK_SOFT))
	h.add_child(mid)
	var add := S.label("+%d%%" % ui.chance_for(e, [c]), 22, S.GOOD)
	add.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(add)
	var tap := S.tap_area(p)
	tap.disabled = full
	if full:
		p.modulate = Color(1, 1, 1, 0.5)
	tap.pressed.connect(ui.toggle_draft.bind(c))
	return tap


## Same total CreatedQuest.calcSuccessChance uses: all four stats, favored one twice.
static func _score(q: CreatedQuest, c: GuildCharacter) -> int:
	var s: Dictionary = c.stats
	var total: int = s[0] + s[1] + s[2] + s[3]
	var f := S.favored_index(q)
	if f < 4:
		total += s[f]
	return total
