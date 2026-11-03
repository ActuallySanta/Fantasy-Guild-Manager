## One quest on the Board, drawn as a scroll: type seal, title, rank, reward,
## party size and favored stat on the left; its state (party picked, sent,
## denied) and odds on the right. Tap it to open Assign Party on that quest.
## Scene: MobileHall/Scenes/Rows/quest_row.tscn
extends TapPanel

const PortraitScene := preload("uid://h87tubvsjwc3")  # MobileHall/Scenes/Components/portrait.tscn

## Size (pixels) of the little party portraits under the state.
const MINI_PORTRAIT_SIZE := 40
## Denied quests fade back so the open ones stand out.
const DENIED_OPACITY := 0.7
## The SENT stamp inked on a sent quest's row: where its centre sits (fraction
## of the row's size), text size, tilt (radians).
const SENT_STAMP_AT := Vector2(0.56, 0.5)
const SENT_STAMP_FONT_SIZE := 34
const SENT_STAMP_TILT := -0.14

# ---- TEXT
# Quest facts (left)
const TEXT_RANK := "RANK %s"
const TEXT_GOLD := "%d"
const TEXT_PARTY_SIZE := "%d max"
# State (right)
const TEXT_OPEN := "Pick a party"
const TEXT_DRAFT := "Party picked"
const TEXT_SENT := "Sent"
const TEXT_SENT_STAMP := "SENT"
const TEXT_DENIED := "Denied"
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
@onready var _party_portraits: HBoxContainer = %Party


func setup(hall: HallMain, quest_index: int) -> void:
	var entry: Dictionary = hall.quest_entries[quest_index]
	pressed.connect(hall.open_assign.bind(quest_index))
	_show_quest_facts(hall, entry)
	_show_party(hall, entry)
	_show_state(entry)
	# sent quests have SENT inked on them (pressed on if it was just sent);
	# a just-denied quest's state word stamps in
	var is_just_decided: bool = hall.pending_fx.get("quest_stamp", -1) == quest_index
	if entry.state == HallStyle.QUEST_STATE_SENT:
		HallFx.stamp_onto(self, TEXT_SENT_STAMP, HallStyle.GREEN_TEXT, SENT_STAMP_AT,
				SENT_STAMP_FONT_SIZE, SENT_STAMP_TILT, is_just_decided)
	elif is_just_decided:
		HallFx.stamp_in(_state_label, 2.0)
		HallFx.pop(self, 1.03, 0.12)


## Type seal, title, rank, reward, party size, favored stat.
func _show_quest_facts(hall: HallMain, entry: Dictionary) -> void:
	var type_info := HallStyle.quest_type_info(entry)
	HallStyle.style_tag(_type_seal, _type_tag, type_info.tag, type_info.color)
	_title.text = entry.quest.questTitle
	_rank_chip.set_box(TEXT_RANK % HallStyle.rank_letter(entry.quest), HallStyle.TEXT_MAIN)
	# item quests pay pre-rolled equipment instead of gold: show the count and rarities
	if entry.quest.pays_in_items():
		_gold_chip.set_chip(HallStyle.item_reward_text(entry.quest, true), HallStyle.BLUE_BG, HallStyle.BLUE_TEXT, "chest")
	else:
		_gold_chip.set_chip(TEXT_GOLD % entry.quest.goldReward, HallStyle.GOLD_BG, HallStyle.TEXT_MAIN, "coins")
	_party_size_chip.set_chip(TEXT_PARTY_SIZE % hall.party_size_limit(entry), HallStyle.BLUE_BG, HallStyle.TEXT_MAIN, "person")
	var favored_stat: Dictionary = HallStyle.STATS[HallStyle.favored_stat_index(entry.quest)]
	_favored_chip.set_chip(favored_stat.short, favored_stat.bg, favored_stat.color, "", true)


## Mini portraits of the picked party and their success chance.
func _show_party(hall: HallMain, entry: Dictionary) -> void:
	HallStyle.clear_children(_party_portraits)
	for character in entry.party:
		var portrait := PortraitScene.instantiate()
		portrait.circle = true
		portrait.custom_minimum_size = Vector2.ONE * MINI_PORTRAIT_SIZE
		_party_portraits.add_child(portrait)
		portrait.show_character(character)

	var chance: int = hall.success_chance(entry, entry.party)
	_odds_label.visible = chance >= 0
	_odds_label.text = TEXT_ODDS % mini(chance, 100)
	HallStyle.set_font_color(_odds_label, HallStyle.odds_look(chance).text_color)


## State word in its ink: green = sent, red = denied (and the row fades), blue = open.
func _show_state(entry: Dictionary) -> void:
	match entry.state:
		HallStyle.QUEST_STATE_SENT:
			_state_label.text = TEXT_SENT
			HallStyle.set_font_color(_state_label, HallStyle.GREEN_TEXT)
		HallStyle.QUEST_STATE_DENIED:
			_state_label.text = TEXT_DENIED
			HallStyle.set_font_color(_state_label, HallStyle.RED)
			modulate = Color(1, 1, 1, DENIED_OPACITY)
		_:
			_state_label.text = TEXT_DRAFT if not entry.party.is_empty() else TEXT_OPEN
			HallStyle.set_font_color(_state_label, HallStyle.BLUE_TEXT)
