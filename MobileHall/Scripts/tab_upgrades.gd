## Upgrades tab: two clearly separate halves, switched with the buttons at the top.
##   Tonight - the Training Yard (who drills which stat) and the Hospital
##             (who's in a bed); the badge counts hurt heroes not in a bed
##   Build   - wallet, then one card per working building (affordable ones
##             first); the badge counts upgrades you can afford
## Buildings that don't do anything yet are folded into one "coming soon" line.
## Scene: MobileHall/Scenes/Tabs/tab_upgrades.tscn
extends VBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const UpgradeCardScene := preload("res://MobileHall/Scenes/Rows/upgrade_card.tscn")

# ---- TEXT
const SECTION_TONIGHT := "Tonight"
const SECTION_BUILD := "Build"
const WALLET := "%d gold · standing %d"
const WALLET_HINT_AFFORDABLE := "You can afford %s. Quests pay for the rest."
const WALLET_HINT_NONE := "Nothing affordable yet. Quests earn gold."
const COMING_SOON := "Coming soon: %s"

# ---- NODES
# Section buttons
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
@onready var _wallet_hint: Label = %WalletHint
@onready var _card_list: VBoxContainer = %List
@onready var _coming_soon: Label = %Soon

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


## The open half's button is dark; the closed one gets its badge.
func _show_section_buttons(is_tonight: bool, affordable: Array) -> void:
	Style.style_button(_tonight_button, "wood" if is_tonight else "paper", 26)
	Style.style_button(_build_button, "paper" if is_tonight else "wood", 26)
	var waiting: int = hall.hurt_waiting_count()
	_tonight_badge.visible = not is_tonight and waiting > 0
	_tonight_badge_text.text = str(waiting)
	_build_badge.visible = is_tonight and not affordable.is_empty()
	_build_badge_text.text = str(affordable.size())

# ---- Build


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


## "Coming soon: Office" for buildings that aren't implemented yet.
func _show_coming_soon() -> void:
	var names := PackedStringArray()
	for building in Style.buildings_in_order():
		if not GuildUpgrades.is_implemented(building):
			names.append(GuildUpgrades.get_building_name(building))
	_coming_soon.text = COMING_SOON % ", ".join(names)
	_coming_soon.visible = not names.is_empty()
