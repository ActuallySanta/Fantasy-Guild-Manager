## Upgrades tab: what you can spend on, buildings you can afford first.
## Buildings that don't do anything yet are folded into one "coming soon" line
## instead of full cards, to save scrolling.
## Scene: MobileHall/Scenes/Tabs/tab_upgrades.tscn
extends ScrollContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const UpgradeCardScene := preload("res://MobileHall/Scenes/Rows/upgrade_card.tscn")

# ---- TEXT
const WALLET := "%d gold · standing %d"
const WALLET_HINT_AFFORDABLE := "You can afford %s. Quests pay for the rest."
const WALLET_HINT_NONE := "Nothing affordable yet. Quests earn gold."
const COMING_SOON := "Coming soon: %s"

# ---- NODES
@onready var _wallet: Label = %Wallet
@onready var _wallet_hint: Label = %WalletHint
@onready var _card_list: VBoxContainer = %List
@onready var _coming_soon: Label = %Soon

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main


func scroll_to_top() -> void:
	scroll_vertical = 0


func refresh() -> void:
	var affordable: Array = hall.affordable_buildings()
	_show_wallet(affordable)
	_show_building_cards(affordable)
	_show_coming_soon()


## Gold and standing, plus how many upgrades that buys right now.
func _show_wallet(affordable: Array) -> void:
	_wallet.text = WALLET % [GameState.gold, GameState.standing]
	if affordable.is_empty():
		_wallet_hint.text = WALLET_HINT_NONE
		Style.set_font_color(_wallet_hint, Style.TEXT_SOFT)
	else:
		_wallet_hint.text = WALLET_HINT_AFFORDABLE % Style.count_text(affordable.size(), "upgrade", "upgrades")
		Style.set_font_color(_wallet_hint, Style.GREEN_TEXT)


## One card per working building, affordable ones first.
func _show_building_cards(affordable: Array) -> void:
	Style.clear_children(_card_list)
	var buildings: Array = Style.buildings_in_order().filter(func(building):
		return GuildUpgrades.is_implemented(building))
	buildings.sort_custom(func(first, second):
		return affordable.has(first) and not affordable.has(second))
	for building in buildings:
		Style.add_row(_card_list, UpgradeCardScene).setup(hall, building)


## "Coming soon: Hospital, ..." for buildings that aren't implemented yet.
func _show_coming_soon() -> void:
	var names := PackedStringArray()
	for building in Style.buildings_in_order():
		if not GuildUpgrades.is_implemented(building):
			names.append(GuildUpgrades.get_building_name(building))
	_coming_soon.text = COMING_SOON % ", ".join(names)
	_coming_soon.visible = not names.is_empty()
