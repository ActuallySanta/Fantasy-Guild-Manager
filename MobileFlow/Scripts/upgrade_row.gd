## One building: level, now / next effect, cost, and the Upgrade button.
## Scene: MobileFlow/Scenes/Rows/upgrade_row.tscn
extends PanelContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")

# ---- TEXT
const TEXT_LEVEL := "Lv %d/%d"
const TEXT_NOW := "[b]Now:[/b] %s"
const TEXT_NEXT := "[b]Next:[/b] %s"
const TEXT_COST := "%d gold"
const TEXT_STANDING := "Standing %d"

# ---- NODES
@onready var _building_name: Label = %BuildingName
@onready var _level: Label = %Level
@onready var _soon_chip: Control = %SoonChip
@onready var _now: RichTextLabel = %Now
@onready var _next: RichTextLabel = %Next
@onready var _cost_chip = %CostChip
@onready var _standing_chip = %StandingChip
@onready var _upgrade_button: Button = %UpgradeButton


func setup(ui: Main, b: int) -> void:
	var lvl := GuildUpgrades.get_level(b)
	var status := GuildUpgrades.get_upgrade_status(b)
	var maxed := GuildUpgrades.is_max_level(b)
	var soon := status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED

	modulate = Color(1, 1, 1, 0.55) if soon else Color.WHITE
	_building_name.text = GuildUpgrades.get_building_name(b)
	_level.text = TEXT_LEVEL % [lvl, GuildUpgrades.MAX_LEVEL]
	_soon_chip.visible = soon
	_now.text = TEXT_NOW % GuildUpgrades.get_effect_text(b, lvl)

	# next level + its price (hidden at max level); red when you can't afford it
	for n in [_next, _cost_chip, _standing_chip]:
		n.visible = not maxed
	if not maxed:
		var cost := GuildUpgrades.get_next_gold_cost(b)
		var req := GuildUpgrades.get_next_standing_req(b)
		var gold_ok := GameState.gold >= cost
		var standing_ok := GameState.standing >= req
		_next.text = TEXT_NEXT % GuildUpgrades.get_effect_text(b, lvl + 1)
		_cost_chip.set_icon_chip("coins", TEXT_COST % cost, S.GOLD_BG if gold_ok else S.BAD_BG, S.GOLD if gold_ok else S.BAD)
		_standing_chip.set_icon_chip("rook", TEXT_STANDING % req, S.BOX_ALT if standing_ok else S.BAD_BG, S.INK if standing_ok else S.BAD)

	var can_buy := status == GuildUpgrades.UpgradeStatus.READY
	_upgrade_button.text = S.upgrade_button_text(status)
	S.style_button(_upgrade_button, "green" if can_buy else "")
	_upgrade_button.disabled = not can_buy
	_upgrade_button.pressed.connect(ui.upgrade.bind(b))
