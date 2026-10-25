## One party going out tonight on the End Day check: quest, who, odds.
## Scene: MobileHall/Scenes/Rows/plan_row.tscn
extends HBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

# ---- TEXT
const TEXT_ODDS := "%d%%"

# ---- NODES
@onready var _tag_box: PanelContainer = %TagBox
@onready var _tag: Label = %Tag
@onready var _title: Label = %Title
@onready var _party_names: Label = %PartyNames
@onready var _odds: Label = %Odds


## entry = one of hall.quest_entries (a sent quest).
func setup(hall: HallMain, entry: Dictionary) -> void:
	var type_info := Style.quest_type_info(entry)
	Style.style_tag(_tag_box, _tag, type_info.tag, type_info.color)
	_title.text = entry.quest.questTitle
	_party_names.text = Style.join_names(entry.party)

	var chance: int = hall.success_chance(entry, entry.party)
	_odds.text = TEXT_ODDS % mini(chance, 100)
	Style.set_font_color(_odds, Style.odds_look(chance).text_color)
