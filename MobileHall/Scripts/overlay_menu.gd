## Menu (header button): how to play, last night's report, and the debug reset.
## Scene: MobileHall/Scenes/Overlays/overlay_menu.tscn
extends Control

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

# ---- TEXT
const BUTTON_HOW_TO_PLAY := "How to play"
const BUTTON_REPORT := "Last night's report"
const BUTTON_RESET := "Reset upgrades (debug)"
const BUTTON_CLOSE := "Close"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _how_to_play_button: Button = %HowButton
@onready var _report_button: Button = %ReportButton
@onready var _reset_button: Button = %ResetButton
@onready var _close_button: Button = %CloseButton

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_how_to_play_button.pressed.connect(hall.open_welcome)
	_report_button.pressed.connect(hall.open_previous_report)
	_reset_button.pressed.connect(hall.reset_upgrades)
	_close_button.pressed.connect(hall.close_menu)
	_dim.gui_input.connect(_on_dim_input)

	_how_to_play_button.text = BUTTON_HOW_TO_PLAY
	_report_button.text = BUTTON_REPORT
	_reset_button.text = BUTTON_RESET
	_close_button.text = BUTTON_CLOSE
	for button in [_how_to_play_button, _report_button, _reset_button]:
		Style.style_button(button, "paper", 28)
	Style.style_button(_close_button, "wood", 28)


func refresh() -> void:
	# no report until the first day has ended
	_report_button.disabled = hall.previous_report.is_empty()
	_reset_button.visible = GuildUpgrades.SHOW_DEBUG_BUTTONS


## Tapping the dimmed background closes the menu.
func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hall.close_menu()
