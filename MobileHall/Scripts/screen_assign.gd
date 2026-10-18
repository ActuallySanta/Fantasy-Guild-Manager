## Assign Party: one quest at a time, with every other quest one tap away.
## Scene: MobileHall/Scenes/Screens/screen_assign.tscn
##
##   strip   - back to the Board, then one tab per quest (state-coloured);
##             switching keeps every quest's picks
##   quest   - type, title, reward, party size, favored stat
##   party   - the seats (tap to remove) and the live success chance
##   picker  - every adventurer, best fit first, with stats and what they add
##   footer  - Deny / Send (or Recall / Reconsider once decided)
extends VBoxContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const QuestTab := preload("res://MobileHall/Scenes/Rows/quest_tab.tscn")
const PartySlot := preload("res://MobileHall/Scenes/Rows/party_slot.tscn")
const PickRow := preload("res://MobileHall/Scenes/Rows/pick_row.tscn")

# ---- TEXT
const TEXT_TYPE := "%s · Rank %s"
const TEXT_GOLD := "%d gold"
const TEXT_SLOTS := "Up to %d"
const TEXT_SLOTS_ONE := "Solo"
const TEXT_FAV := "Favors %s"
const TEXT_ODDS := "%d%%"
const TEXT_ODDS_NONE := "--"
const STATUS_OPEN := "Pick up to %s. Their stats add up to the chance."
const STATUS_DRAFT := "Picks are kept if you look at another quest."
const STATUS_SENT := "Sent. Tap someone to change the party, or recall it."
const STATUS_DENIED := "Denied. Reconsider to put it back on the board."
const PICK_HEADING := "Your adventurers · best fit first"
const PICK_HEADING_HIDDEN := "Free adventurers · %d busy hidden"
const BUTTON_SHOW_BUSY := "Show busy"
const NO_ROSTER := "You have no adventurers yet."
const BUTTON_DENY := "Deny"
const BUTTON_SEND := "Send Party"
const BUTTON_SEND_EMPTY := "Pick someone"
const BUTTON_RECALL := "Recall"
const BUTTON_NEXT := "Next Quest"
const BUTTON_BOARD := "Board"
const BUTTON_RECONSIDER := "Reconsider"

# ---- NODES
@onready var _back_button: Button = %BackButton
@onready var _tabs: HBoxContainer = %QuestTabs
@onready var _scroll: ScrollContainer = %Scroll
@onready var _quest_card: PanelContainer = %QuestCard
@onready var _type_label: Label = %TypeLabel
@onready var _title: Label = %Title
@onready var _gold_chip = %GoldChip
@onready var _slots_chip = %SlotsChip
@onready var _fav_chip = %FavChip
@onready var _status: Label = %Status
@onready var _party_box: Control = %PartyBox
@onready var _slots: HBoxContainer = %Slots
@onready var _odds_value: Label = %OddsValue
@onready var _odds_word: Label = %OddsWord
@onready var _odds_bar = %OddsBar
@onready var _pick_header: Control = %PickHeader
@onready var _pick_heading: Label = %PickHeading
@onready var _busy_toggle: CheckButton = %BusyToggle
@onready var _all_busy: Label = %AllBusy
@onready var _pick_list: VBoxContainer = %PickList
@onready var _no_roster: Control = %NoRoster
@onready var _hire_button: Button = %HireButton
@onready var _left_button: Button = %LeftButton
@onready var _right_button: Button = %RightButton

var ui


func setup(main) -> void:
	ui = main
	_back_button.pressed.connect(ui.close_screen)
	_hire_button.pressed.connect(func(): ui.open_tab("guild", "hire"))
	_left_button.pressed.connect(_on_left)
	_right_button.pressed.connect(_on_right)
	_busy_toggle.toggled.connect(func(on): ui.set_show_busy(on))
	_busy_toggle.text = BUTTON_SHOW_BUSY
	S.style_button(_back_button, "paper", 22)
	S.style_button(_hire_button, "blue", 26)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	var e: Dictionary = ui.current_entry()
	if e.is_empty():
		return
	_show_tabs()
	_show_quest(e)
	_show_party(e)
	_show_picker(e)
	_show_footer(e)


func _show_tabs() -> void:
	S.clear(_tabs)
	_tabs.visible = ui.entries.size() > 1
	for i in ui.entries.size():
		S.add_row(_tabs, QuestTab).setup(ui, i, i == ui.screen.index)


