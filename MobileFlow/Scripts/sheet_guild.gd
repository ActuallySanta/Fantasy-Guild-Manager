## Guild sheet (header "Guild" button): roster, today's recruits and upgrades,
## reachable from any step without losing your place.
extends ColorRect

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const StepEnd := preload("res://MobileFlow/Scripts/step_end.gd")
const MemberRow := preload("res://MobileFlow/Scenes/Rows/member_row.tscn")
const RecruitCard := preload("res://MobileFlow/Scenes/Rows/recruit_card.tscn")
const UpgradeRow := preload("res://MobileFlow/Scenes/Rows/upgrade_row.tscn")

var ui
@onready var _tabs := {"roster": %RosterTab, "hire": %HireTab, "upgrades": %UpgradesTab}


func setup(main) -> void:
	ui = main
	%CloseButton.pressed.connect(func(): ui.close_sheet())
	%HelpButton.pressed.connect(func():
		ui.show_intro = true
		ui.queue_refresh())
	for seg in _tabs:
		_tabs[seg].pressed.connect(func():
			ui.sheet.seg = seg
			ui.queue_refresh())


func refresh() -> void:
	var roster: Array = CharacterContainer.active_characters
	var hires: Array = CharacterContainer.hireable_characters
	var cap: int = CharacterContainer.max_characters
	var seg: String = ui.sheet.get("seg", "roster")

	%RosterTab.text = "Roster %d/%d" % [roster.size(), cap]
	%HireTab.text = "For hire (%d)" % hires.size()
	for s in _tabs:
		var b: Button = _tabs[s]
		b.set_pressed_no_signal(s == seg)
		S.style_button(b)
		if s == seg:
			b.add_theme_stylebox_override("pressed", S.flat(S.INFO_BG, 0, 2, S.INFO))
			b.add_theme_color_override("font_pressed_color", S.INFO)

	%RosterPage.visible = seg == "roster"
	%HirePage.visible = seg == "hire"
	%UpgradesPage.visible = seg == "upgrades"
	match seg:
		"roster":
			S.clear(%RosterList)
			for c in roster:
				S.add_row(%RosterList, MemberRow).setup(ui, c)
			%RosterEmpty.visible = roster.is_empty()
		"hire":
			var full := roster.size() >= cap
			S.clear(%HireList)
			for c in hires:
				S.add_row(%HireList, RecruitCard).setup(ui, c, full)
			%HireEmpty.visible = hires.is_empty()
		_:
			%Wallet.text = "%d gold, Standing %d" % [GameState.gold, GameState.standing]
			S.clear(%UpgradeList)
			for b in StepEnd.sorted_buildings():
				S.add_row(%UpgradeList, UpgradeRow).setup(ui, b)
