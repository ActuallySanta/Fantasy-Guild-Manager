## Day Report: the DaySummary popup as a full-screen ledger page. One entry per
## quest that went out, with the story split into readable beats.
## Scene: MobileLedger/Scenes/Overlays/overlay_report.tscn
extends TextureRect

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")
const ReportEntry := preload("res://MobileLedger/Scenes/Rows/report_entry.tscn")

# ---- TEXT
const TEXT_TITLE := "Day %d Report"
const TEXT_SUMMARY := "%d %s went out · +%d gold"
const TEXT_NOBODY := "Nobody went out today"
const TEXT_START_DAY := "Start Day %d"
const TEXT_CLOSE := "Close report"

# ---- NODES
@onready var _title: Label = %ReportTitle
@onready var _subtitle: Label = %ReportSubtitle
@onready var _scroll: ScrollContainer = %Scroll
@onready var _entries: Container = %Entries
@onready var _empty: Control = %Empty
@onready var _action_button: Button = %ActionButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_action_button.pressed.connect(func(): ui.close_report())


func refresh() -> void:
	var rep: Dictionary = ui.report
	var results: Array = rep.results
	var gold := 0
	for r in results:
		gold += int(r.gold)
	_title.text = TEXT_TITLE % rep.day
	_subtitle.text = TEXT_SUMMARY % [results.size(), S.plural(results.size(), "quest", "quests"), gold] if not results.is_empty() else TEXT_NOBODY

	S.clear(_entries)
	for r in results:
		S.add_row(_entries, ReportEntry).setup(r)
	_empty.visible = results.is_empty()
	_scroll.scroll_vertical = 0

	# right after End Day the button starts the next day; reopened later it just closes
	var live: bool = rep.get("live", false)
	_action_button.text = TEXT_START_DAY % (GameState.day + 1) if live else TEXT_CLOSE
	S.style_button(_action_button, "green" if live else "paper", 34)
