## Step 2: Quests. One quest per screen with the party picker right under it.
## Send or Deny moves straight on to the next undecided quest.
## Scene: MobileFlow/Scenes/Steps/step_quest.tscn
extends VBoxContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")
const QuestDot := preload("res://MobileFlow/Scenes/Rows/quest_dot.tscn")
const PickRow := preload("res://MobileFlow/Scenes/Rows/pick_row.tscn")
const SlotFilled := preload("res://MobileFlow/Scenes/Rows/slot_filled.tscn")
const SlotEmpty := preload("res://MobileFlow/Scenes/Rows/slot_empty.tscn")

# ---- TEXT
const TEXT_QUEST_OF := "Quest %d of %d"
const TEXT_TYPE_RANK := "%s, Rank %s"
const TEXT_MILESTONE := "Milestone"
const TEXT_GOLD := "%d gold"
const TEXT_SOLO := "Solo"
const TEXT_PARTY_OF := "Party of up to %d"
const TEXT_FAV_NOTE := "(counts twice)"
const TEXT_FAV_NOTE_PLUCK := "(Pluck doesn't change the odds)"
const TEXT_PARTY_SET := "Party set: %s. They leave when the day ends."
const TEXT_DENIED := "You denied this quest."
const TEXT_SEND := "Send party"
const TEXT_SEND_DISABLED := "Pick a party first"

# ---- NODES
@onready var _scroll: ScrollContainer = %Scroll
@onready var _footer: Control = %Footer
# no quests today
@onready var _no_quests: Control = %NoQuests
@onready var _to_end_button: Button = %ToEndButton
# which quest of today's board
@onready var _quest_nav: Control = %QuestNav
@onready var _quest_of: Label = %QuestOf
@onready var _dots: Container = %Dots
# the quest card
@onready var _quest_card: Control = %QuestCard
@onready var _quest_title: Label = %QuestTitle
@onready var _type_chip = %TypeChip
@onready var _gold_chip = %GoldChip
@onready var _party_chip = %PartyChip
@onready var _fav_chip = %FavChip
@onready var _fav_note: Label = %FavNote
@onready var _milestone_note: Control = %MilestoneNote
# decision already made
@onready var _decision_panel: PanelContainer = %DecisionPanel
@onready var _decision_text: Label = %DecisionText
# party slots + odds
@onready var _odds_panel: Control = %OddsPanel
@onready var _slots: Container = %Slots
@onready var _chance_percent: Label = %ChancePercent
@onready var _chance_word: Label = %ChanceWord
@onready var _chance_gauge = %ChanceGauge
# party picker
@onready var _no_roster: Control = %NoRoster
@onready var _go_hire_button: Button = %GoHireButton
@onready var _pick_heading: Control = %PickHeading
@onready var _pick_list: Container = %PickList
# footer buttons
@onready var _decided_buttons: Control = %DecidedButtons
@onready var _change_button: Button = %ChangeButton
@onready var _next_button: Button = %NextButton
@onready var _open_buttons: Control = %OpenButtons
@onready var _deny_button: Button = %DenyButton
@onready var _send_button: Button = %SendButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_go_hire_button.pressed.connect(func(): ui.go_step("hire"))
	_to_end_button.pressed.connect(func(): ui.go_step("end"))
	_change_button.pressed.connect(func(): ui.reopen_quest())
	_next_button.pressed.connect(func(): ui.advance())
	_deny_button.pressed.connect(func(): ui.deny_quest())
	_send_button.pressed.connect(func(): ui.send_party())


func footer_height() -> float:
	return _footer.size.y


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	var e: Dictionary = ui.current_entry()
	_show_no_quests(e.is_empty())
	if e.is_empty():
		return
	var decided: bool = e.state != "open"
	var party: Array = e.party if decided else ui.draft
	_show_nav()
	_show_quest(e)
	_show_decision(e)
	_show_slots_and_odds(e, party)
	_show_picker(e, decided)
	_show_footer(decided)


