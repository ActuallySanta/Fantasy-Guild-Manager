## One quest on the Board, drawn as a scroll: type seal, title, rank, reward,
## party size and favored stat on the left; its state (party picked, sent,
## denied) and odds on the right. Tap it to open Assign Party on that quest.
## Scene: MobileHall/Scenes/Rows/quest_row.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const PortraitScene := preload("res://MobileHall/Scenes/Components/portrait.tscn")

## Size (pixels) of the little party portraits under the state.
const MINI_PORTRAIT_SIZE := 40
## Denied quests fade back so the open ones stand out.
const DENIED_OPACITY := 0.7

# ---- TEXT
# Quest facts (left)
const TEXT_RANK := "RANK %s"
const TEXT_GOLD := "%d"
const TEXT_PARTY_SIZE := "%d max"
# State (right)
const TEXT_OPEN := "Pick a party"
const TEXT_DRAFT := "Party picked"
const TEXT_SENT := "Sent"
const TEXT_DENIED := "Denied"
const TEXT_DENIED_HINT := "tap to reconsider"
const TEXT_ODDS := "%d%%"

# ---- NODES
# Quest facts (left)
@onready var _type_seal: PanelContainer = %TypeSeal
@onready var _type_tag: Label = %TypeTag
@onready var _title: Label = %Title
@onready var _rank_chip = %RankChip           # chip.gd
@onready var _gold_chip = %GoldChip           # chip.gd
@onready var _party_size_chip = %SlotsChip    # chip.gd
@onready var _favored_chip = %FavChip         # chip.gd
# State (right)
@onready var _state_label: Label = %StateLabel
@onready var _odds_label: Label = %OddsLabel
@onready var _sub_label: Label = %SubLabel
@onready var _party_portraits: HBoxContainer = %Party


func setup(hall: HallMain, quest_index: int) -> void:
	var entry: Dictionary = hall.quest_entries[quest_index]
	pressed.connect(hall.open_assign.bind(quest_index))
	_show_quest_facts(hall, entry)
	_show_party(hall, entry)
	_show_state(entry)


## Type seal, title, rank, reward, party size, favored stat.
func _show_quest_facts(hall: HallMain, entry: Dictionary) -> void:
	var type_info := Style.quest_type_info(entry)
	Style.style_tag(_type_seal, _type_tag, type_info.tag, type_info.color)
	_title.text = entry.quest.questTitle
	_rank_chip.set_box(TEXT_RANK % Style.rank_letter(entry.quest), Style.TEXT_MAIN)
	# item quests pay pre-rolled equipment instead of gold: show the count and rarities
	if entry.quest.pays_in_items():
		_gold_chip.set_chip(entry.quest.get_reward_text(), Style.BLUE_BG, Style.BLUE_TEXT, "chest")
	else:
		_gold_chip.set_chip(TEXT_GOLD % entry.quest.goldReward, Style.GOLD_BG, Style.TEXT_MAIN, "coins")
	_party_size_chip.set_chip(TEXT_PARTY_SIZE % hall.party_size_limit(entry), Style.BLUE_BG, Style.TEXT_MAIN, "person")
	var favored_stat: Dictionary = Style.STATS[Style.favored_stat_index(entry.quest)]
	_favored_chip.set_chip(favored_stat.short, favored_stat.bg, favored_stat.color, "", true)


## Mini portraits of the picked party and their success chance.
func _show_party(hall: HallMain, entry: Dictionary) -> void:
	Style.clear_children(_party_portraits)
	for character in entry.party:
		var portrait := PortraitScene.instantiate()
		portrait.circle = true
		portrait.custom_minimum_size = Vector2.ONE * MINI_PORTRAIT_SIZE
		_party_portraits.add_child(portrait)
		portrait.show_character(character)

	var chance: int = hall.success_chance(entry, entry.party)
	_odds_label.visible = chance >= 0
	_odds_label.text = TEXT_ODDS % mini(chance, 100)
	Style.set_font_color(_odds_label, Style.odds_look(chance).text_color)


## State word in its ink: green = sent, red = denied (and the row fades), blue = open.
func _show_state(entry: Dictionary) -> void:
	match entry.state:
		Style.QUEST_STATE_SENT:
			_state_label.text = TEXT_SENT
			Style.set_font_color(_state_label, Style.GREEN_TEXT)
		Style.QUEST_STATE_DENIED:
			_state_label.text = TEXT_DENIED
			Style.set_font_color(_state_label, Style.RED)
			_sub_label.visible = true
			_sub_label.text = TEXT_DENIED_HINT
			modulate = Color(1, 1, 1, DENIED_OPACITY)
		_:
			_state_label.text = TEXT_DRAFT if not entry.party.is_empty() else TEXT_OPEN
			Style.set_font_color(_state_label, Style.BLUE_TEXT)
