## Assign Party: one quest at a time, with every other quest one tap away.
## Scene: MobileHall/Scenes/Screens/screen_assign.tscn
##
## Top to bottom:
##   strip   - back to the Board, then one tab per quest (state-coloured);
##             switching keeps every quest's picks
##   quest   - type, title, reward, party size, favored stat
##   party   - the seats (tap to remove) and the live success chance
##   picker  - every adventurer, best fit first, with stats and what they add
##   footer  - Deny / Send (or Recall / Reconsider once decided)
extends VBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const QuestTabScene := preload("res://MobileHall/Scenes/Rows/quest_tab.tscn")
const PartySlotScene := preload("res://MobileHall/Scenes/Rows/party_slot.tscn")
const PickRowScene := preload("res://MobileHall/Scenes/Rows/pick_row.tscn")

## Padding inside the quest card.
const QUEST_CARD_PADDING := Vector4(20, 14, 20, 14)

# ---- TEXT
# Quest card
const TEXT_TYPE := "%s · Rank %s"
const TEXT_GOLD := "%d gold"
const TEXT_PARTY_SIZE := "Up to %d"
const TEXT_PARTY_SIZE_SOLO := "Solo"
const TEXT_FAVORED := "Favors %s"
const STATUS_OPEN := "Pick up to %s. Their stats add up to the chance."
const STATUS_DRAFT := "Picks are kept if you look at another quest."
const STATUS_SENT := "Sent. Tap someone to change the party, or recall it."
const STATUS_DENIED := "Denied. Reconsider to put it back on the board."
# Party odds
const TEXT_ODDS := "%d%%"
const TEXT_ODDS_NONE := "--"
# Picker
const PICK_HEADING := "Your adventurers · best fit first"
const PICK_HEADING_HIDDEN := "Free adventurers · %d busy hidden"
const BUTTON_SHOW_BUSY := "Show busy"
const NO_ROSTER := "You have no adventurers yet."
# Footer
const BUTTON_DENY := "Deny"
const BUTTON_SEND := "Send Party"
const BUTTON_SEND_EMPTY := "Pick someone"
const BUTTON_RECALL := "Recall"
const BUTTON_NEXT := "Next Quest"
const BUTTON_BOARD := "Board"
const BUTTON_RECONSIDER := "Reconsider"

# ---- NODES
# Strip
@onready var _back_button: Button = %BackButton
@onready var _quest_tabs: HBoxContainer = %QuestTabs
@onready var _scroll: ScrollContainer = %Scroll
# Quest card
@onready var _quest_card: PanelContainer = %QuestCard
@onready var _type_label: Label = %TypeLabel
@onready var _title: Label = %Title
@onready var _gold_chip = %GoldChip           # chip.gd
@onready var _party_size_chip = %SlotsChip    # chip.gd
@onready var _favored_chip = %FavChip         # chip.gd
@onready var _status: Label = %Status
# Party
@onready var _party_box: Control = %PartyBox
@onready var _party_seats: HBoxContainer = %Slots
@onready var _odds_value: Label = %OddsValue
@onready var _odds_word: Label = %OddsWord
@onready var _odds_bar = %OddsBar             # odds_bar.gd
# Picker
@onready var _pick_header: Control = %PickHeader
@onready var _pick_heading: Label = %PickHeading
@onready var _show_busy_toggle: CheckButton = %BusyToggle
@onready var _all_busy_label: Label = %AllBusy
@onready var _pick_list: VBoxContainer = %PickList
@onready var _no_roster_box: Control = %NoRoster
@onready var _hire_button: Button = %HireButton
# Footer
@onready var _left_button: Button = %LeftButton
@onready var _right_button: Button = %RightButton

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_back_button.pressed.connect(hall.close_screen)
	_hire_button.pressed.connect(func(): hall.open_tab("guild", HallMain.GUILD_SECTION_HIRE))
	_left_button.pressed.connect(_on_left_button_pressed)
	_right_button.pressed.connect(_on_right_button_pressed)
	_show_busy_toggle.toggled.connect(hall.set_show_busy_adventurers)
	_show_busy_toggle.text = BUTTON_SHOW_BUSY
	Style.style_button(_back_button, "paper", 22)
	Style.style_button(_hire_button, "blue", 26)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	var entry: Dictionary = hall.current_quest_entry()
	if entry.is_empty():
		return
	_show_quest_tabs()
	_show_quest_card(entry)
	_show_party(entry)
	_show_picker(entry)
	_show_footer(entry)


