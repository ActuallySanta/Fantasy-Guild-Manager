## Home tab: today's checklist, everyone's health, and last night's results.
## Scene: MobileLedger/Scenes/Pages/page_home.tscn
##
## The four checklist rows are fixed in the scene (%TodoHire, %TodoQuests,
## %TodoUpgrades, %TodoEnd); their icon and tile colour are set there.
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")
const HealthRow := preload("res://MobileLedger/Scenes/Rows/health_row.tscn")
const LastRow := preload("res://MobileLedger/Scenes/Rows/last_row.tscn")

## The Bone Drake countdown counts down to this day.
const DRAKE_DAY := 10

# ---- TEXT
const TEXT_DAY := "Day %d"
const TEXT_DRAKE_COMING := "The Bone Drake attacks on Day %d · %d %s left"
const TEXT_DRAKE_TODAY := "The Bone Drake is attacking today!"
const TEXT_DRAKE_GONE := "The Bone Drake has come and gone."
# checklist: [title, subtitle] per row; chips are set in _show_checklist
const TODO_HIRE_FIRST := "Hire your first adventurers"
const TODO_HIRE_COUNT := "%d of %d adventurers"
const TODO_HIRE_SUB := "%d for hire today · hiring is free"
const TODO_QUESTS_OPEN := "%d %s %s a decision"
const TODO_QUESTS_DONE := "Every quest decided"
const TODO_QUESTS_SUB := "%d accepted · %d denied"
const TODO_UPGRADES_READY := "%d %s ready to buy"
const TODO_UPGRADES_NONE := "No upgrades affordable"
const TODO_UPGRADES_SUB := "%d gold · Standing %d"
const TODO_END_OPEN := "End the day"
const TODO_END_READY := "Ready to end Day %d"
const TODO_END_DECIDE_FIRST := "Decide every quest first"
const TODO_END_PARTIES := "%d %s set out tonight"
const TODO_END_NOBODY := "Nobody is going out"
const CHIP_START_HERE := "Start here"
const CHIP_TO_DO := "To do"
const CHIP_DONE := "Done"

# ---- NODES
@onready var _day_title: Label = %DayTitle
@onready var _drake: Label = %Drake
@onready var _todo_hire = %TodoHire
@onready var _todo_quests = %TodoQuests
@onready var _todo_upgrades = %TodoUpgrades
@onready var _todo_end = %TodoEnd
@onready var _health_list: Container = %HealthList
@onready var _health_empty: Control = %HealthEmpty
@onready var _last_night_divider: Control = %LastNightDivider
@onready var _last_night: Control = %LastNight
@onready var _last_list: Container = %LastList
@onready var _last_empty: Control = %LastEmpty
@onready var _read_report_button: Button = %ReadReportButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_todo_hire.pressed.connect(func(): ui.open_tab("characters", "hire" if CharacterContainer.active_characters.is_empty() else "guild"))
	_todo_quests.pressed.connect(func(): ui.open_tab("quests"))
	_todo_upgrades.pressed.connect(func(): ui.open_tab("upgrades"))
	_todo_end.pressed.connect(func(): ui.end_day())
	_read_report_button.pressed.connect(func(): ui.open_last_report())


func refresh() -> void:
	_show_day()
	_show_checklist()
	_show_health()
	_show_last_night()


## Day number and the Bone Drake countdown.
func _show_day() -> void:
	var d := GameState.day
	_day_title.text = TEXT_DAY % d
	var left := DRAKE_DAY - d
	if d == DRAKE_DAY:
		_drake.text = TEXT_DRAKE_TODAY
	elif d > DRAKE_DAY:
		_drake.text = TEXT_DRAKE_GONE
	else:
		_drake.text = TEXT_DRAKE_COMING % [DRAKE_DAY, left, S.plural(left, "day", "days")]
	S.color(_drake, S.WAX if d == DRAKE_DAY else S.INK_SOFT)


## "Today's Ledger": hire, quests, upgrades, end the day.
func _show_checklist() -> void:
	var roster: Array = CharacterContainer.active_characters
	var out: int = ui.outstanding()
	var going: int = ui.ready_entries().size()
	var ups: int = ui.upgrades_ready()
	var healthy: Array = S.INJURY[0]

	_todo_hire.show_todo(
		TODO_HIRE_FIRST if roster.is_empty() else TODO_HIRE_COUNT % [roster.size(), CharacterContainer.max_characters],
		TODO_HIRE_SUB % CharacterContainer.hireable_characters.size(),
		CHIP_START_HERE if roster.is_empty() else "", S.INJURY[3])

	_todo_quests.show_todo(
		TODO_QUESTS_OPEN % [out, S.plural(out, "quest", "quests"), S.plural(out, "needs", "need")] if out > 0 else TODO_QUESTS_DONE,
		TODO_QUESTS_SUB % [going, ui.denied_count()],
		CHIP_TO_DO if out > 0 else CHIP_DONE, S.INJURY[1] if out > 0 else healthy)

	_todo_upgrades.show_todo(
		TODO_UPGRADES_READY % [ups, S.plural(ups, "upgrade", "upgrades")] if ups > 0 else TODO_UPGRADES_NONE,
		TODO_UPGRADES_SUB % [GameState.gold, GameState.standing], "", healthy)

	var end_sub := TODO_END_DECIDE_FIRST
	if out == 0:
		end_sub = TODO_END_PARTIES % [going, S.plural(going, "party", "parties")] if going > 0 else TODO_END_NOBODY
	_todo_end.show_todo(TODO_END_OPEN if out > 0 else TODO_END_READY % GameState.day, end_sub, "", healthy)


## Everyone's injury level at a glance.
func _show_health() -> void:
	var roster: Array = CharacterContainer.active_characters
	S.clear(_health_list)
	for i in roster.size():
		S.add_row(_health_list, HealthRow).setup(ui, roster[i], i == roster.size() - 1)
	_health_empty.visible = roster.is_empty()


## Yesterday's results (hidden on day 1).
func _show_last_night() -> void:
	var has_report: bool = not ui.last_report.is_empty()
	_last_night_divider.visible = has_report
	_last_night.visible = has_report
	if not has_report:
		return
	S.clear(_last_list)
	for result in ui.last_report.results:
		S.add_row(_last_list, LastRow).setup(result)
	_last_empty.visible = ui.last_report.results.is_empty()
