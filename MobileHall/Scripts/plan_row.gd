## One party going out tonight on the End Day check: quest, who, odds.
## Scene: MobileHall/Scenes/Rows/plan_row.tscn
extends HBoxContainer


# ---- TEXT
const TEXT_ODDS := "%d%%"

# ---- NODES
@onready var _tag_box: PanelContainer = %TagBox
@onready var _tag: Label = %Tag
@onready var _tag_icon: TextureRect = %TagIcon
@onready var _title: Label = %Title
@onready var _party_names: Label = %PartyNames
@onready var _odds: Label = %Odds


## entry = one of hall.quest_entries (a sent quest).
func setup(hall: HallMain, entry: Dictionary) -> void:
	var type_info := HallStyle.quest_type_info(entry)
	HallStyle.style_icon_tag(_tag_box, _tag, _tag_icon, type_info.tag, type_info.get("icon", ""), type_info.color)
	_title.text = entry.quest.questTitle
	_party_names.text = HallStyle.join_names(entry.party)

	var chance: int = hall.success_chance(entry, entry.party)
	_odds.text = TEXT_ODDS % mini(chance, 100)
	HallStyle.set_font_color(_odds, HallStyle.odds_look(chance).text_color)
