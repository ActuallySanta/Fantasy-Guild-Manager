## Upgrades tab: one card per GuildUpgrades building. Working buildings first,
## "coming soon" ones faded, exactly as the upgrades page orders them.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")



static func build(ui) -> Control:
	var v := S.vbox(12)
	v.add_child(S.divider("Guild Upgrades", 38))
	var hint := S.wrap(S.label("Spend gold to raise a building. Higher levels also need Standing.", 25, S.INK_SOFT))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	for b in order:
		v.add_child(_card(ui, b))
	return v


static func _card(ui, b: int) -> Control:
	var lvl := GuildUpgrades.get_level(b)
	var status := GuildUpgrades.get_upgrade_status(b)
	var soon := status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED
	var p := S.panel("card", Vector4(24, 20, 24, 20))
	if soon:
		p.modulate = Color(1, 1, 1, 0.62)
	var v := S.vbox(14)
	p.add_child(v)

	var top := S.hbox(16)
	var mid := S.vbox(8)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nr := S.hbox(12)
	nr.add_child(S.title(GuildUpgrades.get_building_name(b), 32))
	var lv := S.label("Lv %d / %d" % [lvl, GuildUpgrades.MAX_LEVEL], 25, S.INK_SOFT)
	lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nr.add_child(lv)
	mid.add_child(nr)
	mid.add_child(S.gauge(float(lvl) / GuildUpgrades.MAX_LEVEL, S.INFO, 200))
	top.add_child(mid)
	if soon:
		top.add_child(S.chip("Coming soon", S.INFO_BG, S.INFO))
	v.add_child(top)

	v.add_child(S.rich("[b]Now:[/b] %s" % GuildUpgrades.get_effect_text(b, lvl), 26))
	var next_text := "Fully upgraded" if GuildUpgrades.is_max_level(b) else GuildUpgrades.get_effect_text(b, lvl + 1)
	v.add_child(S.rich("[b]Next:[/b] %s" % next_text, 26))
	v.add_child(S.hline())

	var bottom := S.hbox(12)
	if not GuildUpgrades.is_max_level(b):
		var cost := GuildUpgrades.get_next_gold_cost(b)
		var req := GuildUpgrades.get_next_standing_req(b)
		bottom.add_child(S.icon("coins", 40))
		bottom.add_child(S.label(str(cost), 26, S.GOLD if GameState.gold >= cost else S.BAD))
		bottom.add_child(S.icon("rook", 40))
		bottom.add_child(S.label(str(req), 26, S.INK if GameState.standing >= req else S.BAD))
	bottom.add_child(S.spacer())
	var label := "Upgrade"
	match status:
		GuildUpgrades.UpgradeStatus.NOT_ENOUGH_GOLD:
			label = "%d gold short" % (GuildUpgrades.get_next_gold_cost(b) - GameState.gold)
		GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW:
			label = "Needs Standing %d" % GuildUpgrades.get_next_standing_req(b)
		GuildUpgrades.UpgradeStatus.MAX_LEVEL:
			label = "Max level"
		GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED:
			label = "Coming soon"
	var btn := S.button(label, "green" if status == GuildUpgrades.UpgradeStatus.READY else "", 27, 84)
	btn.disabled = status != GuildUpgrades.UpgradeStatus.READY
	btn.pressed.connect(ui.upgrade.bind(b))
	bottom.add_child(btn)
	v.add_child(bottom)
	return p
