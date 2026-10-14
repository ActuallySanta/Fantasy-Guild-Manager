## Day Report: the DaySummary popup as a full-screen page. One entry per
## quest that went out, with the story from CreatedQuest.generateResults.
extends ColorRect

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const ReportEntry := preload("res://MobileFlow/Scenes/Rows/report_entry.tscn")

var ui


func setup(main) -> void:
	ui = main
	%ActionButton.pressed.connect(func(): ui.close_report())


func refresh() -> void:
	var rep: Dictionary = ui.report
	var results: Array = rep.results
	%ReportTitle.text = "Day %d Report" % rep.day
	var total := 0
	for r in results:
		total += int(r.gold)
	%ReportSubtitle.text = "%d quest%s went out, +%d gold" % [results.size(), "" if results.size() == 1 else "s", total] if not results.is_empty() else "Nobody went out today"
	S.clear(%Entries)
	for r in results:
		S.add_row(%Entries, ReportEntry).setup(r)
	%Empty.visible = results.is_empty()
	%Scroll.scroll_vertical = 0
	var live: bool = rep.get("live", false)
	%ActionButton.text = "Start Day %d" % (GameState.day + 1) if live else "Close report"
	S.style_button(%ActionButton, "green" if live else "")