# ---- strip

## One tab per quest; hidden when there's only one quest (milestone day).
func _show_quest_tabs() -> void:
	Style.clear_children(_quest_tabs)
	_quest_tabs.visible = hall.quest_entries.size() > 1
	for quest_index in hall.quest_entries.size():
		var is_current: bool = quest_index == hall.active_screen.quest_index
		Style.add_row(_quest_tabs, QuestTabScene).setup(hall, quest_index, is_current)


# ---- quest card

func _show_quest_card(entry: Dictionary) -> void:
	var type_info := Style.quest_type_info(entry)
	var quest: CreatedQuest = entry.quest
	var size_limit: int = hall.party_size_limit(entry)

	_type_label.text = TEXT_TYPE % [type_info.name, Style.rank_letter(quest)]
	Style.set_font_color(_type_label, type_info.color)
	_title.text = quest.questTitle

	# chips: reward, party size, favored stat
	_gold_chip.set_chip(TEXT_GOLD % quest.goldReward, Style.GOLD_BG, Style.GOLD_TEXT, "coins")
	var size_text := TEXT_PARTY_SIZE_SOLO if size_limit == 1 else TEXT_PARTY_SIZE % size_limit
	_party_size_chip.set_chip(size_text, Style.BLUE_BG, Style.BLUE_TEXT, "nav_characters")
	var favored_stat: Dictionary = Style.STATS[Style.favored_stat_index(quest)]
	_favored_chip.set_chip(TEXT_FAVORED % favored_stat.name, favored_stat.bg, favored_stat.color, "", true)

	# status line and card colour by state
	match entry.state:
		Style.QUEST_STATE_SENT:
			_status.text = STATUS_SENT
			Style.style_panel(_quest_card, Style.SENT_CARD_BG, Style.GREEN, 4, 18, QUEST_CARD_PADDING)
		Style.QUEST_STATE_DENIED:
			_status.text = STATUS_DENIED
			Style.style_panel(_quest_card, Style.DENIED_CARD_BG, Style.RED, 4, 18, QUEST_CARD_PADDING)
		_:
			if entry.party.is_empty():
				_status.text = STATUS_OPEN % Style.count_text(size_limit, "adventurer", "adventurers")
			else:
				_status.text = STATUS_DRAFT
			Style.style_panel(_quest_card, Style.CARD_BG, type_info.color, 4, 18, QUEST_CARD_PADDING)


# ---- party

## Seats (filled or empty) and the party's success chance. Hidden for denied quests.
func _show_party(entry: Dictionary) -> void:
	_party_box.visible = entry.state != Style.QUEST_STATE_DENIED

	Style.clear_children(_party_seats)
	for seat_index in hall.party_size_limit(entry):
		var seated: GuildCharacter = entry.party[seat_index] if seat_index < entry.party.size() else null
		Style.add_row(_party_seats, PartySlotScene).setup(hall, seated)

	var chance: int = hall.success_chance(entry, entry.party)
	var odds := Style.odds_look(chance)
	_odds_value.text = TEXT_ODDS % mini(chance, 100) if chance >= 0 else TEXT_ODDS_NONE
	_odds_word.text = odds.word
	Style.set_font_color(_odds_value, odds.text_color)
	Style.set_font_color(_odds_word, odds.text_color)
	_odds_bar.set_chance(mini(chance, 100))


# ---- picker

