## One party going out tonight on the End Day check: quest, who, odds.
## Scene: MobileHall/Scenes/Rows/plan_row.tscn
extends HBoxContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_ODDS := "%d%%"

@onready var _tag_box: PanelContainer = %TagBox
@onready var _tag: Label = %Tag
@onready var _title: Label = %Title
@onready var _party: Label = %PartyNames
@onready var _odds: Label = %Odds


func setup(main, e: Dictionary) -> void:
	var info := S.type_info(e)
	S.style_tag(_tag_box, _tag, info.tag, info.color)
	_title.text = e.quest.questTitle
	_party.text = S.names(e.party)
	var chance: int = main.chance_for(e, e.party)
	_odds.text = TEXT_ODDS % mini(chance, 100)
	S.color(_odds, S.odds(chance)[1])
