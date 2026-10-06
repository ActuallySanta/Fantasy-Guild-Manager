## Full-screen Guild Upgrades page, opened from the nav bar's Upgrades button
## (GuildUpgrades.open_page). Shows one UpgradeCard per building. Gold and
## standing are shown in the home screen's top bar, not on this page.
extends Control

const UPGRADE_CARD := preload("res://Scenes/UI/Upgrades/upgrade_card.tscn")

@onready var card_list: VBoxContainer = %CardList
@onready var debug_row: HBoxContainer = %DebugRow

var _cards: Array[UpgradeCard] = []


func _ready() -> void:
	# Working buildings first, "coming soon" ones after.
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	for building in order:
		var card: UpgradeCard = UPGRADE_CARD.instantiate()
		card.building = building
		card_list.add_child(card)
		_cards.append(card)

	GuildUpgrades.upgrades_changed.connect(refresh)
	GuildUpgrades.resources_changed.connect(refresh)
	visibility_changed.connect(_on_visibility_changed)

	debug_row.visible = GuildUpgrades.SHOW_DEBUG_BUTTONS
	%AddGoldButton.pressed.connect(GuildUpgrades.add_gold.bind(200))
	%AddStandingButton.pressed.connect(GuildUpgrades.add_standing.bind(1))
	%ResetButton.pressed.connect(GuildUpgrades.reset)

	refresh()


func refresh() -> void:
	for card in _cards:
		card.refresh()


func _on_visibility_changed() -> void:
	if visible:
		GuildUpgrades.sync_characters()
		refresh()