## "No quests today": hide everything else and offer End Day.
func _show_no_quests(none: bool) -> void:
	_no_quests.visible = none
	_to_end_button.visible = none
	for n in [_quest_nav, _quest_card, _decision_panel, _odds_panel, _no_roster, _pick_heading, _pick_list, _decided_buttons, _open_buttons]:
		n.visible = not none


## "Quest 2 of 5" plus one numbered square per quest.
func _show_nav() -> void:
	_quest_of.text = TEXT_QUEST_OF % [ui.quest_index + 1, ui.entries.size()]
	S.clear(_dots)
	for i in ui.entries.size():
		S.add_row(_dots, QuestDot).setup(ui, i)


func _show_quest(e: Dictionary) -> void:
	var q: CreatedQuest = e.quest
	var milestone: bool = e.milestone
	var n: int = ui.slot_count(e)
	_quest_title.text = q.questTitle
	S.color(_quest_title, S.BAD if milestone else S.INK)
	var type_name: String = TEXT_MILESTONE if milestone else S.TYPE_NAMES.get(int(q.type), "Quest")
	_type_chip.set_chip(TEXT_TYPE_RANK % [type_name, S.rank_letter(q)])
	_gold_chip.set_icon_chip("coins", TEXT_GOLD % q.goldReward, S.GOLD_BG, S.GOLD)
	_party_chip.set_chip(TEXT_SOLO if n == 1 else TEXT_PARTY_OF % n)
	var fav := S.favored_index(q)
	var st: Dictionary = S.STATS[fav]
	_fav_chip.set_icon_chip("", st.name, st.bg, st.color, 22, true)
	_fav_note.text = TEXT_FAV_NOTE if fav < 4 else TEXT_FAV_NOTE_PLUCK
	_milestone_note.visible = milestone


## Green "Party set" or red "You denied this quest" banner.
func _show_decision(e: Dictionary) -> void:
	_decision_panel.visible = e.state != "open"
	if e.state == "open":
		return
	var sent: bool = e.state == "ready"
	var fg := S.GOOD if sent else S.BAD
	_decision_panel.add_theme_stylebox_override("panel", S.flat(S.GOOD_BG if sent else S.BAD_BG, 0, 1, fg, Vector4(14, 10, 14, 10)))
	_decision_text.text = TEXT_PARTY_SET % S.names(e.party) if sent else TEXT_DENIED
	S.color(_decision_text, fg)


func _show_slots_and_odds(e: Dictionary, party: Array) -> void:
	S.clear(_slots)
	for i in ui.slot_count(e):
		if i < party.size():
			S.add_row(_slots, SlotFilled).show_character(party[i])
		else:
			S.add_row(_slots, SlotEmpty)
	var chance: int = ui.chance_for(e, party)
	var o: Array = S.odds(chance)
	_chance_percent.text = S.percent(chance)
	S.color(_chance_percent, o[1])
	_chance_word.text = o[0]
	S.color(_chance_word, o[1])
	_chance_gauge.set_value(0.0 if chance < 0 else minf(chance, 100) / 100.0, o[2])


## Everyone in the guild, best fit for this quest first. Hidden once decided.
func _show_picker(e: Dictionary, decided: bool) -> void:
	var roster: Array = CharacterContainer.active_characters.duplicate()
	_no_roster.visible = roster.is_empty()
	_pick_heading.visible = not roster.is_empty() and not decided
	_pick_list.visible = _pick_heading.visible
	S.clear(_pick_list)
	if not _pick_list.visible:
		return
	roster.sort_custom(func(a, b): return S.fit_score(e.quest, a) > S.fit_score(e.quest, b))
	for c in roster:
		S.add_row(_pick_list, PickRow).setup(ui, e, c, ui.slot_count(e))


## Decided: Change decision / Next. Open: Deny / Send party.
func _show_footer(decided: bool) -> void:
	_decided_buttons.visible = decided
	_open_buttons.visible = not decided
	var has_party: bool = not ui.draft.is_empty()
	_send_button.text = TEXT_SEND if has_party else TEXT_SEND_DISABLED
	_send_button.disabled = not has_party
	S.style_button(_send_button, "green" if has_party else "")
