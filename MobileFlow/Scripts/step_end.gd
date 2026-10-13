## Step 3: End Day. Today's plan at a glance, upgrades to spend gold on, and
## the End Day button (locked until every quest is decided).
extends RefCounted

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


static func build(ui) -> Dictionary:
	var v := S.vbox(14)
	var out: int = ui.outstanding()
	v.add_child(S.heading("End the day", "Check today's plan, spend gold on upgrades, then end the day."))

	# --- today's plan
	var plan := S.panel("card")
	var pv := S.vbox(6)
	plan.add_child(pv)
	pv.add_child(S.title("Today's plan", 24))
	for i in ui.entries.size():
		var e: Dictionary = ui.entries[i]
		var row := S.hbox(10)
		row.custom_minimum_size.y = 52
		var t := S.trim(S.label(e.quest.questTitle, 22))
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(t)
		match e.state:
			"ready":
				var names := []
				for c in e.party:
					names.append(c.name)
				row.add_child(S.chip("%s, %d%%" % [", ".join(PackedStringArray(names)), mini(ui.chance_for(e, e.party), 100)], S.GOOD_BG, S.GOOD, 18))
			"denied":
				row.add_child(S.chip("Denied", S.BAD_BG, S.BAD, 18))
			_:
				row.add_child(S.chip("Not decided", S.WARN_BG, S.WARN, 18))
		var tap := S.tap_area(row, 52)
		tap.pressed.connect(ui.show_quest.bind(i))
		pv.add_child(tap)
		if i < ui.entries.size() - 1:
			pv.add_child(S.hline())
	v.add_child(plan)

	# --- upgrades
	v.add_child(S.heading("Upgrades", "You have %d gold and Standing %d." % [GameState.gold, GameState.standing]))
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	for b in order:
		v.add_child(upgrade_row(ui, b))

	if not ui.last_report.is_empty():
		var lr := S.button("Read last night's report", "", 22, 52)
		lr.pressed.connect(ui.open_last_report)
		v.add_child(lr)

	# --- footer
	var f := S.vbox(4)
	if out > 0:
		var w := S.label("Decide %d more quest%s before ending the day." % [out, "" if out == 1 else "s"], 20, S.WARN)
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		f.add_child(w)
		var back := S.button("Back to quests", "blue", 26)
		back.pressed.connect(ui.go_step.bind("quests"))
		f.add_child(back)
	else:
		var going: int = ui.ready_entries().size()
		var info := S.label("%d part%s will set out." % [going, "y" if going == 1 else "ies"] if going > 0 else "Nobody is going out today.", 20, S.INK_SOFT)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		f.add_child(info)
		var b := S.button("End Day %d" % GameState.day, "green", 26)
		b.pressed.connect(ui.end_day)
		f.add_child(b)
	return {"body": v, "footer": f}


## One compact row per building: level, next effect, cost, Upgrade button.
static func upgrade_row(ui, b: int) -> Control:
	var lvl := GuildUpgrades.get_level(b)
	var status := GuildUpgrades.get_upgrade_status(b)
	var soon := status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED
	var p := S.panel("card")
	if soon:
		p.modulate = Color(1, 1, 1, 0.55)
	var v := S.vbox(6)
	p.add_child(v)
	var top := S.hbox(10)
	top.add_child(S.title(GuildUpgrades.get_building_name(b), 24))
	var lv := S.label("Lv %d/%d" % [lvl, GuildUpgrades.MAX_LEVEL], 20, S.INK_SOFT)
	lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(lv)
	top.add_child(S.spacer())
	if soon:
		top.add_child(S.chip("Coming soon", S.INFO_BG, S.INFO, 18))
	v.add_child(top)
	v.add_child(S.rich("[b]Now:[/b] %s" % GuildUpgrades.get_effect_text(b, lvl), 20))
	if not GuildUpgrades.is_max_level(b):
		v.add_child(S.rich("[b]Next:[/b] %s" % GuildUpgrades.get_effect_text(b, lvl + 1), 20))
	var bottom := S.hbox(8)
	if not GuildUpgrades.is_max_level(b):
		var cost := GuildUpgrades.get_next_gold_cost(b)
		var req := GuildUpgrades.get_next_standing_req(b)
		var ok_gold := GameState.gold >= cost
		var ok_st := GameState.standing >= req
		bottom.add_child(S.icon_chip("coins", "%d gold" % cost, S.GOLD_BG if ok_gold else S.BAD_BG, S.GOLD if ok_gold else S.BAD, 18))
		bottom.add_child(S.icon_chip("rook", "Standing %d" % req, S.BOX_ALT if ok_st else S.BAD_BG, S.INK if ok_st else S.BAD, 18))
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
	var btn := S.button(label, "green" if status == GuildUpgrades.UpgradeStatus.READY else "", 20, 48)
	btn.disabled = status != GuildUpgrades.UpgradeStatus.READY
	btn.pressed.connect(ui.upgrade.bind(b))
	bottom.add_child(btn)
	v.add_child(bottom)
	return p
