## Mission Charter: pick the party for one quest and watch the odds live.
## Every adventurer's four quest stats are on screen while you choose, with the
## quest's favored stat outlined, plus how much each one adds to the odds.
## Scene: MobileLedger/Scenes/Screens/screen_charter.tscn
extends TextureRect

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")
const SlotFilled := preload("res://MobileLedger/Scenes/Rows/charter_slot_filled.tscn")
const SlotEmpty := preload("res://MobileLedger/Scenes/Rows/charter_slot_empty.tscn")
const PickRow := preload("res://MobileLedger/Scenes/Rows/charter_pick_row.tscn")

# ---- TEXT
const TEXT_SUB := "[center][color=#6B5537]%s ·[/color] [b]%d Gold[/b] [color=#6B5537]· Rank %s[/color][/center]"
const TEXT_MILESTONE := "Milestone"
const TEXT_SELECT_ONE := "Select 1 Adventurer"
const TEXT_SELECT_UP_TO := "Select up to %d"
const TEXT_CHANCE_NONE := "-- %"
const TEXT_ESTIMATE_EMPTY := "Pick adventurers to see the odds"
const TEXT_ESTIMATE := "Party stat total %d · %d needed for 100%%"
const TEXT_FAV_NOTE := "Each adventurer adds all four stats, plus %s again.%s"
const TEXT_FAV_NOTE_SOLO := " Solo quests need half as much."
const TEXT_PICK := "Pick an adventurer"
const TEXT_DISPATCH := "Dispatch Party"
const TEXT_UPDATE := "Update Party"

# ---- NODES
@onready var _top_bar = %TopBar
@onready var _page_scroll: ScrollContainer = %PageScroll
@onready var _quest_title: Label = %QuestTitle
@onready var _quest_sub: RichTextLabel = %QuestSub
@onready var _quest_picture: TextureRect = %QuestPicture
@onready var _fav_chip = %FavChip
@onready var _slots_title: Label = %SlotsTitle
@onready var _slots: Container = %Slots
@onready var _chance_percent: Label = %ChancePercent
@onready var _chance_word: Label = %ChanceWord
@onready var _chance_gauge = %ChanceGauge
@onready var _estimate_note: Label = %EstimateNote
@onready var _fav_note: Label = %FavNote
@onready var _pick_list: Container = %PickList
@onready var _no_roster: Control = %NoRoster
@onready var _go_hire_button: Button = %GoHireButton
@onready var _dispatch_button: Button = %DispatchButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_top_bar.back_pressed.connect(func(): ui.close_page())
	_go_hire_button.pressed.connect(func(): ui.open_tab("characters", "hire"))
	_dispatch_button.pressed.connect(func(): ui.dispatch_charter())


func scroll_to_top() -> void:
	_page_scroll.scroll_vertical = 0


func refresh() -> void:
	var e: Dictionary = ui.page.entry
	var draft: Array = ui.page.draft
	_show_quest(e)
	_show_slots(e, draft)
	_show_estimate(e, draft)
	_show_roster(e, draft)
	_show_dispatch(e, draft)


## The charter itself: title, type / gold / rank, picture, favored stat.
func _show_quest(e: Dictionary) -> void:
	var q: CreatedQuest = e.quest
	var key := S.type_key(e)
	_quest_title.text = q.questTitle
	S.color(_quest_title, S.TYPE_COLORS[key])
	var type_name: String = TEXT_MILESTONE if e.milestone else S.TYPE_NAMES.get(int(q.type), "Quest")
	_quest_sub.text = TEXT_SUB % [type_name, q.goldReward, S.rank_letter(q)]
	_quest_picture.texture = S.tex(S.TYPE_SCENES[key])
	var st: Dictionary = S.STATS[S.favored_index(q)]
	_fav_chip.set_icon_chip(st.icon, st.name, st.bg, st.color)


## Big round slots: chosen adventurers (tap to remove), then empty ones.
func _show_slots(e: Dictionary, draft: Array) -> void:
	var n: int = ui.slot_count(e)
	_slots_title.text = TEXT_SELECT_ONE if n == 1 else TEXT_SELECT_UP_TO % n
	S.clear(_slots)
	for i in n:
		if i < draft.size():
			S.add_row(_slots, SlotFilled).setup(ui, draft[i])
		else:
			S.add_row(_slots, SlotEmpty)


## Percent, word, rune gauge, and the party's stat total vs. what 100% needs.
func _show_estimate(e: Dictionary, draft: Array) -> void:
	var chance: int = ui.chance_for(e, draft)
	var o: Array = S.odds(chance)
	_chance_percent.text = TEXT_CHANCE_NONE if chance < 0 else "%d%%" % mini(chance, 100)
	S.color(_chance_percent, o[1])
	_chance_word.text = o[0]
	_chance_gauge.set_value(0.0 if chance < 0 else minf(chance, 100) / 100.0, o[2])
	var total := 0
	for c in draft:
		total += S.fit_score(e.quest, c)
	_estimate_note.text = TEXT_ESTIMATE_EMPTY if draft.is_empty() else TEXT_ESTIMATE % [total, S.fit_needed(e.quest)]


## Everyone in the guild, best fit first.
func _show_roster(e: Dictionary, draft: Array) -> void:
	var q: CreatedQuest = e.quest
	var n: int = ui.slot_count(e)
	var fav_name: String = S.STATS[S.favored_index(q)].name
	_fav_note.text = TEXT_FAV_NOTE % [fav_name, TEXT_FAV_NOTE_SOLO if n == 1 else ""]
	var roster: Array = CharacterContainer.active_characters.duplicate()
	roster.sort_custom(func(a, b): return S.fit_score(q, a) > S.fit_score(q, b))
	S.clear(_pick_list)
	for c in roster:
		S.add_row(_pick_list, PickRow).setup(ui, e, c, draft, n)
	_no_roster.visible = roster.is_empty()


func _show_dispatch(e: Dictionary, draft: Array) -> void:
	if draft.is_empty():
		_dispatch_button.text = TEXT_PICK
	else:
		_dispatch_button.text = TEXT_UPDATE if e.state == "ready" else TEXT_DISPATCH
	_dispatch_button.disabled = draft.is_empty()
