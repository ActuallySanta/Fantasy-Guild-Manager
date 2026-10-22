## Upgrades tab: the treasury ledger, then a building plan for everything you
## can spend on, affordable ones first. Buildings that don't do anything yet
## are shown as rolled-up scrolls on one line instead of full plans.
## Scene: MobileHall/Scenes/Tabs/tab_upgrades.tscn
extends ScrollContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const UpgradeCard := preload("res://MobileHall/Scenes/Rows/upgrade_card.tscn")
const RolledTag := preload("res://MobileHall/Scenes/Components/rolled_tag.tscn")

# ---- TEXT
const WALLET := "%d gold"
const STANDING := "· Standing %d"
const WALLET_HINT_READY := "You can afford %s. Quests pay for the rest."
const WALLET_HINT_NONE := "Nothing affordable yet. Quests earn gold."

# ---- NODES
@onready var _wallet: Label = %Wallet
@onready var _standing: Label = %Standing
@onready var _wallet_hint: Label = %WalletHint
@onready var _list: VBoxContainer = %List
@onready var _soon_box: Control = %SoonBox
@onready var _soon_row: HFlowContainer = %SoonRow

var ui


func setup(main) -> void:
	ui = main


func scroll_to_top() -> void:
	scroll_vertical = 0


func refresh() -> void:
	_wallet.text = WALLET % GameState.gold
	_standing.text = STANDING % GameState.standing
	var ups: Array = ui.upgradable()
	_wallet_hint.text = WALLET_HINT_READY % S.count(ups.size(), "upgrade", "upgrades") if not ups.is_empty() else WALLET_HINT_NONE
	S.color(_wallet_hint, S.GREEN_TEXT if not ups.is_empty() else S.INK_SOFT)

	S.clear(_list)
	var order: Array = S.buildings_in_order().filter(func(b): return GuildUpgrades.is_implemented(b))
	# affordable first
	order.sort_custom(func(a, b): return ups.has(a) and not ups.has(b))
	for b in order:
		S.add_row(_list, UpgradeCard).setup(ui, b)

	S.clear(_soon_row)
	for b in S.buildings_in_order():
		if not GuildUpgrades.is_implemented(b):
			S.add_row(_soon_row, RolledTag).get_node("Center/Tag/Text").text = GuildUpgrades.get_building_name(b)
	_soon_box.visible = _soon_row.get_child_count() > 0
