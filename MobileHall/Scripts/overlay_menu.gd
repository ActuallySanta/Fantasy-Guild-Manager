## Menu (header button): how to play, last night's report, Accessibility (text
## size, colorblind filter, reduced motion: overlay_accessibility.gd), Debug
## tools (cheats for testing, only when GuildUpgrades.SHOW_DEBUG_BUTTONS:
## overlay_debug.gd), and Abandon run (two taps: the first asks, the second
## deletes the saved run and starts a new guild).
## A small line under Close says which build is running (HallBuildInfo), so a
## phone can tell whether it's on the latest web deploy.
## Scene: MobileHall/Scenes/Overlays/overlay_menu.tscn
extends Control

## Font size of the build line under Close (pixels): small, it's a footnote.
const BUILD_FONT_SIZE := 20

# ---- TEXT
const BUTTON_HOW_TO_PLAY := "How to play"
const BUTTON_REPORT := "Last night's report"
const BUTTON_ACCESSIBILITY := "Accessibility"
const BUTTON_DEBUG := "Debug tools"
const BUTTON_CLOSE := "Close"
const BUTTON_ABANDON := "Abandon run"
const BUTTON_ABANDON_CONFIRM := "Tap again to abandon this guild"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _how_to_play_button: Button = %HowButton
@onready var _report_button: Button = %ReportButton
@onready var _accessibility_button: Button = %AccessibilityButton
@onready var _debug_button: Button = %DebugButton
@onready var _abandon_button: Button = %AbandonButton
@onready var _close_button: Button = %CloseButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## Which build is running, built in setup() under Close, so the menu scene
## doesn't need a new node.
var _build_label: Label
## Abandon run was tapped once: the next tap really abandons. Cleared when the menu closes.
var _is_abandon_armed := false


func setup(main: HallMain) -> void:
	hall = main
	_how_to_play_button.pressed.connect(hall.open_welcome)
	_report_button.pressed.connect(hall.open_previous_report)
	_accessibility_button.pressed.connect(hall.open_accessibility)
	_debug_button.pressed.connect(hall.open_debug)
	_build_label = Label.new()
	_build_label.name = "BuildLabel"
	_build_label.theme_type_variation = &"ItalicLabel"
	HallFontScale.set_size(_build_label, "font_size", BUILD_FONT_SIZE)
	_build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_label.custom_minimum_size.x = 40
	_build_label.text = HallBuildInfo.label()
	_close_button.add_sibling(_build_label)
	_close_button.pressed.connect(hall.close_menu)
	_abandon_button.pressed.connect(_on_abandon_pressed)
	_dim.gui_input.connect(_on_dim_input)
	# closing the menu takes back a half-made Abandon
	visibility_changed.connect(func() -> void: _is_abandon_armed = false)

	_how_to_play_button.text = BUTTON_HOW_TO_PLAY
	_report_button.text = BUTTON_REPORT
	_accessibility_button.text = BUTTON_ACCESSIBILITY
	_debug_button.text = BUTTON_DEBUG
	_close_button.text = BUTTON_CLOSE
	for button in [_how_to_play_button, _report_button, _accessibility_button, _debug_button]:
		HallStyle.style_button(button, "paper", 28)
	HallStyle.style_button(_abandon_button, "red", 28)
	HallStyle.style_button(_close_button, "wood", 28)


func refresh() -> void:
	# no report until the first day has ended
	_report_button.disabled = hall.previous_report.is_empty()
	_debug_button.visible = GuildUpgrades.SHOW_DEBUG_BUTTONS
	_abandon_button.text = BUTTON_ABANDON_CONFIRM if _is_abandon_armed else BUTTON_ABANDON


## Abandon run: the first tap asks (the button reads BUTTON_ABANDON_CONFIRM),
## the second starts a new guild (hall.start_new_run deletes the save).
func _on_abandon_pressed() -> void:
	if not _is_abandon_armed:
		_is_abandon_armed = true
		refresh()
		return
	_is_abandon_armed = false
	hall.start_new_run()


## Tapping the dimmed background closes the menu.
func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hall.close_menu()
