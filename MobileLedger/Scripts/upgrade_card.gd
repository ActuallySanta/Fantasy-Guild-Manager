## One building on the Upgrades tab (Scenes/Rows/upgrade_card.tscn).
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

## Keyed by GuildUpgrades.Building (OFFICE, TRAINING_YARD, HOSPITAL, ARMORY, BARRACKS).
const ICONS := {0: "office", 1: "training", 2: "hospital", 3: "armory", 4: "barracks"}


func setup(ui, b: int) -> void:
	var lvl := GuildUpgrades.get_level(b)
	var color := GuildUpgrades.get_building_color(b)
	var status := GuildUpgrades.get_upgrade_status(b)
	var soon := status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED
	modulate = Color(1, 1, 1, 0.62) if soon else Color.WHITE
	%Tile.add_theme_stylebox_override("panel", S.flat(color, 20, 3, S.INK, Vector4(10, 10, 10, 10)))
	%Icon.texture = S.icon_tex(ICONS.get(b, "rook"))
	%BuildingName.text = GuildUpgrades.get_building_name(b)
	%Level.text = "Lv %d / %d" % [lvl, GuildUpgrades.MAX_LEVEL]
	for i in GuildUpgrades.MAX_LEVEL:
		var pip := %Pips.get_child(i) as Panel
		if pip:
			pip.add_theme_stylebox_override("panel", S.flat(color if i < lvl else Color("#E2CC9C"), 6, 2, S.INK))
	%SoonChip.visible = soon
	%Now.text = "[b]Now:[/b] %s" % GuildUpgrades.get_effect_text(b, lvl)
	var next_text := "Fully upgraded" if GuildUpgrades.is_max_level(b) else GuildUpgrades.get_effect_text(b, lvl + 1)
	%Next.text = "[color=#2F6A22][b]Next:[/b] %s[/color]" % next_text

	var maxed := GuildUpgrades.is_max_level(b)
	for n in [%CoinIcon, %Cost, %RookIcon, %Requirement]:
		n.visible = not maxed
	if not maxed:
		var cost := GuildUpgrades.get_next_gold_cost(b)
		var req := GuildUpgrades.get_next_standing_req(b)
		%Cost.text = str(cost)
		%Cost.add_theme_color_override("font_color", S.INK if GameState.gold >= cost else S.WAX)
		%Requirement.text = str(req)
		%Requirement.add_theme_color_override("font_color", S.INK if GameState.standing >= req else S.WAX)
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
	%UpgradeButton.text = label
	S.style_button(%UpgradeButton, kind, 27)
	%UpgradeButton.disabled = status != GuildUpgrades.UpgradeStatus.READY
	%UpgradeButton.pressed.connect(ui.upgrade.bind(b))
