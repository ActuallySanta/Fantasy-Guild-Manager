## Day Report: the DaySummary popup as a full-screen ledger page. One entry per
## quest that went out, with the story from CreatedQuest.generateResults split
## into readable beats.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

## generateResults uses bright BBCode colours meant for a dark screen; swap
## them for inks that read on parchment.
const RECOLOR := {
	"[color=FFE700]": "[color=#7A5A12]", "[color=gold]": "[color=#7A5A12]",
	"[color=green]": "[color=#2F6A22]", "[color=FD0000]": "[color=#A3262A]", "[color=red]": "[color=#A3262A]",
}


static func build(ui) -> Control:
	var rep: Dictionary = ui.report
	var results: Array = rep.results
	var root := TextureRect.new()
	root.texture = S.tex("page_bg.png")
	root.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.stretch_mode = TextureRect.STRETCH_SCALE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := S.vbox(0)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(col)

	# --- wooden header with the banner
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", S.sbtex("wood_bar.png", 8, Vector4(18, 18, 18, 18)))
	var hv := S.vbox(6)
	head.add_child(hv)
	var banner := PanelContainer.new()
	var bsb := StyleBoxTexture.new()
	bsb.texture = S.tex("banner.png")
	bsb.texture_margin_left = 70
	bsb.texture_margin_right = 70
	bsb.texture_margin_top = 30
	bsb.texture_margin_bottom = 36
	bsb.content_margin_left = 80
	bsb.content_margin_right = 80
	bsb.content_margin_top = 10
	bsb.content_margin_bottom = 20
	banner.add_theme_stylebox_override("panel", bsb)
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	banner.custom_minimum_size = Vector2(480, 100)
	var bt := S.title("Day %d Report" % rep.day, 44)
	bt.add_theme_font_override("font", S.display_black)
	bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(bt)
	hv.add_child(banner)
	var total := 0
	for r in results:
		total += int(r.gold)
	var sub := "%d quest%s went out · +%d gold" % [results.size(), "" if results.size() == 1 else "s", total] if not results.is_empty() else "Nobody went out today"
	var sl := S.label(sub, 27, Color("#F6E2B0"), S.body_bold)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(sl)
	col.add_child(head)

	# --- entries
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var v := S.vbox(26)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := S.margin(v, 24, 24, 24, 30)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(m)
	for r in results:
		v.add_child(_entry(r))
	if results.is_empty():
		var p := S.panel("inset", Vector4(30, 40, 30, 40))
		var l := S.wrap(S.label("No quests went out today. The guild hall was very quiet.", 28, S.INK_SOFT))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		v.add_child(p)

	# --- footer
	var foot := PanelContainer.new()
	foot.add_theme_stylebox_override("panel", S.sbtex("inset_parchment.png", 26, Vector4(24, 16, 24, 16), 8))
	var live: bool = rep.get("live", false)
	var b := S.button("Start Day %d" % (GameState.day + 1) if live else "Close report", "green" if live else "paper", 34, 100)
	b.pressed.connect(ui.close_report)
	foot.add_child(b)
	col.add_child(foot)
	return root


static func _entry(r: Dictionary) -> Control:
	var p := S.panel("card", Vector4(24, 20, 24, 22))
	var v := S.vbox(14)
	p.add_child(v)
	var top := S.hbox(12)
	top.add_child(S.wrap(S.title(r.quest.questTitle, 30)))
	var ok: bool = r.succeeded
	var badge := S.chip("Success" if ok else "Failed", Color("#3F7A2E") if ok else S.WAX, S.WHITE, 24, false)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(badge)
	v.add_child(top)

	var party := S.hbox(10)
	var names := []
	for c in r.party:
		party.add_child(S.portrait(c, 64, "circle"))
		names.append(c.name)
	party.add_child(S.trim(S.label(" & ".join(PackedStringArray(names)), 26, S.INK, S.body_bold)))
	v.add_child(party)

	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 10)
	chips.add_theme_constant_override("v_separation", 8)
	chips.add_child(S.chip("%d%% chance" % mini(int(r.chance), 100), Color("#EAD6A8"), S.INK, 22))
	chips.add_child(S.icon_chip("coins", "+%d gold" % r.gold if r.gold > 0 else "No gold", Color("#F4E5AC"), S.GOLD_TEXT, 22))
	var injuries: int = r.story.count("INJURED")
	if injuries > 0:
		chips.add_child(S.icon_chip("injury", "%d injur%s" % [injuries, "y" if injuries == 1 else "ies"], Color("#F2CBC3"), Color("#8A1E22"), 22))
	else:
		chips.add_child(S.icon_chip("heart", "No injuries", Color("#D9E8CF"), Color("#2F5A27"), 22))
	v.add_child(chips)
	v.add_child(S.hline())

	var story: String = r.story
	for k in RECOLOR:
		story = story.replace(k, RECOLOR[k])
	for line in story.split("\n"):
		var t := line.strip_edges()
		if t == "":
			continue
		var row := S.hbox(12)
		var ic := "nav_quests"
		var tint := Color.WHITE
		if t.contains("INJUR"):
			ic = "injury"
		elif t.contains("chest"):
			ic = "coins"
		elif t.contains("without sustaining"):
			ic = "defense"
		elif t.begins_with("Summary"):
			ic = "check" if ok else "x"
			tint = S.GREEN_TEXT if ok else S.WAX
		elif t.begins_with("However"):
			ic = "coins"
		var icn := S.icon(ic, 34, tint)
		icn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(icn)
		row.add_child(S.rich(t, 25))
		v.add_child(row)
	return p
