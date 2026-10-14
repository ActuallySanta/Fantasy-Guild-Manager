## Day Report: the DaySummary popup as a full-screen ledger page. One entry per
## quest that went out, with the story from CreatedQuest.generateResults split
## into readable beats.
extends RefCounted

const S := preload("res://MobileDeck/Scripts/deck_style.gd")

## generateResults uses bright BBCode colours meant for a dark screen; map them
## to the UI's meaning colours (gold = gold, green = good, red = bad).
static func _strip_color(t: String) -> String:
	var map := {
		"[color=FFE700]": S.GOLD, "[color=gold]": S.GOLD, "[color=green]": S.GOOD,
		"[color=FD0000]": S.BAD, "[color=red]": S.BAD,
	}
	for k in map:
		t = t.replace(k, "[color=#%s]" % map[k].to_html(false))
	return t


static func build(ui) -> Control:
	var rep: Dictionary = ui.report
	var results: Array = rep.results
	var root := ColorRect.new()
	root.color = S.BG
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := S.vbox(0)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(col)

	var head := S.panel("panel", Vector4(16, 10, 16, 10))
	var hv := S.vbox(4)
	head.add_child(hv)
	hv.add_child(S.title("Day %d Report" % rep.day, 32))
	var total := 0
	for r in results:
		total += int(r.gold)
	var sub := "%d quest%s went out, +%d gold" % [results.size(), "" if results.size() == 1 else "s", total] if not results.is_empty() else "Nobody went out today"
	hv.add_child(S.label(sub, 24, S.INK_SOFT))
	col.add_child(head)

	# --- entries
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var v := S.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := S.margin(v, 16, 16, 16, 16)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(m)
	for r in results:
		v.add_child(_entry(r))
	if results.is_empty():
		var p := S.panel("inset")
		var l := S.wrap(S.label("No quests went out today. The guild hall was very quiet.", 28, S.INK_SOFT))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		v.add_child(p)

	# --- footer
	var foot := S.panel("bar", Vector4(16, 10, 16, 10))
	var live: bool = rep.get("live", false)
	var b := S.button("Start Day %d" % (GameState.day + 1) if live else "Close report", "green" if live else "", 26, 64)
	b.pressed.connect(ui.close_report)
	foot.add_child(b)
	col.add_child(foot)
	return root


static func _entry(r: Dictionary) -> Control:
	var p := S.panel("card")
	var v := S.vbox(8)
	p.add_child(v)
	var top := S.hbox(12)
	top.add_child(S.wrap(S.title(r.quest.questTitle, 26)))
	var ok: bool = r.succeeded
	var badge := S.chip("Success" if ok else "Failed", S.GOOD_BG if ok else S.BAD_BG, S.GOOD if ok else S.BAD)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(badge)
	v.add_child(top)

	var party := S.hbox(10)
	var names := []
	for c in r.party:
		party.add_child(S.portrait(c, 56))
		names.append(c.name)
	party.add_child(S.trim(S.label(" & ".join(PackedStringArray(names)), 26, S.INK)))
	v.add_child(party)

	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 10)
	chips.add_theme_constant_override("v_separation", 8)
	chips.add_child(S.chip("%d%% chance" % mini(int(r.chance), 100)))
	chips.add_child(S.icon_chip("coins", "+%d gold" % r.gold if r.gold > 0 else "No gold", S.GOLD_BG, S.GOLD))
	var injuries: int = r.story.count("INJURED")
	if injuries > 0:
		chips.add_child(S.chip("%d injur%s" % [injuries, "y" if injuries == 1 else "ies"], S.BAD_BG, S.BAD))
	else:
		chips.add_child(S.chip("No injuries", S.GOOD_BG, S.GOOD))
	v.add_child(chips)
	v.add_child(S.hline())

	var story: String = _strip_color(r.story)
	for line in story.split("\n"):
		var t := line.strip_edges()
		if t == "":
			continue
		v.add_child(S.rich(t, 22))
	return p
