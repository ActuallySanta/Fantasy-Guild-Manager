## Upgrades bottom sheet (Scenes/Sheets/sheet_upgrades.tscn).
extends ColorRect

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const UpgradeRow := preload("res://MobileDeck/Scenes/Rows/upgrade_row.tscn")

var ui


func setup(main) -> void:
	ui = main
	%CloseButton.pressed.connect(func(): ui.close_sheet())


func refresh() -> void:
	%Wallet.text = "%d gold  ·  Standing %d" % [GameState.gold, GameState.standing]
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	S.clear(%UpgradeList)
	for b in order:
		S.add_row(%UpgradeList, UpgradeRow).setup(ui, b)