func _show_quest(e: Dictionary) -> void:
	var info := S.type_info(e)
	var q: CreatedQuest = e.quest
	_type_label.text = TEXT_TYPE % [info.name, S.rank_letter(q)]
	S.color(_type_label, info.color)
	_title.text = q.questTitle
	_gold_chip.set_chip(TEXT_GOLD % q.goldReward, S.GOLD_BG, S.GOLD_TEXT, "coins")
	var n: int = ui.slot_count(e)
	_slots_chip.set_chip(TEXT_SLOTS_ONE if n == 1 else TEXT_SLOTS % n, S.BLUE_BG, S.BLUE_TEXT, "nav_characters")
	var fav: Dictionary = S.STATS[S.favored_index(q)]
	_fav_chip.set_chip(TEXT_FAV % fav.name, fav.bg, fav.color, "", true)
	match e.state:
		"ready":
			_status.text = STATUS_SENT
			S.style_panel(_quest_card, Color("#E8F5E9"), S.GREEN, 4, 18, Vector4(20, 14, 20, 14))
		"denied":
			_status.text = STATUS_DENIED
			S.style_panel(_quest_card, Color("#EEEEEE"), S.WAX, 4, 18, Vector4(20, 14, 20, 14))
		_:
			_status.text = STATUS_DRAFT if not e.party.is_empty() else STATUS_OPEN % S.count(n, "adventurer", "adventurers")
			S.style_panel(_quest_card, S.CREAM, info.color, 4, 18, Vector4(20, 14, 20, 14))


func _show_party(e: Dictionary) -> void:
	_party_box.visible = e.state != "denied"
	S.clear(_slots)
	for i in ui.slot_count(e):
		var c: GuildCharacter = e.party[i] if i < e.party.size() else null
		S.add_row(_slots, PartySlot).setup(ui, c)
	var chance: int = ui.chance_for(e, e.party)
	var o := S.odds(chance)
	_odds_value.text = TEXT_ODDS % mini(chance, 100) if chance >= 0 else TEXT_ODDS_NONE
	_odds_word.text = o[0]
	S.color(_odds_value, o[1])
	S.color(_odds_word, o[1])
	_odds_bar.set_chance(mini(chance, 100))


## Everyone, best fit for this quest first; dead adventurers last.
## Adventurers in another quest's party (sent or picked) are left out unless
## "Show busy" is on; when shown they still say which quest they're on.
func _show_picker(e: Dictionary) -> void:
	S.clear(_pick_list)
	var list: Array = []
	var hidden := 0
	for c in ui.roster():
		var i: int = ui.entry_index_of(c)
		var busy: bool = i >= 0 and ui.entries[i] != e
		if busy and not ui.show_busy:
			hidden += 1
		else:
			list.append(c)
	list.sort_custom(func(a, b):
		if S.is_dead(a) != S.is_dead(b):
			return S.is_dead(b)
		return ui.chance_added(e, a) > ui.chance_added(e, b))
	for c in list:
		S.add_row(_pick_list, PickRow).setup(ui, e, c)
	var open: bool = e.state != "denied"
	_pick_heading.text = PICK_HEADING_HIDDEN % hidden if hidden > 0 else PICK_HEADING
	_busy_toggle.set_pressed_no_signal(ui.show_busy)
	S.style_button(_busy_toggle, "blue" if ui.show_busy else "paper", 21)
	_pick_header.visible = open and not ui.roster().is_empty()
	_pick_list.visible = open
	_all_busy.visible = open and list.is_empty() and hidden > 0
	_no_roster.visible = ui.roster().is_empty()


## Left / right footer buttons depend on the quest's state:
##   open   -> Deny | Send Party
##   ready  -> Recall | Next Quest (or Board)
##   denied -> Board | Reconsider
func _show_footer(e: Dictionary) -> void:
	_right_button.disabled = false
	match e.state:
		"ready":
			_left_button.text = BUTTON_RECALL
			S.style_button(_left_button, "paper", 28)
			_right_button.text = BUTTON_NEXT if ui.outstanding() > 0 else BUTTON_BOARD
			S.style_button(_right_button, "blue", 30)
		"denied":
			_left_button.text = BUTTON_BOARD
			S.style_button(_left_button, "paper", 28)
			_right_button.text = BUTTON_RECONSIDER
			S.style_button(_right_button, "blue", 30)
		_:
			_left_button.text = BUTTON_DENY
			S.style_button(_left_button, "red", 28)
			_right_button.text = BUTTON_SEND if not e.party.is_empty() else BUTTON_SEND_EMPTY
			_right_button.disabled = e.party.is_empty()
			S.style_button(_right_button, "green", 30)


func _on_left() -> void:
	match ui.current_entry().state:
		"ready":
			ui.recall_party()
		"denied":
			ui.close_screen()
		_:
			ui.deny_quest()


func _on_right() -> void:
	match ui.current_entry().state:
		"ready":
			if ui.outstanding() > 0:
				ui.open_assign(ui.next_open(ui.screen.index))
			else:
				ui.close_screen()
		"denied":
			ui.reconsider()
		_:
			ui.send_party()
