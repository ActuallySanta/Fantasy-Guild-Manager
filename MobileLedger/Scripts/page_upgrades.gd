## Upgrades tab: one card per GuildUpgrades building. Working buildings first,
## "coming soon" ones faded, exactly as the upgrades page orders them.
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const UpgradeCard := preload("res://MobileLedger/Scenes/Rows/upgrade_card.tscn")

var ui


func setup(main) -> void:
	ui = main


func refresh() -> void:
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	S.clear(%UpgradeList)
	for b in order:
		S.add_row(%UpgradeList, UpgradeCard).setup(ui, b)
