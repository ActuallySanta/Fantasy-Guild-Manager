## Step 3: End Day. Today's plan at a glance, upgrades to spend gold on, and
## the End Day button (locked until every quest is decided).
extends VBoxContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const PlanRow := preload("res://MobileFlow/Scenes/Rows/plan_row.tscn")
const UpgradeRow := preload("res://MobileFlow/Scenes/Rows/upgrade_row.tscn")

var ui


func setup(main) -> void:
	ui = main
	%LastReportButton.pressed.connect(func(): ui.open_last_report())
	%BackButton.pressed.connect(func(): ui.go_step("quests"))
	%EndDayButton.pressed.connect(func(): ui.end_day())


func footer_height() -> float:
	return %Footer.size.y


func scroll_to_top() -> void:
	%Scroll.scroll_vertical = 0


func refresh() -> void:
	var out: int = ui.outstanding()

	# --- today's plan
	S.clear(%PlanList)
	for i in ui.entries.size():
		S.add_row(%PlanList, PlanRow).setup(ui, i, i == ui.entries.size() - 1)

	# --- upgrades
	%UpgradesSubtitle.text = "You have %d gold and Standing %d." % [GameState.gold, GameState.standing]
	S.clear(%UpgradeList)
	for b in sorted_buildings():
		S.add_row(%UpgradeList, UpgradeRow).setup(ui, b)
	%LastReportButton.visible = not ui.last_report.is_empty()

	# --- footer
	%Warning.visible = out > 0
	%BackButton.visible = out > 0
	%GoingInfo.visible = out == 0
	%EndDayButton.visible = out == 0
	if out > 0:
		%Warning.text = "Decide %d more quest%s before ending the day." % [out, "" if out == 1 else "s"]
	else:
		var going: int = ui.ready_entries().size()
		%GoingInfo.text = "%d part%s will set out." % [going, "y" if going == 1 else "ies"] if going > 0 else "Nobody is going out today."
		%EndDayButton.text = "End Day %d" % GameState.day


## Working buildings first, "coming soon" ones after.
static func sorted_buildings() -> Array:
	var order: Array = GuildUpgrades.Building.values()
	order.sort_custom(func(a, b): return GuildUpgrades.is_implemented(a) and not GuildUpgrades.is_implemented(b))
	return order
