## Step 3: End Day. Today's plan at a glance, upgrades to spend gold on, and
## the End Day button (swapped for "Back to quests" until every quest is decided).
## Scene: MobileFlow/Scenes/Steps/step_end.tscn
extends VBoxContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")
const PlanRow := preload("res://MobileFlow/Scenes/Rows/plan_row.tscn")
const UpgradeRow := preload("res://MobileFlow/Scenes/Rows/upgrade_row.tscn")

# ---- TEXT
const TEXT_WALLET := "You have %d gold and Standing %d."
const TEXT_DECIDE_MORE := "Decide %d more %s before ending the day."
const TEXT_PARTIES_GOING := "%d %s will set out."
const TEXT_NOBODY_GOING := "Nobody is going out today."
const TEXT_END_DAY := "End Day %d"

# ---- NODES
@onready var _scroll: ScrollContainer = %Scroll
@onready var _footer: Control = %Footer
@onready var _plan_list: Container = %PlanList
@onready var _upgrades_subtitle: Label = %UpgradesSubtitle
@onready var _upgrade_list: Container = %UpgradeList
@onready var _last_report_button: Button = %LastReportButton
@onready var _warning: Label = %Warning
@onready var _back_button: Button = %BackButton
@onready var _going_info: Label = %GoingInfo
@onready var _end_day_button: Button = %EndDayButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_last_report_button.pressed.connect(func(): ui.open_last_report())
	_back_button.pressed.connect(func(): ui.go_step("quests"))
	_end_day_button.pressed.connect(func(): ui.end_day())


func footer_height() -> float:
	return _footer.size.y


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	_show_plan()
	_show_upgrades()
	_last_report_button.visible = not ui.last_report.is_empty()
	_show_footer()


## One row per quest: who's going and their odds, or Denied / Not decided.
func _show_plan() -> void:
	S.clear(_plan_list)
	for i in ui.entries.size():
		S.add_row(_plan_list, PlanRow).setup(ui, i, i == ui.entries.size() - 1)


func _show_upgrades() -> void:
	_upgrades_subtitle.text = TEXT_WALLET % [GameState.gold, GameState.standing]
	S.clear(_upgrade_list)
	for b in S.buildings_in_order():
		S.add_row(_upgrade_list, UpgradeRow).setup(ui, b)


func _show_footer() -> void:
	var out: int = ui.outstanding()
	_warning.visible = out > 0
	_back_button.visible = out > 0
	_going_info.visible = out == 0
	_end_day_button.visible = out == 0
	if out > 0:
		_warning.text = TEXT_DECIDE_MORE % [out, S.plural(out, "quest", "quests")]
		return
	var going: int = ui.ready_entries().size()
	_going_info.text = TEXT_PARTIES_GOING % [going, S.plural(going, "party", "parties")] if going > 0 else TEXT_NOBODY_GOING
	_end_day_button.text = TEXT_END_DAY % GameState.day
