## Guild sheet (header "Guild" button): roster, today's recruits and upgrades,
## reachable from any step without losing your place.
## Scene: MobileFlow/Scenes/Sheets/sheet_guild.tscn
extends ColorRect

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")
const MemberRow := preload("res://MobileFlow/Scenes/Rows/member_row.tscn")
const RecruitCard := preload("res://MobileFlow/Scenes/Rows/recruit_card.tscn")
const UpgradeRow := preload("res://MobileFlow/Scenes/Rows/upgrade_row.tscn")

# ---- TEXT
const TEXT_ROSTER_TAB := "Roster %d/%d"
const TEXT_HIRE_TAB := "For hire (%d)"
const TEXT_WALLET := "%d gold, Standing %d"

# ---- NODES
@onready var _close_button: Button = %CloseButton
@onready var _help_button: Button = %HelpButton
@onready var _tabs := {"roster": %RosterTab, "hire": %HireTab, "upgrades": %UpgradesTab}
@onready var _pages := {"roster": %RosterPage, "hire": %HirePage, "upgrades": %UpgradesPage}
@onready var _roster_list: Container = %RosterList
@onready var _roster_empty: Control = %RosterEmpty
@onready var _hire_list: Container = %HireList
@onready var _hire_empty: Control = %HireEmpty
@onready var _wallet: Label = %Wallet
@onready var _upgrade_list: Container = %UpgradeList

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_close_button.pressed.connect(func(): ui.close_sheet())
	_help_button.pressed.connect(func(): ui.open_intro())
	for seg in _tabs:
		_tabs[seg].pressed.connect(func(): ui.set_guild_tab(seg))


func refresh() -> void:
	var seg: String = ui.sheet.get("seg", "roster")
	_show_tabs(seg)
	for s in _pages:
		_pages[s].visible = s == seg
	match seg:
		"roster":
			_show_roster()
		"hire":
			_show_hires()
		_:
			_show_upgrades()


## Three tabs; the open one is highlighted.
func _show_tabs(seg: String) -> void:
	_tabs.roster.text = TEXT_ROSTER_TAB % [CharacterContainer.active_characters.size(), CharacterContainer.max_characters]
	_tabs.hire.text = TEXT_HIRE_TAB % CharacterContainer.hireable_characters.size()
	for s in _tabs:
		var b: Button = _tabs[s]
		b.set_pressed_no_signal(s == seg)
		S.style_button(b)
		if s == seg:
			b.add_theme_stylebox_override("pressed", S.flat(S.INFO_BG, 0, 2, S.INFO))
			b.add_theme_color_override("font_pressed_color", S.INFO)


func _show_roster() -> void:
	var roster: Array = CharacterContainer.active_characters
	S.clear(_roster_list)
	for c in roster:
		S.add_row(_roster_list, MemberRow).setup(ui, c)
	_roster_empty.visible = roster.is_empty()


func _show_hires() -> void:
	var hires: Array = CharacterContainer.hireable_characters
	var full := CharacterContainer.active_characters.size() >= CharacterContainer.max_characters
	S.clear(_hire_list)
	for c in hires:
		S.add_row(_hire_list, RecruitCard).setup(ui, c, full)
	_hire_empty.visible = hires.is_empty()


func _show_upgrades() -> void:
	_wallet.text = TEXT_WALLET % [GameState.gold, GameState.standing]
	S.clear(_upgrade_list)
	for b in S.buildings_in_order():
		S.add_row(_upgrade_list, UpgradeRow).setup(ui, b)
