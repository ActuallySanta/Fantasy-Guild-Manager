## One quest result in the Home tab's "Last Night" card.
## Scene: MobileLedger/Scenes/Rows/last_row.tscn
extends HBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

const TEXT_GOLD := "+%dg"
const TEXT_NO_GOLD := "0g"

@onready var _icon: TextureRect = %Icon
@onready var _quest_name: Label = %QuestName
@onready var _gold: Label = %Gold


func setup(result: Dictionary) -> void:
	_icon.texture = S.icon_tex("check" if result.succeeded else "x")
	_icon.modulate = S.GREEN_TEXT if result.succeeded else S.WAX
	_quest_name.text = result.quest.questTitle
	_gold.text = TEXT_GOLD % result.gold if result.gold > 0 else TEXT_NO_GOLD
