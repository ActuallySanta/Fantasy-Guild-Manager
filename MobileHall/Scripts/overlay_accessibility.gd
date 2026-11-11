## Accessibility (Menu > Accessibility): Text size, the colorblind filter and
## Reduced Motion, each a button that steps to the next choice. Changes apply
## right away and are saved (HallSettings). Back returns to the Menu; tapping
## the dimmed background closes both.
## Scene: MobileHall/Scenes/Overlays/overlay_accessibility.tscn
extends Control

## Font size of the buttons and of the note under the title (design px;
## HallFontScale grows them with everything else).
const BUTTON_FONT_SIZE := 28

# ---- TEXT
const BUTTON_TEXT_SIZE := "Text size: %s"
const BUTTON_COLOR := "Colorblind filter: %s"
const BUTTON_MOTION := "Reduced motion: %s"
const MOTION_ON := "On"
const MOTION_OFF := "Off"
const BUTTON_BACK := "Back"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _text_size_button: Button = %TextSizeButton
@onready var _color_button: Button = %ColorButton
@onready var _motion_button: Button = %MotionButton
@onready var _back_button: Button = %BackButton

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_text_size_button.pressed.connect(hall.cycle_text_size)
	_color_button.pressed.connect(hall.cycle_color_filter)
	_motion_button.pressed.connect(hall.toggle_reduce_motion)
	_back_button.pressed.connect(hall.close_accessibility)
	_dim.gui_input.connect(_on_dim_input)

	_back_button.text = BUTTON_BACK
	for button in [_text_size_button, _color_button, _motion_button]:
		HallStyle.style_button(button, "paper", BUTTON_FONT_SIZE)
	HallStyle.style_button(_back_button, "wood", BUTTON_FONT_SIZE)


func refresh() -> void:
	_text_size_button.text = BUTTON_TEXT_SIZE % HallSettings.TEXT_SIZES[hall.text_size]
	_color_button.text = BUTTON_COLOR % HallSettings.COLOR_FILTERS[hall.color_filter]
	_motion_button.text = BUTTON_MOTION % (MOTION_ON if hall.reduce_motion else MOTION_OFF)


## Tapping the dimmed background closes Accessibility and the Menu.
func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hall.close_accessibility(false)
