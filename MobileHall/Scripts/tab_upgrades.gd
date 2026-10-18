## Upgrades tab: what you can spend on, buildings you can afford first.
## Buildings that don't do anything yet are folded into one "coming soon" line
## instead of full cards, to save scrolling.
## Scene: MobileHall/Scenes/Tabs/tab_upgrades.tscn
extends ScrollContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const UpgradeCard := preload("res://MobileHall/Scenes/Rows/upgrade_card.tscn")

# ---- TEXT
const WALLET := "%d gold · standing %d"
const WALLET_HINT_READY := "You can afford %s. Quests pay for the rest."
const WALLET_HINT_NONE := "Nothing affordable yet. Quests earn gold."
const SOON := "Coming soon: %s"

# ---- NODES
@onready var _wallet: Label = %Wallet
@onready var _wallet_hint: Label = %WalletHint
@onready var _list: VBoxContainer = %List
@onready var _soon: Label = %Soon

var ui


func setup(main) -> void:
	ui = main


func scroll_to_top() -> void:
	scroll_vertical = 0


func refresh() -> void:
	_wallet.text = WALLET % [GameState.gold, GameState.standing]
	var ups: Array = ui.upgradable()
	_wallet_hint.text = WALLET_HINT_READY % S.count(ups.size(), "upgrade", "upgrades") if not ups.is_empty() else WALLET_HINT_NONE
	S.color(_wallet_hint, S.GREEN_TEXT if not ups.is_empty() else S.INK_SOFT)

	S.clear(_list)
	var order: Array = S.buildings_in_order().filter(func(b): return GuildUpgrades.is_implemented(b))
	# affordable first
	order.sort_custom(func(a, b): return ups.has(a) and not ups.has(b))
	for b in order:
		S.add_row(_list, UpgradeCard).setup(ui, b)

	var soon := PackedStringArray()
	for b in S.buildings_in_order():
		if not GuildUpgrades.is_implemented(b):
			soon.append(GuildUpgrades.get_building_name(b))
	_soon.text = SOON % ", ".join(soon)
	_soon.visible = not soon.is_empty()
