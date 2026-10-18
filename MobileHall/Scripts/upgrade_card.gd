## One building on the Upgrades tab: level pips, what it does now and next,
## and the Upgrade button (or why you can't yet).
## Scene: MobileHall/Scenes/Rows/upgrade_card.tscn
extends PanelContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

const PIP_ON := Color("#1E88E5")
const PIP_OFF := Color("#E6E6E6")

# ---- TEXT
const TEXT_LEVEL := "Level %d / %d"
const TEXT_NOW := "Now: %s"
const TEXT_NEXT := "Next: %s"
const TEXT_MAXED := "Fully upgraded"
const TEXT_BUTTON := "%d gold"
const TEXT_BUTTON_MAX := "Max"
const TEXT_NEED_GOLD := "Need %d more gold"
const TEXT_NEED_STANDING := "Needs standing %d"
const TEXT_READY := "Ready to build"

# ---- NODES
@onready var _tag_box: PanelContainer = %TagBox
@onready var _tag: Label = %Tag
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
	S.style_tag(_tag_box, _tag, S.BUILDING_TAGS.get(b, "?"), GuildUpgrades.get_building_color(b).darkened(0.25))
	_name.text = GuildUpgrades.get_building_name(b)
	_level.text = TEXT_LEVEL % [lvl, GuildUpgrades.MAX_LEVEL]
	for i in _pips.get_child_count():
		var pip: Panel = _pips.get_child(i)
		pip.add_theme_stylebox_override("panel", S.flat(PIP_ON if i < lvl else PIP_OFF, 6, 2, S.INK))
	_now.text = TEXT_NOW % GuildUpgrades.get_effect_text(b, lvl)
	var maxed := GuildUpgrades.is_max_level(b)
	_next.text = TEXT_MAXED if maxed else TEXT_NEXT % GuildUpgrades.get_effect_text(b, lvl + 1)
	_show_status(b, maxed)


func _show_status(b: int, maxed: bool) -> void:
	var status := GuildUpgrades.get_upgrade_status(b)
	var ready := status == GuildUpgrades.UpgradeStatus.READY
	_button.text = TEXT_BUTTON_MAX if maxed else TEXT_BUTTON % GuildUpgrades.get_next_gold_cost(b)
	_button.disabled = not ready
	S.style_button(_button, "green", 26)
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
	_status.visible = _status.text != ""
	if ready:
		S.style_panel(self, Color("#E8F5E9"), S.GREEN, 4, 16)
	else:
		S.style_panel(self, S.CREAM, S.LINE, 2, 16)
