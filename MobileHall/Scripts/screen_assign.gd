## Assign Party: one quest at a time, with every other quest one tap away.
## Scene: MobileHall/Scenes/Screens/screen_assign.tscn
##
## Top to bottom:
##   strip   - back to the Board, then one little scroll per quest
##             (state-coloured); switching keeps every quest's picks
##   writ    - the quest as an unrolled scroll: type, title, reward, party
##             size, favored stat, the pinned party (tap to remove) and the
##             live success chance
##   picker  - every adventurer, best fit first, with stats and what they add
##   footer  - Deny / Seal & send (or Recall / Reconsider once decided)
extends VBoxContainer

const QuestTabScene := preload("uid://cp5084mci60mt")  # MobileHall/Scenes/Rows/quest_tab.tscn
const PartySlotScene := preload("uid://cisymsmond1")  # MobileHall/Scenes/Rows/party_slot.tscn
const PickRowScene := preload("uid://cfnuyteanwwp5")  # MobileHall/Scenes/Rows/pick_row.tscn

# ---- MOTION
## Seconds the odds number and bar take to move to a new chance.
const ODDS_ROLL_SECONDS := 0.4
## How big the odds circle grows when the chance changes.
const ODDS_POP := 1.2
## The "+12%" / "-12%" that floats off the tapped row: font size, inks.
const ODDS_DELTA_FONT_SIZE := 32
const ODDS_UP_INK := Color("#3D5A2A")
const ODDS_DOWN_INK := Color("#8B2E2A")
## How hard the quest shakes when it's denied (pixels).
const DENY_SHAKE := 12.0
## The SENT stamp inked on a sent quest: where its centre sits (fraction of the
## quest card's size), text size, tilt (radians).
const WRIT_STAMP_AT := Vector2(0.74, 0.2)
const WRIT_STAMP_FONT_SIZE := 60
const WRIT_STAMP_TILT := -0.16

# ---- TEXT
# Quest writ
const TEXT_TYPE := "%s · Rank %s"
const TEXT_GOLD := "%d gold"
const TEXT_STANDING := "+%d standing"
const TEXT_PARTY_SIZE := "Up to %d"
const TEXT_PARTY_SIZE_SOLO := "Solo"
const TEXT_FAVORED := "Favors %s"
const TEXT_STAMP_SENT := "SENT"
# Party odds
const TEXT_ODDS := "%d%%"
const TEXT_ODDS_UP := "+%d%%"
const TEXT_ODDS_DOWN := "%d%%"
const TEXT_ODDS_NONE := "--"
const TEXT_ODDS_WORD := "Chance of success"
## Under the odds: what each hero's Pluck goes up by if the party wins.
## Two lines, so the column never gets wider than the screen (OddsWord wraps too).
const TEXT_PLUCK_ON_WIN := "%s\nwin for +%d Pluck"
## Under the odds, at good odds for the quest's rank: the stat(s) a win can
## train instead of Pluck (HallRules.trains_stat), e.g. "Defense or Power".
const TEXT_TRAIN_ON_WIN := "%s\nwin to train %s"
## Joins the two stats a win can train.
const TEXT_TRAIN_OR := " or "
# Picker
const PICK_HEADING := "Your adventurers"
## Only shown when "Show busy" is off and someone is hidden.
const PICK_HINT_HIDDEN := "%d busy hidden"
const BUTTON_SHOW_BUSY := "Show busy"
const NO_ROSTER := "You have no adventurers yet."
# Footer
const BUTTON_DENY := "Deny"
## Inside the shield on the Deny button: the standing denying costs.
const TEXT_DENY_COST := "-%d"
## Room kept on the Deny button's right for the shield.
const DENY_COST_ROOM := 64.0
const BUTTON_SEND := "Seal & send %s"
const BUTTON_SEND_PARTY := "Seal & send party"
const BUTTON_SEND_EMPTY := "Pin someone first"
const BUTTON_RECALL := "Recall"
const BUTTON_NEXT := "Next Quest"
const BUTTON_BOARD := "Board"
const BUTTON_RECONSIDER := "Reconsider"

