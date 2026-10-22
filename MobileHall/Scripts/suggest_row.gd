## An upgrade you can afford, offered on the End Day check.
## Scene: MobileHall/Scenes/Rows/suggest_row.tscn
extends HBoxContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_NAME := "%s · Level %d"
const TEXT_BUTTON := "%d gold"

@onready var _tag_box: PanelContainer = %TagBox
@onready var _tag: Label = %Tag
@onready var _name: Label = %Name
@onready var _effect: Label = %Effect
@onready var _button: Button = %BuyButton


func setup(main, b: int) -> void:
	var lvl := GuildUpgrades.get_level(b)
	S.seal(_tag_box, _tag, S.BUILDINGS.get(b, {}).get("tag", "?"), GuildUpgrades.get_building_color(b).darkened(0.35))
	_name.text = TEXT_NAME % [GuildUpgrades.get_building_name(b), lvl + 1]
	_effect.text = GuildUpgrades.get_effect_text(b, lvl + 1)
	_button.text = TEXT_BUTTON % GuildUpgrades.get_next_gold_cost(b)
	S.style_button(_button, "gold", 28)
	_button.pressed.connect(main.upgrade.bind(b))
