## Upgrades bottom sheet: one row per building.
## Scene: MobileDeck/Scenes/Sheets/sheet_upgrades.tscn
extends ColorRect

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const Main := preload("res://MobileDeck/Scripts/deck_main.gd")
const UpgradeRow := preload("res://MobileDeck/Scenes/Rows/upgrade_row.tscn")

const TEXT_WALLET := "%d gold  ·  Standing %d"

@onready var _close_button: Button = %CloseButton
@onready var _wallet: Label = %Wallet
@onready var _upgrade_list: Container = %UpgradeList

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_close_button.pressed.connect(func(): ui.close_sheet())


func refresh() -> void:
	_wallet.text = TEXT_WALLET % [GameState.gold, GameState.standing]
	S.clear(_upgrade_list)
	for b in S.buildings_in_order():
		S.add_row(_upgrade_list, UpgradeRow).setup(ui, b)
