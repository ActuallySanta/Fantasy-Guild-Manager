## End-of-day card face: today's plan, upgrades, last night's report, End Day.
## Scene: MobileDeck/Scenes/Cards/card_end.tscn
extends VBoxContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const Main := preload("res://MobileDeck/Scripts/deck_main.gd")
const PlanRow := preload("res://MobileDeck/Scenes/Rows/plan_row.tscn")

# ---- TEXT
const TEXT_TITLE := "End of Day %d"
const TEXT_UPGRADES := "Upgrades"
const TEXT_UPGRADES_READY := "Upgrades  (%d ready to buy)"
const TEXT_PARTIES_GOING := "%d %s will set out tonight."
const TEXT_NOBODY_GOING := "Nobody is going out today."
const TEXT_END_DAY := "End Day %d"

# ---- NODES
@onready var _title: Label = %EndTitle
@onready var _plan_list: Container = %PlanList
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _last_report_button: Button = %LastReportButton
@onready var _going: Label = %Going
@onready var _end_day_button: Button = %EndDayButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_upgrades_button.pressed.connect(func(): ui.open_sheet("upgrades"))
	_last_report_button.pressed.connect(func(): ui.open_last_report())
	_end_day_button.pressed.connect(func(): ui.end_day())


func refresh() -> void:
	_title.text = TEXT_TITLE % GameState.day
	S.clear(_plan_list)
	for e in ui.entries:
		S.add_row(_plan_list, PlanRow).setup(ui, e)
	_show_upgrades_button()
	_last_report_button.visible = not ui.last_report.is_empty()
	var going: int = ui.ready_entries().size()
	_going.text = TEXT_PARTIES_GOING % [going, S.plural(going, "party", "parties")] if going > 0 else TEXT_NOBODY_GOING
	_end_day_button.text = TEXT_END_DAY % GameState.day


## Blue, with a count, when something can be bought.
func _show_upgrades_button() -> void:
	var buyable := 0
	for b in GuildUpgrades.Building.values():
		if GuildUpgrades.get_upgrade_status(b) == GuildUpgrades.UpgradeStatus.READY:
			buyable += 1
	_upgrades_button.text = TEXT_UPGRADES_READY % buyable if buyable > 0 else TEXT_UPGRADES
	S.style_button(_upgrades_button, "blue" if buyable > 0 else "")
