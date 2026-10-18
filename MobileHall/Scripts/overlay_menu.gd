## Menu (header button): how to play, last night's report, and the debug reset.
## Scene: MobileHall/Scenes/Overlays/overlay_menu.tscn
extends Control

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const BUTTON_HOW := "How to play"
const BUTTON_REPORT := "Last night's report"
const BUTTON_RESET := "Reset upgrades (debug)"
const BUTTON_CLOSE := "Close"

@onready var _dim: Control = %Dim
@onready var _how_button: Button = %HowButton
@onready var _report_button: Button = %ReportButton
@onready var _reset_button: Button = %ResetButton
@onready var _close_button: Button = %CloseButton

var ui


func setup(main) -> void:
	ui = main
	_how_button.pressed.connect(ui.open_welcome)
	_report_button.pressed.connect(ui.open_last_report)
	_reset_button.pressed.connect(ui.reset_upgrades)
	_close_button.pressed.connect(ui.close_menu)
	_dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: ui.close_menu())
	_how_button.text = BUTTON_HOW
	_report_button.text = BUTTON_REPORT
	_reset_button.text = BUTTON_RESET
	_close_button.text = BUTTON_CLOSE
	for b in [_how_button, _report_button, _reset_button]:
		S.style_button(b, "paper", 28)
	S.style_button(_close_button, "wood", 28)


func refresh() -> void:
	_report_button.disabled = ui.last_report.is_empty()
	_reset_button.visible = GuildUpgrades.SHOW_DEBUG_BUTTONS
