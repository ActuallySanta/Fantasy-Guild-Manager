## Home tab: what to do today, who's hurt, and last night's results.
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const HealthRow := preload("res://MobileLedger/Scenes/Rows/health_row.tscn")
const LastRow := preload("res://MobileLedger/Scenes/Rows/last_row.tscn")

var ui


func setup(main) -> void:
	ui = main
	%TodoHire.pressed.connect(func(): ui.open_tab("characters", "hire" if CharacterContainer.active_characters.is_empty() else "guild"))
	%TodoQuests.pressed.connect(func(): ui.open_tab("quests"))
	%TodoUpgrades.pressed.connect(func(): ui.open_tab("upgrades"))
	%TodoEnd.pressed.connect(func(): ui.end_day())
	%ReadReportButton.pressed.connect(func(): ui.open_last_report())


func refresh() -> void:
	var roster: Array = CharacterContainer.active_characters

	# --- day card
	var d := GameState.day
	%DayTitle.text = "Day %d" % d
	var drake := "The Bone Drake attacks on Day 10 · %d day%s left" % [10 - d, "" if 10 - d == 1 else "s"]
	if d == 10:
		drake = "The Bone Drake is attacking today!"
	elif d > 10:
		drake = "The Bone Drake has come and gone."
	%Drake.text = drake
	%Drake.add_theme_color_override("font_color", S.WAX if d == 10 else S.INK_SOFT)

	# --- today's checklist
	var out: int = ui.outstanding()
	var ready: int = ui.ready_entries().size()
	var denied: int = ui.entries.filter(func(e): return e.state == "denied").size()
	var ups := 0
	for b in GuildUpgrades.Building.values():
		if GuildUpgrades.get_upgrade_status(b) == GuildUpgrades.UpgradeStatus.READY:
			ups += 1
	%TodoHire.show_todo(
		"Hire your first adventurers" if roster.is_empty() else "%d of %d adventurers" % [roster.size(), CharacterContainer.max_characters],
		"%d for hire today · hiring is free" % CharacterContainer.hireable_characters.size(),
		"Start here" if roster.is_empty() else "", S.INJURY[3])
	%TodoQuests.show_todo(
		"%d quest%s need%s a decision" % [out, "" if out == 1 else "s", "s" if out == 1 else ""] if out > 0 else "Every quest decided",
		"%d accepted · %d denied" % [ready, denied],
		"To do" if out > 0 else "Done", S.INJURY[1] if out > 0 else S.INJURY[0])
	%TodoUpgrades.show_todo(
		"%d upgrade%s ready to buy" % [ups, "" if ups == 1 else "s"] if ups > 0 else "No upgrades affordable",
		"%d gold · Standing %d" % [GameState.gold, GameState.standing], "", S.INJURY[0])
	%TodoEnd.show_todo(
		"End the day" if out > 0 else "Ready to end Day %d" % GameState.day,
		"Decide every quest first" if out > 0 else ("%d part%s set out tonight" % [ready, "y" if ready == 1 else "ies"] if ready > 0 else "Nobody is going out"),
		"", S.INJURY[0])

	# --- adventurer health (injury levels at a glance)
	S.clear(%HealthList)
	for i in roster.size():
		S.add_row(%HealthList, HealthRow).setup(ui, roster[i], i == roster.size() - 1)
	%HealthEmpty.visible = roster.is_empty()

	# --- last night's report
	var has_last: bool = not ui.last_report.is_empty()
	%LastNightDivider.visible = has_last
	%LastNight.visible = has_last
	if has_last:
		S.clear(%LastList)
		for res in ui.last_report.results:
			S.add_row(%LastList, LastRow).setup(res)
		%LastEmpty.visible = ui.last_report.results.is_empty()
