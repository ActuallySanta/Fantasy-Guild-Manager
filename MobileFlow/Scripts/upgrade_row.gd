## One building (Rows/upgrade_row.tscn): level, now/next effect, cost, Upgrade button.
extends PanelContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


func setup(ui, b: int) -> void:
	var lvl := GuildUpgrades.get_level(b)
	var status := GuildUpgrades.get_upgrade_status(b)
	var soon := status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED
	modulate = Color(1, 1, 1, 0.55) if soon else Color.WHITE
	%BuildingName.text = GuildUpgrades.get_building_name(b)
	%Level.text = "Lv %d/%d" % [lvl, GuildUpgrades.MAX_LEVEL]
	%SoonChip.visible = soon
	%Now.text = "[b]Now:[/b] %s" % GuildUpgrades.get_effect_text(b, lvl)
	var maxed := GuildUpgrades.is_max_level(b)
	%Next.visible = not maxed
	%CostChip.visible = not maxed
	%StandingChip.visible = not maxed
	if not maxed:
		%Next.text = "[b]Next:[/b] %s" % GuildUpgrades.get_effect_text(b, lvl + 1)
		var cost := GuildUpgrades.get_next_gold_cost(b)
		var req := GuildUpgrades.get_next_standing_req(b)
		var ok_gold := GameState.gold >= cost
		var ok_st := GameState.standing >= req
		%CostChip.set_icon_chip("coins", "%d gold" % cost, S.GOLD_BG if ok_gold else S.BAD_BG, S.GOLD if ok_gold else S.BAD)
		%StandingChip.set_icon_chip("rook", "Standing %d" % req, S.BOX_ALT if ok_st else S.BAD_BG, S.INK if ok_st else S.BAD)
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
	%UpgradeButton.text = label
	S.style_button(%UpgradeButton, "green" if status == GuildUpgrades.UpgradeStatus.READY else "")
	%UpgradeButton.disabled = status != GuildUpgrades.UpgradeStatus.READY
	%UpgradeButton.pressed.connect(ui.upgrade.bind(b))
