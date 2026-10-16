## Upgrades tab: one card per GuildUpgrades building. Working buildings first,
## "coming soon" ones faded.
## Scene: MobileLedger/Scenes/Pages/page_upgrades.tscn
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")
const UpgradeCardScene := preload("res://MobileLedger/Scenes/Rows/upgrade_card.tscn")

@onready var _upgrade_list: Container = %UpgradeList

var ui: Main


func setup(main: Main) -> void:
	ui = main


func refresh() -> void:
	S.clear(_upgrade_list)
	for b in S.buildings_in_order():
		S.add_row(_upgrade_list, UpgradeCardScene).setup(ui, b)
