## Upgrades tab: one card per GuildUpgrades building. Working buildings first,
## "coming soon" ones faded, exactly as the upgrades page orders them.
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

## Keyed by GuildUpgrades.Building (OFFICE, TRAINING_YARD, HOSPITAL, ARMORY, BARRACKS).
const ICONS := {0: "office", 1: "training", 2: "hospital", 3: "armory", 4: "barracks"}


static func build(ui) -> Control:
	var v := S.vbox(26)
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
	var color := GuildUpgrades.get_building_color(b)
	var status := GuildUpgrades.get_upgrade_status(b)
	var soon := status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED
	var p := S.panel("card", Vector4(24, 20, 24, 20))
	if soon:
		p.modulate = Color(1, 1, 1, 0.62)
	var v := S.vbox(14)
	p.add_child(v)

	var top := S.hbox(16)
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(96, 96)
	tile.add_theme_stylebox_override("panel", S.flat(color, 20, 3, S.INK, Vector4(10, 10, 10, 10)))
	var ic := S.icon(ICONS.get(b, "rook"), 66)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.add_child(ic)
	top.add_child(tile)
	var mid := S.vbox(8)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nr := S.hbox(12)
	nr.add_child(S.title(GuildUpgrades.get_building_name(b), 32))
	var lv := S.label("Lv %d / %d" % [lvl, GuildUpgrades.MAX_LEVEL], 25, S.INK_SOFT, S.body_bold)
	lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nr.add_child(lv)
	mid.add_child(nr)
	var pips := S.hbox(8)
	for i in GuildUpgrades.MAX_LEVEL:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(0, 18)
		pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pip.add_theme_stylebox_override("panel", S.flat(color if i < lvl else Color("#E2CC9C"), 6, 2, S.INK))
		pips.add_child(pip)
	mid.add_child(pips)
	top.add_child(mid)
	if soon:
		top.add_child(S.chip("Coming soon", S.INK, Color("#F3E4C2"), 20, false))
	v.add_child(top)

	v.add_child(S.rich("[b]Now:[/b] %s" % GuildUpgrades.get_effect_text(b, lvl), 26))
	var next_text := "Fully upgraded" if GuildUpgrades.is_max_level(b) else GuildUpgrades.get_effect_text(b, lvl + 1)
	v.add_child(S.rich("[color=#2F6A22][b]Next:[/b] %s[/color]" % next_text, 26))
	v.add_child(S.hline())

	var bottom := S.hbox(12)
	if not GuildUpgrades.is_max_level(b):
		var cost := GuildUpgrades.get_next_gold_cost(b)
		var req := GuildUpgrades.get_next_standing_req(b)
		bottom.add_child(S.icon("coins", 40))
		bottom.add_child(S.title(str(cost), 30, S.INK if GameState.gold >= cost else S.WAX))
		bottom.add_child(S.icon("rook", 40))
		bottom.add_child(S.title(str(req), 30, S.INK if GameState.standing >= req else S.WAX))
	bottom.add_child(S.spacer())
	var label := "Upgrade"
	var kind := "green"
	match status:
		GuildUpgrades.UpgradeStatus.NOT_ENOUGH_GOLD:
			label = "%d gold short" % (GuildUpgrades.get_next_gold_cost(b) - GameState.gold)
		GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW:
			label = "Needs Standing %d" % GuildUpgrades.get_next_standing_req(b)
		GuildUpgrades.UpgradeStatus.MAX_LEVEL:
			label = "Max level"
			kind = "wood"
		GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED:
			label = "Coming soon"
	var btn := S.button(label, kind, 27, 84)
	btn.disabled = status != GuildUpgrades.UpgradeStatus.READY
	btn.pressed.connect(ui.upgrade.bind(b))
	bottom.add_child(btn)
	v.add_child(bottom)
	return p