## Everyone, best fit for this quest first; dead adventurers last.
## Adventurers in another quest's party (sent or picked) are left out unless
## "Show busy" is on; when shown they still say which quest they're on.
func _show_picker(entry: Dictionary) -> void:
	# split the roster into shown / hidden
	var shown_adventurers: Array = []
	var hidden_busy_count := 0
	for character in hall.roster():
		var quest_index: int = hall.quest_index_of(character)
		var is_busy_elsewhere: bool = quest_index >= 0 and hall.quest_entries[quest_index] != entry
		if is_busy_elsewhere and not hall.show_busy_adventurers:
			hidden_busy_count += 1
		else:
			shown_adventurers.append(character)

	# living before dead, then most chance added first
	shown_adventurers.sort_custom(func(first, second):
		if Style.is_dead(first) != Style.is_dead(second):
			return Style.is_dead(second)
		return hall.chance_added_by(entry, first) > hall.chance_added_by(entry, second))

	Style.clear_children(_pick_list)
	for character in shown_adventurers:
		Style.add_row(_pick_list, PickRowScene).setup(hall, entry, character)

	# header, toggle and empty states
	var can_pick: bool = entry.state != Style.QUEST_STATE_DENIED
	var has_roster: bool = not hall.roster().is_empty()
	_pick_heading.text = PICK_HEADING_HIDDEN % hidden_busy_count if hidden_busy_count > 0 else PICK_HEADING
	_show_busy_toggle.set_pressed_no_signal(hall.show_busy_adventurers)
	Style.style_button(_show_busy_toggle, "blue" if hall.show_busy_adventurers else "paper", 21)
	_pick_header.visible = can_pick and has_roster
	_pick_list.visible = can_pick
	_all_busy_label.visible = can_pick and shown_adventurers.is_empty() and hidden_busy_count > 0
	_no_roster_box.visible = not has_roster


# ---- footer

## Left / right footer buttons depend on the quest's state:
##   open   -> Deny | Send Party
##   sent   -> Recall | Next Quest (or Board when nothing's left to decide)
##   denied -> Board | Reconsider
func _show_footer(entry: Dictionary) -> void:
	_right_button.disabled = false
	match entry.state:
		Style.QUEST_STATE_SENT:
			_set_footer_button(_left_button, BUTTON_RECALL, "paper", 28)
			var right_text := BUTTON_NEXT if hall.undecided_count() > 0 else BUTTON_BOARD
			_set_footer_button(_right_button, right_text, "blue", 30)
		Style.QUEST_STATE_DENIED:
			_set_footer_button(_left_button, BUTTON_BOARD, "paper", 28)
			_set_footer_button(_right_button, BUTTON_RECONSIDER, "blue", 30)
		_:
			var has_party: bool = not entry.party.is_empty()
			_set_footer_button(_left_button, BUTTON_DENY, "red", 28)
			_set_footer_button(_right_button, BUTTON_SEND if has_party else BUTTON_SEND_EMPTY, "green", 30)
			_right_button.disabled = not has_party


func _set_footer_button(button: Button, text: String, kind: String, font_size: int) -> void:
	button.text = text
	Style.style_button(button, kind, font_size)


## Recall (sent) / Board (denied) / Deny (open).
func _on_left_button_pressed() -> void:
	match hall.current_quest_entry().state:
		Style.QUEST_STATE_SENT:
			hall.recall_party()
		Style.QUEST_STATE_DENIED:
			hall.close_screen()
		_:
			hall.deny_quest()


## Next Quest or Board (sent) / Reconsider (denied) / Send Party (open).
func _on_right_button_pressed() -> void:
	match hall.current_quest_entry().state:
		Style.QUEST_STATE_SENT:
			if hall.undecided_count() > 0:
				hall.open_assign(hall.next_undecided_index(hall.active_screen.quest_index))
			else:
				hall.close_screen()
		Style.QUEST_STATE_DENIED:
			hall.reconsider_quest()
		_:
			hall.send_party()
