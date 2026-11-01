## One building on the Upgrades tab, drawn as a plan on grid paper: its icon,
## level diamonds, what it does now and next, and the Build button (or why you
## can't yet).
## Scene: MobileHall/Scenes/Rows/upgrade_card.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const Fx := preload("res://MobileHall/Scripts/hall_fx.gd")

# ---- MOTION
## Seconds after Build before the new level diamond stamps in (lets the
## building squash first).
const NEW_PIP_DELAY := 0.15

# ---- TEXT
# Level and effect
const TEXT_LEVEL := "Level %d / %d"
const TEXT_NOW := "Now · %s"
const TEXT_NEXT := "Next · %s"
const TEXT_MAXED := "Fully built"
# Button and status
const TEXT_BUTTON := "Build · %d"
const TEXT_BUTTON_MAX := "Built"
const TEXT_NEED_GOLD := "need %d more gold"
const TEXT_NEED_STANDING := "needs standing %d"
const TEXT_READY := "ready to build"

# ---- NODES
# Name and level
@onready var _icon: TextureRect = %Icon
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
	if hall.pending_fx.get("upgraded", -1) == building:
		_play_built(level)


## Just built: the building squashes and stretches, the new level's diamond
## stamps in, and "Level 3 / 5" pops.
func _play_built(level: int) -> void:
	Fx.squash(_icon.get_parent())
	if level >= 1 and level <= _pips.get_child_count():
		Fx.stamp_in(_pips.get_child(level - 1), 2.4, NEW_PIP_DELAY)
	Fx.pop(_level, 1.25, NEW_PIP_DELAY)
	Fx.pop(self, 1.03)


## Icon, name, "Level 2 / 5" and one diamond per level (filled up to the level).
func _show_name_and_level(building: int, level: int) -> void:
	_icon.texture = Style.icon_texture(Style.BUILDING_ICONS.get(building, ""))
	_name.text = GuildUpgrades.get_building_name(building)
	_level.text = TEXT_LEVEL % [level, GuildUpgrades.MAX_LEVEL]
	# one diamond per level, authored in the scene
	for pip_index in _pips.get_child_count():
		var pip: TextureRect = _pips.get_child(pip_index)
		pip.texture = Style.icon_texture("diamond" if pip_index < level else "diamond_empty")


## "Now · ..." and "Next · ..." (or "Fully built").
func _show_effects(building: int, level: int, is_maxed: bool) -> void:
	_now.text = TEXT_NOW % GuildUpgrades.get_effect_text(building, level)
	if is_maxed:
		_next.text = TEXT_MAXED
	else:
		_next.text = TEXT_NEXT % GuildUpgrades.get_effect_text(building, level + 1)


## Build button (cost or Built) and the status line (ready / what's missing).
func _show_status(building: int, is_maxed: bool) -> void:
	var status := GuildUpgrades.get_upgrade_status(building)
	var is_ready := status == GuildUpgrades.UpgradeStatus.READY

	if is_maxed:
		_upgrade_button.text = TEXT_BUTTON_MAX
	else:
		_upgrade_button.text = TEXT_BUTTON % GuildUpgrades.get_next_gold_cost(building)
	_upgrade_button.disabled = not is_ready

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
