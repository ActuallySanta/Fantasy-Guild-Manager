## Day Report: the night's results, short. A totals line, then one card per
## quest (result, gold, who went, who got hurt); the full story is behind
## "Read the story" on each card.
## Scene: MobileHall/Scenes/Overlays/overlay_report.tscn
extends Control

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const ReportEntryScene := preload("res://MobileHall/Scenes/Rows/report_entry.tscn")

# ---- TEXT
const TEXT_TITLE := "Day %d Report"
const TEXT_SUCCEEDED := "%d / %d succeeded"
const TEXT_GOLD := "+%d gold"
const TEXT_NO_INJURIES := "No injuries"
const TEXT_NOBODY_WENT := "Nobody went out. Quests are the only way to earn gold."
const BUTTON_START_DAY := "Start Day %d"
const BUTTON_CLOSE := "Close"

# ---- NODES
@onready var _title: Label = %Title
# Totals
@onready var _succeeded_chip = %WinsChip      # chip.gd
@onready var _gold_chip = %GoldChip           # chip.gd
@onready var _injured_chip = %HurtChip        # chip.gd
# Quest cards
@onready var _scroll: ScrollContainer = %Scroll
@onready var _entry_list: VBoxContainer = %Entries
@onready var _empty_label: Label = %Empty
@onready var _action_button: Button = %ActionButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The report currently built on screen (to skip rebuilding the same one).
var _built_report: Dictionary = {}


func setup(main: HallMain) -> void:
	hall = main
	_action_button.pressed.connect(hall.close_report)


func refresh() -> void:
	var report: Dictionary = hall.shown_report
	# only rebuild when a different report opens (keeps open stories open)
	var is_same_report: bool = report.get("results") == _built_report.get("results") \
			and report.get("starts_next_day") == _built_report.get("starts_next_day")
	if is_same_report:
		return
	_built_report = report

	var results: Array = report.results
	_title.text = TEXT_TITLE % report.day
	_show_totals(results)
	_show_entries(results)

	# after End Day the button starts the next day; from the Menu it just closes
	var starts_next_day: bool = report.get("starts_next_day", false)
	_action_button.text = BUTTON_START_DAY % (GameState.day + 1) if starts_next_day else BUTTON_CLOSE
	Style.style_button(_action_button, "green" if starts_next_day else "paper", 32)


## Chips: how many succeeded, total gold, how many got hurt.
func _show_totals(results: Array) -> void:
	var total_gold := 0
	var succeeded_count := 0
	var injured_count := 0
	for result in results:
		total_gold += int(result.gold)
		if result.succeeded:
			succeeded_count += 1
		injured_count += result.get("injured", []).size()

	_succeeded_chip.set_chip(TEXT_SUCCEEDED % [succeeded_count, results.size()], Style.GREEN_BG, Style.GREEN_TEXT, "check")
	_succeeded_chip.visible = not results.is_empty()
	_gold_chip.set_chip(TEXT_GOLD % total_gold, Style.GOLD_BG, Style.GOLD_TEXT, "coins")
	if injured_count > 0:
		_injured_chip.set_chip(Style.count_text(injured_count, "hurt", "hurt"), Style.RED_BG, Style.RED, "injury")
	else:
		_injured_chip.set_chip(TEXT_NO_INJURIES, Style.GREEN_BG, Style.GREEN_TEXT, "heart")


## One card per quest, or a note when nobody went out.
func _show_entries(results: Array) -> void:
	Style.clear_children(_entry_list)
	for result in results:
		Style.add_row(_entry_list, ReportEntryScene).setup(result)
	_empty_label.text = TEXT_NOBODY_WENT
	_empty_label.visible = results.is_empty()
	_scroll.scroll_vertical = 0
