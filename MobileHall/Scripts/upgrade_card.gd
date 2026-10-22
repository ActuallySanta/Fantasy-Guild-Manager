## One building on the Upgrades tab, drawn as a plan on grid paper: its icon,
## level diamonds, what it does now and next, and the Build button (or why you
## can't yet).
## Scene: MobileHall/Scenes/Rows/upgrade_card.tscn
extends PanelContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_LEVEL := "Level %d / %d"
const TEXT_NOW := "Now · %s"
const TEXT_NEXT := "Next · %s"
const TEXT_MAXED := "Fully built"
const TEXT_BUTTON := "Build · %d"
const TEXT_BUTTON_MAX := "Built"
const TEXT_NEED_GOLD := "need %d more gold"
const TEXT_NEED_STANDING := "needs standing %d"
const TEXT_READY := "ready to build"

# ---- NODES
@onready var _icon: TextureRect = %Icon
@onready var _name: Label = %Name
@onready var _level: Label = %Level
@onready var _pips: HBoxContainer = %Pips
@onready var _now: Label = %Now
@onready var _next: Label = %Next
@onready var _status: Label = %Status
@onready var _button: Button = %UpgradeButton


func setup(main, b: int) -> void:
	_button.pressed.connect(main.upgrade.bind(b))
	var lvl := GuildUpgrades.get_level(b)
	_icon.texture = S.icon_tex(S.BUILDINGS.get(b, {}).get("icon", ""))
	_name.text = GuildUpgrades.get_building_name(b)
	_level.text = TEXT_LEVEL % [lvl, GuildUpgrades.MAX_LEVEL]
	for i in _pips.get_child_count():
		_pips.get_child(i).texture = S.icon_tex("diamond" if i < lvl else "diamond_empty")
	_now.text = TEXT_NOW % GuildUpgrades.get_effect_text(b, lvl)
	var maxed := GuildUpgrades.is_max_level(b)
	_next.text = TEXT_MAXED if maxed else TEXT_NEXT % GuildUpgrades.get_effect_text(b, lvl + 1)
	_show_status(b, maxed)


func _show_status(b: int, maxed: bool) -> void:
	var status := GuildUpgrades.get_upgrade_status(b)
	var ready := status == GuildUpgrades.UpgradeStatus.READY
	_button.text = TEXT_BUTTON_MAX if maxed else TEXT_BUTTON % GuildUpgrades.get_next_gold_cost(b)
	_button.disabled = not ready
	match status:
		GuildUpgrades.UpgradeStatus.READY:
			_status.text = TEXT_READY
			S.color(_status, S.GREEN_TEXT)
		GuildUpgrades.UpgradeStatus.NOT_ENOUGH_GOLD:
			_status.text = TEXT_NEED_GOLD % (GuildUpgrades.get_next_gold_cost(b) - GameState.gold)
			S.color(_status, S.GOLD_TEXT)
		GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW:
			_status.text = TEXT_NEED_STANDING % GuildUpgrades.get_next_standing_req(b)
			S.color(_status, S.WAX)
		_:
			_status.text = ""
