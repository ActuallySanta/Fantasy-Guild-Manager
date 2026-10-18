## One quest on the Board: type, title, reward, party size and favored stat on
## the left; its state (party picked, sent, denied) and odds on the right.
## Tap it to open Assign Party on that quest.
## Scene: MobileHall/Scenes/Rows/quest_row.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const Portrait := preload("res://MobileHall/Scenes/Components/portrait.tscn")

const MINI_PORTRAIT := 44

# ---- TEXT
const TEXT_RANK := "Rank %s"
const TEXT_GOLD := "%d"
const TEXT_SLOTS := "%d max"
const TEXT_OPEN := "Pick a party"
const TEXT_DRAFT := "Party picked"
const TEXT_SENT := "Sent"
const TEXT_DENIED := "Denied"
const TEXT_DENIED_HINT := "Tap to reconsider"
const TEXT_ODDS := "%d%%"

# ---- NODES
@onready var _type_tile: PanelContainer = %TypeTile
@onready var _type_tag: Label = %TypeTag
@onready var _title: Label = %Title
@onready var _rank_chip = %RankChip
@onready var _gold_chip = %GoldChip
@onready var _slots_chip = %SlotsChip
@onready var _fav_chip = %FavChip
@onready var _state_label: Label = %StateLabel
@onready var _odds_label: Label = %OddsLabel
@onready var _sub_label: Label = %SubLabel
@onready var _party: HBoxContainer = %Party


func setup(main, index: int) -> void:
	var e: Dictionary = main.entries[index]
	pressed.connect(main.open_assign.bind(index))
	_show_quest(main, e)
	_show_state(main, e)


func _show_quest(main, e: Dictionary) -> void:
	var info := S.type_info(e)
	S.style_tag(_type_tile, _type_tag, info.tag, info.color)
	_title.text = e.quest.questTitle
	_rank_chip.set_chip(TEXT_RANK % S.rank_letter(e.quest), S.PAPER, S.INK)
	_gold_chip.set_chip(TEXT_GOLD % e.quest.goldReward, S.GOLD_BG, S.GOLD_TEXT, "coins")
	_slots_chip.set_chip(TEXT_SLOTS % main.slot_count(e), S.BLUE_BG, S.BLUE_TEXT, "nav_characters")
	var fav: Dictionary = S.STATS[S.favored_index(e.quest)]
	_fav_chip.set_chip(fav.short, fav.bg, fav.color, "", true)


func _show_state(main, e: Dictionary) -> void:
	S.clear(_party)
	for c in e.party:
		var p := Portrait.instantiate()
		p.custom_minimum_size = Vector2.ONE * MINI_PORTRAIT
		_party.add_child(p)
		p.show_character(c)
	var chance: int = main.chance_for(e, e.party)
	_odds_label.visible = chance >= 0
	_odds_label.text = TEXT_ODDS % mini(chance, 100)
	S.color(_odds_label, S.odds(chance)[1])
	match e.state:
		"ready":
			_state_label.text = TEXT_SENT
			S.color(_state_label, S.GREEN_TEXT)
			S.style_panel(self, Color("#E8F5E9"), S.GREEN, 4)
		"denied":
			_state_label.text = TEXT_DENIED
			S.color(_state_label, S.WAX)
			_sub_label.visible = true
			_sub_label.text = TEXT_DENIED_HINT
			S.style_panel(self, Color("#EEEEEE"), S.LINE, 2)
			modulate = Color(1, 1, 1, 0.75)
		_:
			_state_label.text = TEXT_DRAFT if not e.party.is_empty() else TEXT_OPEN
			S.color(_state_label, S.BLUE_TEXT)
			S.style_panel(self, S.CREAM, S.LINE, 2)
