## End-of-day card face (Scenes/Cards/card_end.tscn): today's plan, upgrades, End Day.
extends VBoxContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const PlanRow := preload("res://MobileDeck/Scenes/Rows/plan_row.tscn")

var ui


func setup(main) -> void:
	ui = main
	%UpgradesButton.pressed.connect(func(): ui.open_sheet("upgrades"))
	%LastReportButton.pressed.connect(func(): ui.open_last_report())
	%EndDayButton.pressed.connect(func(): ui.end_day())


func refresh() -> void:
	%EndTitle.text = "End of Day %d" % GameState.day
	S.clear(%PlanList)
	for e in ui.entries:
		S.add_row(%PlanList, PlanRow).setup(ui, e)

	var ready_ups := 0
	for b in GuildUpgrades.Building.values():
		if GuildUpgrades.get_upgrade_status(b) == GuildUpgrades.UpgradeStatus.READY:
			ready_ups += 1
	%UpgradesButton.text = "Upgrades  (%d ready to buy)" % ready_ups if ready_ups > 0 else "Upgrades"
	S.style_button(%UpgradesButton, "blue" if ready_ups > 0 else "")
	%LastReportButton.visible = not ui.last_report.is_empty()
	var going: int = ui.ready_entries().size()
	%Going.text = "%d part%s will set out tonight." % [going, "y" if going == 1 else "ies"] if going > 0 else "Nobody is going out today."
	%EndDayButton.text = "End Day %d" % GameState.day
