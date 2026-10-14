## Quest card face: type, rank, gold, favored stat, party slots and live odds.
## Fill the slots from the roster tray, then swipe right to send / left to deny.
## Scene: MobileDeck/Scenes/Cards/card_quest.tscn
extends VBoxContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const Main := preload("res://MobileDeck/Scripts/deck_main.gd")
const SlotFilled := preload("res://MobileDeck/Scenes/Rows/slot_filled.tscn")
const SlotEmpty := preload("res://MobileDeck/Scenes/Rows/slot_empty.tscn")

## Slot size: big for 1-2 adventurers, smaller for bigger parties.
const SLOT_SIZE_SMALL_PARTY := 150.0
const SLOT_SIZE_BIG_PARTY := 120.0

# ---- TEXT
const TEXT_MILESTONE := "MILESTONE"
const TEXT_RANK := "Rank %s"
const TEXT_GOLD := "%d gold"
const TEXT_FAV_NOTE := "(counts twice)"
const TEXT_FAV_NOTE_PLUCK := "(doesn't change odds)"
const TEXT_SOLO := "Solo quest"
const TEXT_PARTY_OF := "Party of up to %d"
const TEXT_CHANCE_UNKNOWN := "chance of success"
const TEXT_HINT_NO_ADVENTURERS := "No adventurers yet. Press Back to see the recruits, or swipe left to deny."
const TEXT_HINT_PICK := "Tap adventurers in the tray below to add them.\nThen swipe right to send, or left to deny."
const TEXT_HINT_SEND := "Swipe right to send this party, left to deny the quest."

# ---- NODES
@onready var _type_chip = %TypeChip
@onready var _rank_chip = %RankChip
@onready var _gold_chip = %GoldChip
@onready var _quest_title: Label = %QuestTitle
@onready var _fav_chip = %FavChip
@onready var _fav_note: Label = %FavNote
@onready var _milestone_note: Control = %MilestoneNote
@onready var _party_label: Label = %PartyLabel
@onready var _slots: Container = %Slots
@onready var _chance_percent: Label = %ChancePercent
@onready var _chance_word: Label = %ChanceWord
@onready var _chance_gauge = %ChanceGauge
@onready var _hint: Label = %Hint

var ui: Main


func setup(main: Main) -> void:
	ui = main


func refresh() -> void:
	var e: Dictionary = ui.current().entry
	_show_quest(e)
	_show_slots(e)
	_show_odds(e)
	_show_hint()


func _show_quest(e: Dictionary) -> void:
	var q: CreatedQuest = e.quest
	var milestone: bool = e.milestone
	var type_name: String = TEXT_MILESTONE if milestone else S.TYPE_NAMES.get(int(q.type), "Quest").to_upper()
	_type_chip.set_chip(type_name, S.BAD_BG if milestone else S.BOX_ALT, S.BAD if milestone else S.INK_SOFT, -1, false)
	_rank_chip.set_chip(TEXT_RANK % S.rank_letter(q), S.BOX_ALT, S.INK, -1, false)
	_gold_chip.set_icon_chip("coins", TEXT_GOLD % q.goldReward, S.GOLD_BG, S.GOLD)
	_quest_title.text = q.questTitle
	S.color(_quest_title, S.BAD if milestone else S.INK)
	var fav := S.favored_index(q)
	var st: Dictionary = S.STATS[fav]
	_fav_chip.set_icon_chip("", st.name, st.bg, st.color, -1, true)
	_fav_note.text = TEXT_FAV_NOTE if fav < 4 else TEXT_FAV_NOTE_PLUCK
	_milestone_note.visible = milestone


## One slot per adventurer the quest takes. Tap a filled slot to remove them.
func _show_slots(e: Dictionary) -> void:
	var n: int = ui.slot_count(e)
	var slot_size := SLOT_SIZE_SMALL_PARTY if n <= 2 else SLOT_SIZE_BIG_PARTY
	_party_label.text = TEXT_SOLO if n == 1 else TEXT_PARTY_OF % n
	S.clear(_slots)
	for i in n:
		if i < ui.draft.size():
			S.add_row(_slots, SlotFilled).setup(ui, ui.draft[i], slot_size)
		else:
			S.add_row(_slots, SlotEmpty).setup(slot_size)


func _show_odds(e: Dictionary) -> void:
	var chance: int = ui.chance_for(e, ui.draft)
	var o: Array = S.odds(chance)
	_chance_percent.text = S.percent(chance)
	S.color(_chance_percent, o[1])
	_chance_word.text = TEXT_CHANCE_UNKNOWN if chance < 0 else o[0]
	S.color(_chance_word, o[1])
	_chance_gauge.set_value(0.0 if chance < 0 else minf(chance, 100) / 100.0, o[2])


func _show_hint() -> void:
	if CharacterContainer.active_characters.is_empty():
		_hint.text = TEXT_HINT_NO_ADVENTURERS
	elif ui.draft.is_empty():
		_hint.text = TEXT_HINT_PICK
	else:
		_hint.text = TEXT_HINT_SEND
