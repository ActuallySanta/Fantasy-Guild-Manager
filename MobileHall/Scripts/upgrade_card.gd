## One building on the Upgrades tab: level pips, what it does now and next,
## and the Upgrade button (or why you can't yet).
## Scene: MobileHall/Scenes/Rows/upgrade_card.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

## Level pips: filled up to the current level.
const PIP_FILLED := Color("#1E88E5")
const PIP_EMPTY := Color("#E6E6E6")

# ---- TEXT
# Level and effect
const TEXT_LEVEL := "Level %d / %d"
const TEXT_NOW := "Now: %s"
const TEXT_NEXT := "Next: %s"
const TEXT_MAXED := "Fully upgraded"
# Button and status
const TEXT_BUTTON := "%d gold"
const TEXT_BUTTON_MAX := "Max"
const TEXT_NEED_GOLD := "Need %d more gold"
const TEXT_NEED_STANDING := "Needs standing %d"
const TEXT_READY := "Ready to build"

# ---- NODES
# Name and level
@onready var _tag_box: PanelContainer = %TagBox
@onready var _tag: Label = %Tag
@onready var _name: Label = %Name
@onready var _level: Label = %Level
@onready var _pips: HBoxContainer = %Pips
# Effect
@onready var _now: Label = %Now
@onready var _next: Label = %Next
# Button and status
@onready var _status: Label = %Status
@onready var _upgrade_button: Button = %UpgradeButton


## building = a GuildUpgrades.Building value.
func setup(hall: HallMain, building: int) -> void:
	_upgrade_button.pressed.connect(hall.upgrade_building.bind(building))
	var level := GuildUpgrades.get_level(building)
	var is_maxed := GuildUpgrades.is_max_level(building)
	_show_name_and_level(building, level)
	_show_effects(building, level, is_maxed)
	_show_status(building, is_maxed)


func _show_name_and_level(building: int, level: int) -> void:
	var tag_color: Color = GuildUpgrades.get_building_color(building).darkened(0.25)
	Style.style_tag(_tag_box, _tag, Style.BUILDING_TAGS.get(building, "?"), tag_color)
	_name.text = GuildUpgrades.get_building_name(building)
	_level.text = TEXT_LEVEL % [level, GuildUpgrades.MAX_LEVEL]
	# one pip per level, authored in the scene
	for pip_index in _pips.get_child_count():
		var pip: Panel = _pips.get_child(pip_index)
		var pip_color := PIP_FILLED if pip_index < level else PIP_EMPTY
		pip.add_theme_stylebox_override("panel", Style.flat_box(pip_color, 6, 2, Style.TEXT_MAIN))


## "Now: ..." and "Next: ..." (or "Fully upgraded").
func _show_effects(building: int, level: int, is_maxed: bool) -> void:
	_now.text = TEXT_NOW % GuildUpgrades.get_effect_text(building, level)
	if is_maxed:
		_next.text = TEXT_MAXED
	else:
		_next.text = TEXT_NEXT % GuildUpgrades.get_effect_text(building, level + 1)


## Button (cost or Max), the status line (ready / what's missing), and card colours.
func _show_status(building: int, is_maxed: bool) -> void:
	var status := GuildUpgrades.get_upgrade_status(building)
	var is_ready := status == GuildUpgrades.UpgradeStatus.READY

	if is_maxed:
		_upgrade_button.text = TEXT_BUTTON_MAX
	else:
		_upgrade_button.text = TEXT_BUTTON % GuildUpgrades.get_next_gold_cost(building)
	_upgrade_button.disabled = not is_ready
	Style.style_button(_upgrade_button, "green", 26)

	match status:
		GuildUpgrades.UpgradeStatus.READY:
			_status.text = TEXT_READY
			Style.set_font_color(_status, Style.GREEN_TEXT)
		GuildUpgrades.UpgradeStatus.NOT_ENOUGH_GOLD:
			_status.text = TEXT_NEED_GOLD % (GuildUpgrades.get_next_gold_cost(building) - GameState.gold)
			Style.set_font_color(_status, Style.GOLD_TEXT)
		GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW:
			_status.text = TEXT_NEED_STANDING % GuildUpgrades.get_next_standing_req(building)
			Style.set_font_color(_status, Style.RED)
		_:
			_status.text = ""
	_status.visible = _status.text != ""

	if is_ready:
		Style.style_panel(self, Style.SENT_CARD_BG, Style.GREEN, 4, 16)
	else:
		Style.style_panel(self, Style.CARD_BG, Style.BORDER, 2, 16)