# ---- NODES
# Strip
@onready var _back_button: Button = %BackButton
@onready var _quest_tabs: HBoxContainer = %QuestTabs
@onready var _scroll: ScrollContainer = %Scroll
# Quest writ
@onready var _type_label: Label = %TypeLabel
@onready var _title: Label = %Title
@onready var _gold_chip = %GoldChip           # chip.gd
@onready var _standing_chip = %StandingChip   # chip.gd
@onready var _party_size_chip = %SlotsChip    # chip.gd
@onready var _favored_chip = %FavChip         # chip.gd
@onready var _quest_card: PanelContainer = $Scroll/Margin/Col/Writ/WritMargin/QuestCard
# Party
@onready var _party_box: Control = %PartyBox
@onready var _party_seats: VBoxContainer = %Slots
@onready var _odds_value: Label = %OddsValue
@onready var _odds_circle: TextureRect = %Circle
@onready var _odds_word: Label = %OddsWord
@onready var _odds_bar = %OddsBar             # odds_bar.gd
@onready var _odds_stack: Control = %Circle.get_parent()
# Picker
@onready var _pick_header: Control = %PickHeader
@onready var _pick_heading: Label = %PickHeading
@onready var _pick_hint: Label = %PickHint
@onready var _show_busy_toggle: CheckButton = %BusyToggle
@onready var _all_busy_label: Label = %AllBusy
@onready var _pick_list: VBoxContainer = %PickList
@onready var _no_roster_box: Control = %NoRoster
@onready var _hire_button: Button = %HireButton
# Footer (left = wood, right = the wax-sealed button)
@onready var _left_button: Button = %LeftButton
@onready var _deny_cost: Control = %DenyCost
@onready var _deny_cost_value: Label = %DenyCostValue
@onready var _right_button: Button = %RightButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The quest and chance the odds were last drawn for (to animate a change on
## the same quest; switching quests just snaps). -1 = not drawn yet.
var _odds_quest_index := -1
var _shown_chance := -1
## The SENT ink on the quest card (null = none) and which quest it's for.
var _writ_stamp: Control
var _writ_stamp_quest := -1


func setup(main: HallMain) -> void:
	hall = main
	_back_button.pressed.connect(hall.close_screen)
	_hire_button.pressed.connect(func(): hall.open_tab("guild", HallMain.GUILD_SECTION_HIRE))
	_left_button.pressed.connect(_on_left_button_pressed)
	_right_button.pressed.connect(_on_right_button_pressed)
	_show_busy_toggle.toggled.connect(hall.set_show_busy_adventurers)
	_show_busy_toggle.text = BUTTON_SHOW_BUSY
	_back_button.text = BUTTON_BOARD
	_make_room_for_deny_cost()


## The Deny button's shield sits on its right edge: pad every look of the
## button on that side so the "Deny" text never runs under it.
func _make_room_for_deny_cost() -> void:
	for look in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := _left_button.get_theme_stylebox(look)
		if box == null:
			continue
		box = box.duplicate()
		box.content_margin_right = maxf(box.content_margin_right, 0.0) + DENY_COST_ROOM
		_left_button.add_theme_stylebox_override(look, box)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	var entry: Dictionary = hall.current_quest_entry()
	if entry.is_empty():
		return
	_show_quest_tabs()
	_show_quest_card(entry)
	_show_writ_stamp(entry)
	_show_party(entry)
	_show_picker(entry)
	_show_footer(entry)


# ---- strip

## One tab per quest; hidden when there's only one quest (milestone day).
func _show_quest_tabs() -> void:
	HallStyle.clear_children(_quest_tabs)
	_quest_tabs.visible = hall.quest_entries.size() > 1
	for quest_index in hall.quest_entries.size():
		var is_current: bool = quest_index == hall.active_screen.quest_index
		HallStyle.add_row(_quest_tabs, QuestTabScene).setup(hall, quest_index, is_current)


# ---- quest writ

func _show_quest_card(entry: Dictionary) -> void:
	var type_info := HallStyle.quest_type_info(entry)
	var quest: CreatedQuest = entry.quest
	var size_limit: int = hall.party_size_limit(entry)

	_type_label.text = TEXT_TYPE % [type_info.writ, HallStyle.rank_letter(quest)]
	HallStyle.set_font_color(_type_label, type_info.color)
	_title.text = quest.questTitle

	# chips: reward (gold, standing on a win), party size, favored stat
	_gold_chip.set_chip(TEXT_GOLD % quest.goldReward, HallStyle.GOLD_BG, HallStyle.TEXT_MAIN, "coins")
	_standing_chip.set_chip(TEXT_STANDING % HallRules.standing_for_win(quest), HallStyle.BLUE_BG, HallStyle.TEXT_MAIN, "shield")
	var size_text := TEXT_PARTY_SIZE_SOLO if size_limit == 1 else TEXT_PARTY_SIZE % size_limit
	_party_size_chip.set_chip(size_text, HallStyle.BLUE_BG, HallStyle.TEXT_MAIN, "person")
	var favored_stat: Dictionary = HallStyle.STATS[HallStyle.favored_stat_index(quest)]
	_favored_chip.set_chip(TEXT_FAVORED % favored_stat.name, favored_stat.bg, favored_stat.color, "", true)


# ---- party

## Seats (pinned cards or empty) and the party's success chance, circled in
## its ink. Hidden for denied quests.
func _show_party(entry: Dictionary) -> void:
	_party_box.visible = entry.state != HallStyle.QUEST_STATE_DENIED

	HallStyle.clear_children(_party_seats)
	for seat_index in hall.party_size_limit(entry):
		var seated: GuildCharacter = entry.party[seat_index] if seat_index < entry.party.size() else null
		var seat: Control = HallStyle.add_row(_party_seats, PartySlotScene)
		seat.setup(hall, entry, seated)
		# the seat someone just left fades back to empty
		if hall.pending_fx.get("seat_out", false) and seat_index == entry.party.size():
			HallFx.fade_in(seat)

	var chance: int = hall.success_chance(entry, entry.party)
	var odds := HallStyle.odds_look(chance)
	_odds_value.text = TEXT_ODDS % mini(chance, 100) if chance >= 0 else TEXT_ODDS_NONE
	_odds_word.text = _odds_caption(entry, chance, odds.word)
	HallStyle.set_font_color(_odds_value, odds.text_color)
	HallStyle.tint_art(_odds_circle, odds.text_color)
	_show_odds_change(chance)


## The caption under the odds: the odds word, then what a win grows. At good
## odds for the quest's rank that's a stat to train, otherwise Pluck.
## entry: the quest entry; chance: the party's success chance (-1 = no party);
## odds_word: HallStyle.odds_look(chance).word. Returns the caption text.
func _odds_caption(entry: Dictionary, chance: int, odds_word: String) -> String:
	if chance < 0:
		return odds_word
	if hall.trains_stat(entry, chance):
		var stat_names := PackedStringArray()
		for stat_index in hall.trained_stat_options(entry):
			stat_names.append(HallStyle.STATS[stat_index].name)
		return TEXT_TRAIN_ON_WIN % [odds_word, TEXT_TRAIN_OR.join(stat_names)]
	return TEXT_PLUCK_ON_WIN % [odds_word, hall.pluck_gain_for(chance)]


## The odds number and bar. On the same quest, a new chance rolls the number,
## slides the bar, pops the circle, and floats "+12%" / "-12%" off the row the
## player tapped. Switching quests (or the first draw) just snaps.
func _show_odds_change(chance: int) -> void:
	var shown := mini(chance, 100)
	var quest_index: int = hall.active_screen.quest_index
	var was_drawn := _odds_quest_index == quest_index
	var old_chance := _shown_chance
	_odds_quest_index = quest_index
	_shown_chance = shown

	if not was_drawn or old_chance == shown:
		_odds_value.text = TEXT_ODDS % shown if shown >= 0 else TEXT_ODDS_NONE
		_odds_bar.set_chance(shown)
		return

	_odds_bar.set_chance(shown, true)
	HallFx.pop(_odds_stack, ODDS_POP)
	if shown < 0:
		_odds_value.text = TEXT_ODDS_NONE
	else:
		HallFx.count(_odds_value, maxi(old_chance, 0), shown, ODDS_ROLL_SECONDS, TEXT_ODDS)
	var change := maxi(shown, 0) - maxi(old_chance, 0)
	if change != 0:
		var text := (TEXT_ODDS_UP if change > 0 else TEXT_ODDS_DOWN) % change
		HallFx.float_text(hall.fx_layer, hall.tap_point(), text,
				ODDS_UP_INK if change > 0 else ODDS_DOWN_INK, ODDS_DELTA_FONT_SIZE)


## A sent quest has SENT inked on it. Pressed on with the stamp animation
## right after Send (hall.pending_fx.writ_stamp); just there when you look at
## a quest sent earlier; lifted off when it's recalled.
func _show_writ_stamp(entry: Dictionary) -> void:
	var quest_index: int = hall.active_screen.quest_index
	var is_sent: bool = entry.state == HallStyle.QUEST_STATE_SENT
	var is_just_sent: bool = hall.pending_fx.get("writ_stamp", false)
	var has_right_stamp := is_instance_valid(_writ_stamp) and _writ_stamp_quest == quest_index
	if is_instance_valid(_writ_stamp) and (not is_sent or not has_right_stamp or is_just_sent):
		_writ_stamp.queue_free()
		_writ_stamp = null
	if is_sent and _writ_stamp == null:
		_writ_stamp = HallFx.stamp_onto(_quest_card, TEXT_STAMP_SENT, HallStyle.GREEN_TEXT,
				WRIT_STAMP_AT, WRIT_STAMP_FONT_SIZE, WRIT_STAMP_TILT, is_just_sent)
		_writ_stamp_quest = quest_index


## Where hall_main lands the DENIED stamp: the middle of the quest's
## title area, kept inside the visible part of the scroll.
func stamp_point() -> Vector2:
	var visible_rect := _scroll.get_global_rect()
	var point := _title.get_global_rect().get_center()
	return point.clamp(visible_rect.position, visible_rect.end)


## Deny: the quest writ shakes its head.
func shake_writ() -> void:
	HallFx.shake($Scroll/Margin/Col/Writ, DENY_SHAKE)


# ---- picker

## Every living adventurer, best fit for this quest first (the dead are left out).
## Adventurers in another quest's party (sent or picked) are left out unless
## "Show busy" is on; when shown they still say which quest they're on.
func _show_picker(entry: Dictionary) -> void:
	# split the roster into shown / hidden
	var shown_adventurers: Array = []
	var hidden_busy_count := 0
	for character in hall.roster():
		if HallStyle.is_dead(character):
			continue
		var quest_index: int = hall.quest_index_of(character)
		var is_busy_elsewhere: bool = quest_index >= 0 and hall.quest_entries[quest_index] != entry
		if is_busy_elsewhere and not hall.show_busy_adventurers:
			hidden_busy_count += 1
		else:
			shown_adventurers.append(character)

	# most chance added first
	shown_adventurers.sort_custom(func(first, second):
		return hall.chance_added_by(entry, first) > hall.chance_added_by(entry, second))

	HallStyle.clear_children(_pick_list)
	for character in shown_adventurers:
		HallStyle.add_row(_pick_list, PickRowScene).setup(hall, entry, character)

	# header, toggle and empty states
	var can_pick: bool = entry.state != HallStyle.QUEST_STATE_DENIED
	var has_roster: bool = not shown_adventurers.is_empty() or hidden_busy_count > 0
	_pick_heading.text = PICK_HEADING
	_pick_hint.visible = hidden_busy_count > 0
	_pick_hint.text = PICK_HINT_HIDDEN % hidden_busy_count
	_show_busy_toggle.set_pressed_no_signal(hall.show_busy_adventurers)
	_pick_header.visible = can_pick and has_roster
	_pick_list.visible = can_pick
	_all_busy_label.visible = can_pick and shown_adventurers.is_empty() and hidden_busy_count > 0
	_no_roster_box.visible = not has_roster


# ---- footer

## Left / right footer buttons depend on the quest's state:
##   open   -> Deny [shield -N] | Seal & send <name>
##   sent   -> Recall | Next Quest (or Board when nothing's left to decide)
##   denied -> Board | Reconsider
## The left button is always wood; the right one is the wax-sealed button.
func _show_footer(entry: Dictionary) -> void:
	_right_button.disabled = false
	_left_button.icon = null
	_deny_cost.visible = false
	match entry.state:
		HallStyle.QUEST_STATE_SENT:
			_left_button.text = BUTTON_RECALL
			_right_button.text = BUTTON_NEXT if hall.undecided_count() > 0 else BUTTON_BOARD
		HallStyle.QUEST_STATE_DENIED:
			_left_button.text = BUTTON_BOARD
			_right_button.text = BUTTON_RECONSIDER
		_:
			_left_button.text = BUTTON_DENY
			_left_button.icon = HallStyle.icon_texture("x")
			_deny_cost_value.text = TEXT_DENY_COST % HallRules.standing_for_deny(entry.quest)
			_deny_cost.visible = true
			if entry.party.is_empty():
				_right_button.text = BUTTON_SEND_EMPTY
			elif entry.party.size() == 1:
				_right_button.text = BUTTON_SEND % entry.party[0].name
			else:
				_right_button.text = BUTTON_SEND_PARTY
			_right_button.disabled = entry.party.is_empty()


## Recall (sent) / Board (denied) / Deny (open).
func _on_left_button_pressed() -> void:
	match hall.current_quest_entry().state:
		HallStyle.QUEST_STATE_SENT:
			hall.recall_party()
		HallStyle.QUEST_STATE_DENIED:
			hall.close_screen()
		_:
			hall.deny_quest()


## Next Quest or Board (sent) / Reconsider (denied) / Seal & send (open).
func _on_right_button_pressed() -> void:
	match hall.current_quest_entry().state:
		HallStyle.QUEST_STATE_SENT:
			if hall.undecided_count() > 0:
				hall.open_assign(hall.next_undecided_index(hall.active_screen.quest_index))
			else:
				hall.close_screen()
		HallStyle.QUEST_STATE_DENIED:
			hall.reconsider_quest()
		_:
			hall.send_party()
