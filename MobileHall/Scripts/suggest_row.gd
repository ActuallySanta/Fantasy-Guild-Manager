## An upgrade you can afford, offered on the End Day check with a buy button.
## Scene: MobileHall/Scenes/Rows/suggest_row.tscn
extends HBoxContainer


# ---- TEXT
const TEXT_NAME := "%s · Level %d"
const TEXT_BUTTON := "%d gold"

# ---- NODES
@onready var _tag_box: PanelContainer = %TagBox
@onready var _tag: Label = %Tag
@onready var _name: Label = %Name
@onready var _effect: Label = %Effect
@onready var _buy_button: Button = %BuyButton


## building = a GuildUpgrades.Building value.
func setup(hall: HallMain, building: int) -> void:
	var next_level := GuildUpgrades.get_level(building) + 1
	var tag_color: Color = GuildUpgrades.get_building_color(building).darkened(0.25)
	HallStyle.style_tag(_tag_box, _tag, HallStyle.BUILDING_TAGS.get(building, "?"), tag_color)
	_name.text = TEXT_NAME % [GuildUpgrades.get_building_name(building), next_level]
	_effect.text = GuildUpgrades.get_effect_text(building, next_level)

	_buy_button.text = TEXT_BUTTON % GuildUpgrades.get_next_gold_cost(building)
	HallStyle.style_button(_buy_button, "green", 24)
	_buy_button.pressed.connect(hall.upgrade_building.bind(building))
