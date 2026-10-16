## One building on the Upgrades tab: icon tile, level pips, now / next effect,
## cost, and the Upgrade button.
## Scene: MobileLedger/Scenes/Rows/upgrade_card.tscn
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

## GuildUpgrades.Building -> icon in Art/Icons.
const ICONS := {0: "office", 1: "training", 2: "hospital", 3: "armory", 4: "barracks"}
const PIP_EMPTY := Color("#E2CC9C")

# ---- TEXT
const TEXT_LEVEL := "Lv %d / %d"
const TEXT_NOW := "[b]Now:[/b] %s"
const TEXT_NEXT := "[color=#2F6A22][b]Next:[/b] %s[/color]"
const TEXT_FULLY_UPGRADED := "Fully upgraded"
const TEXT_UPGRADE := "Upgrade"
const TEXT_GOLD_SHORT := "%d gold short"
const TEXT_NEEDS_STANDING := "Needs Standing %d"
const TEXT_MAX_LEVEL := "Max level"
const TEXT_COMING_SOON := "Coming soon"

# ---- NODES
@onready var _tile: PanelContainer = %Tile
@onready var _icon: TextureRect = %Icon
@onready var _building_name: Label = %BuildingName
@onready var _level: Label = %Level
@onready var _pips: Container = %Pips
@onready var _soon_chip: Control = %SoonChip
@onready var _now: RichTextLabel = %Now
@onready var _next: RichTextLabel = %Next
@onready var _coin_icon: Control = %CoinIcon
@onready var _cost: Label = %Cost
@onready var _rook_icon: Control = %RookIcon
@onready var _requirement: Label = %Requirement
@onready var _upgrade_button: Button = %UpgradeButton


func setup(ui: Main, b: int) -> void:
	var lvl := GuildUpgrades.get_level(b)
	var status := GuildUpgrades.get_upgrade_status(b)
	var maxed := GuildUpgrades.is_max_level(b)
	modulate = Color(1, 1, 1, 0.62) if status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED else Color.WHITE
	_show_header(b, lvl, status)
	_now.text = TEXT_NOW % GuildUpgrades.get_effect_text(b, lvl)
	_next.text = TEXT_NEXT % (TEXT_FULLY_UPGRADED if maxed else GuildUpgrades.get_effect_text(b, lvl + 1))
	_show_cost(b, maxed)
	_show_button(ui, b, status)


## Building-coloured tile, name, "Lv 2 / 5" and one pip per level.
func _show_header(b: int, lvl: int, status: int) -> void:
	var color := GuildUpgrades.get_building_color(b)
	_tile.add_theme_stylebox_override("panel", S.flat(color, 20, 3, S.INK, Vector4(10, 10, 10, 10)))
	_icon.texture = S.icon_tex(ICONS.get(b, "rook"))
	_building_name.text = GuildUpgrades.get_building_name(b)
	_level.text = TEXT_LEVEL % [lvl, GuildUpgrades.MAX_LEVEL]
	for i in _pips.get_child_count():
		var filled := i < lvl
		_pips.get_child(i).add_theme_stylebox_override("panel", S.flat(color if filled else PIP_EMPTY, 6, 2, S.INK))
	_soon_chip.visible = status == GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED


## Gold and Standing needed (red when you don't have enough). Hidden at max level.
func _show_cost(b: int, maxed: bool) -> void:
	for n in [_coin_icon, _cost, _rook_icon, _requirement]:
		n.visible = not maxed
	if maxed:
		return
	var cost := GuildUpgrades.get_next_gold_cost(b)
	var req := GuildUpgrades.get_next_standing_req(b)
	_cost.text = str(cost)
	S.color(_cost, S.INK if GameState.gold >= cost else S.WAX)
	_requirement.text = str(req)
	S.color(_requirement, S.INK if GameState.standing >= req else S.WAX)


func _show_button(ui: Main, b: int, status: int) -> void:
	var label := TEXT_UPGRADE
	var kind := "green"
	match status:
		GuildUpgrades.UpgradeStatus.NOT_ENOUGH_GOLD:
			label = TEXT_GOLD_SHORT % (GuildUpgrades.get_next_gold_cost(b) - GameState.gold)
		GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW:
			label = TEXT_NEEDS_STANDING % GuildUpgrades.get_next_standing_req(b)
		GuildUpgrades.UpgradeStatus.MAX_LEVEL:
			label = TEXT_MAX_LEVEL
			kind = "wood"
		GuildUpgrades.UpgradeStatus.NOT_IMPLEMENTED:
			label = TEXT_COMING_SOON
	_upgrade_button.text = label
	S.style_button(_upgrade_button, kind, 27)
	_upgrade_button.disabled = status != GuildUpgrades.UpgradeStatus.READY
	_upgrade_button.pressed.connect(ui.upgrade.bind(b))
