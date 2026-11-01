## Upgrades tab (the "Guild" nav button): a folder with two tabs.
##   Tonight - the Training Yard (who drills which stat) and the Hospital
##             (who's in a bed), each a building plan; the badge counts hurt
##             heroes not in a bed
##   Build   - the treasury ledger, then a building plan for every working
##             building (affordable ones first); the badge counts upgrades
##             you can afford
## Buildings that don't do anything yet are shown as rolled-up scrolls on one
## line instead of full plans.
## Scene: MobileHall/Scenes/Tabs/tab_upgrades.tscn
extends VBoxContainer

const UpgradeCardScene := preload("uid://bsodxki3j2b0o")  # MobileHall/Scenes/Rows/upgrade_card.tscn
const RolledTagScene := preload("uid://dvyjbi6emukey")  # MobileHall/Scenes/Components/rolled_tag.tscn

## Folder tab heights: the open one stands taller and joins the folder.
const FOLDER_TAB_HEIGHT := 72
const FOLDER_TAB_HEIGHT_OPEN := 80

# ---- TEXT
const SECTION_TONIGHT := "Tonight"
const SECTION_BUILD := "Build"
const WALLET := "%d gold"
const STANDING := "· Standing %d"
const WALLET_HINT_AFFORDABLE := "You can afford %s. Quests pay for the rest."
const WALLET_HINT_NONE := "Nothing affordable yet. Quests earn gold."

# ---- NODES
# Folder tabs
@onready var _tonight_button: Button = %SegTonight
@onready var _build_button: Button = %SegBuild
@onready var _tonight_badge: Control = %TonightBadge
@onready var _tonight_badge_text: Label = %TonightBadgeText
@onready var _build_badge: Control = %BuildBadge
@onready var _build_badge_text: Label = %BuildBadgeText
@onready var _scroll: ScrollContainer = %Scroll
# Tonight
@onready var _tonight_box: Control = %Tonight
@onready var _training_section = %TrainingSection   # home_section.gd
@onready var _hospital_section = %HospitalSection   # home_section.gd
# Build
@onready var _build_box: Control = %Build
@onready var _wallet: Label = %Wallet
@onready var _standing: Label = %Standing
@onready var _wallet_hint: Label = %WalletHint
@onready var _card_list: VBoxContainer = %List
@onready var _coming_soon_box: Control = %SoonBox
@onready var _coming_soon_row: HFlowContainer = %SoonRow

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_tonight_button.pressed.connect(func(): hall.show_upgrades_section(HallMain.UPGRADES_SECTION_TONIGHT))
	_build_button.pressed.connect(func(): hall.show_upgrades_section(HallMain.UPGRADES_SECTION_BUILD))
	_tonight_button.text = SECTION_TONIGHT
	_build_button.text = SECTION_BUILD
	_training_section.setup(hall, GuildUpgrades.Building.TRAINING_YARD)
	_hospital_section.setup(hall, GuildUpgrades.Building.HOSPITAL)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	var affordable: Array = hall.affordable_buildings()
	var is_tonight := hall.upgrades_section == HallMain.UPGRADES_SECTION_TONIGHT
	_show_section_buttons(is_tonight, affordable)
	_tonight_box.visible = is_tonight
	_build_box.visible = not is_tonight
	if is_tonight:
		_training_section.refresh()
		_hospital_section.refresh()
	else:
		_show_wallet(affordable)
		_show_building_cards(affordable)
		_show_coming_soon()


## The open folder tab is the lighter one that joins the folder below;
## the closed one gets its badge.
func _show_section_buttons(is_tonight: bool, affordable: Array) -> void:
	_tonight_button.theme_type_variation = &"FolderTabActive" if is_tonight else &"FolderTab"
	_build_button.theme_type_variation = &"FolderTab" if is_tonight else &"FolderTabActive"
	_tonight_button.custom_minimum_size.y = FOLDER_TAB_HEIGHT_OPEN if is_tonight else FOLDER_TAB_HEIGHT
	_build_button.custom_minimum_size.y = FOLDER_TAB_HEIGHT if is_tonight else FOLDER_TAB_HEIGHT_OPEN
	var waiting: int = hall.hurt_waiting_count()
	_tonight_badge.visible = not is_tonight and waiting > 0
	_tonight_badge_text.text = str(waiting)
	_build_badge.visible = is_tonight and not affordable.is_empty()
	_build_badge_text.text = str(affordable.size())

# ---- Build


## The treasury ledger: gold, standing, and how many upgrades that buys right now.
func _show_wallet(affordable: Array) -> void:
	_wallet.text = WALLET % GameState.gold
	_standing.text = STANDING % GameState.standing
	if affordable.is_empty():
		_wallet_hint.text = WALLET_HINT_NONE
		HallStyle.set_font_color(_wallet_hint, HallStyle.TEXT_SOFT)
	else:
		_wallet_hint.text = WALLET_HINT_AFFORDABLE % HallStyle.count_text(affordable.size(), "upgrade", "upgrades")
		HallStyle.set_font_color(_wallet_hint, HallStyle.GREEN_TEXT)


## One plan per working building, affordable ones first.
func _show_building_cards(affordable: Array) -> void:
	HallStyle.clear_children(_card_list)
	var buildings: Array = HallStyle.buildings_in_order().filter(func(building):
		return GuildUpgrades.is_implemented(building))
	buildings.sort_custom(func(first, second):
		return affordable.has(first) and not affordable.has(second))
	for building in buildings:
		HallStyle.add_row(_card_list, UpgradeCardScene).setup(hall, building)


## A rolled-up scroll for each building that isn't implemented yet.
func _show_coming_soon() -> void:
	HallStyle.clear_children(_coming_soon_row)
	for building in HallStyle.buildings_in_order():
		if not GuildUpgrades.is_implemented(building):
			var rolled_tag := HallStyle.add_row(_coming_soon_row, RolledTagScene)
			rolled_tag.get_node("Center/Tag/Text").text = GuildUpgrades.get_building_name(building)
	_coming_soon_box.visible = _coming_soon_row.get_child_count() > 0
