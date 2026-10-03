## One building row on the upgrades page: level pips, current / next effect,
## cost, and the upgrade button. Reads everything from the GuildUpgrades autoload.
class_name UpgradeCard
extends PanelContainer

const PIP_SIZE := Vector2(40, 14)
const PIP_EMPTY := Color(0.91, 0.86, 0.78)
const BUTTON_READY := Color(0.21087831, 0.7186899, 0, 1)
const BUTTON_BLOCKED := Color(0.45, 0.42, 0.40, 1)
const BUTTON_LOCKED := Color(0.12, 0.08, 0.05, 1)
const BUTTON_MAX := Color(0.96, 0.73, 0.23, 1)

## A GuildUpgrades.Building value. Set before adding to the tree.
var building: int = 0

@onready var icon: ColorRect = %Icon
@onready var icon_letter: Label = %IconLetter
@onready var name_label: Label = %NameLabel
@onready var pip_row: HBoxContainer = %PipRow
@onready var effect_label: Label = %EffectLabel
@onready var next_label: Label = %NextLabel
@onready var cost_label: Label = %CostLabel
@onready var upgrade_button: Button = %UpgradeButton

var _pips: Array[ColorRect] = []


func _ready() -> void:
	for i in GuildUpgrades.MAX_LEVEL:
		var pip := ColorRect.new()
		pip.custom_minimum_size = PIP_SIZE
		pip_row.add_child(pip)
		_pips.append(pip)

	upgrade_button.pressed.connect(_on_upgrade_pressed)
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return

	var level := GuildUpgrades.get_level(building)
	var color := GuildUpgrades.get_building_color(building)
	var building_name := GuildUpgrades.get_building_name(building)

	icon.color = color
	icon_letter.text = building_name.substr(0, 1)
	name_label.text = "%s   Lv %d / %d" % [building_name, level, GuildUpgrades.MAX_LEVEL]

	for i in _pips.size():
		_pips[i].color = color if i < level else PIP_EMPTY

	effect_label.text = "Now: " + GuildUpgrades.get_effect_text(building, level)

	if GuildUpgrades.is_max_level(building):
		next_label.text = "Fully upgraded"
		cost_label.text = ""
	else:
		next_label.text = "Next: " + GuildUpgrades.get_effect_text(building, level + 1)
		cost_label.text = "%dg  ·  Standing %d" % [
			GuildUpgrades.get_next_gold_cost(building),
			GuildUpgrades.get_next_standing_req(building),
		]

	_refresh_button()

	# Buildings that don't do anything yet are shown, but faded.
	modulate = Color(1, 1, 1, 1) if GuildUpgrades.is_implemented(building) else Color(1, 1, 1, 0.55)


func _refresh_button() -> void:
	var status := GuildUpgrades.get_upgrade_status(building)
	var bg := BUTTON_READY
	match status:
		GuildUpgrades.UpgradeStatus.READY:
			upgrade_button.text = "UPGRADE"
		GuildUpgrades.UpgradeStatus.NOT_ENOUGH_GOLD:
			var short := GuildUpgrades.get_next_gold_cost(building) - GuildUpgrades.gold
			upgrade_button.text = "%dg SHORT" % short
			bg = BUTTON_BLOCKED
		GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW:
			upgrade_button.text = "NEEDS\nSTANDING %d" % GuildUpgrades.get_next_standing_req(building)
			bg = BUTTON_LOCKED
		GuildUpgrades.UpgradeStatus.MAX_LEVEL:
			upgrade_button.text = "MAX LEVEL"
			bg = BUTTON_MAX
		GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED:
			upgrade_button.text = "COMING SOON"
			bg = BUTTON_BLOCKED

	upgrade_button.disabled = status != GuildUpgrades.UpgradeStatus.READY

	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(0)
	for state in ["normal", "hover", "pressed", "disabled"]:
		upgrade_button.add_theme_stylebox_override(state, style)
	upgrade_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var text_color := Color.BLACK if status == GuildUpgrades.UpgradeStatus.MAX_LEVEL else Color.WHITE
	upgrade_button.add_theme_color_override("font_color", text_color)
	upgrade_button.add_theme_color_override("font_disabled_color", text_color)


func _on_upgrade_pressed() -> void:
	GuildUpgrades.try_upgrade(building)
