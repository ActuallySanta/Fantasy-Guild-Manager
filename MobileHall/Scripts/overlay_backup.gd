## Backup save (Menu > Backup save): keep a copy of the run outside the
## browser, which can clear its saved games. Save backup file / Copy save code
## export the run as a save code (HallSaveTransfer); Load backup file / Paste
## save code bring one back. Loading replaces the current guild, so those two
## take two taps, like the Menu's Abandon run. Export and import work whether
## or not "Save runs" is on (an import turns it on). Back returns to the Menu;
## tapping the dimmed background closes both.
## Scene: MobileHall/Scenes/Overlays/overlay_backup.tscn
extends Control

## Font size of the buttons (design px; HallFontScale grows them with everything else).
const BUTTON_FONT_SIZE := 28

# ---- TEXT
const BUTTON_SAVE_FILE := "Save backup file"
const BUTTON_COPY_CODE := "Copy save code"
const BUTTON_LOAD_FILE := "Load backup file"
const BUTTON_PASTE_CODE := "Paste save code"
const BUTTON_CONFIRM := "Tap again to replace this guild"
const BUTTON_BACK := "Back"
const PROMPT_PASTE := "Paste your Fantasy Guild save code:"
const TOAST_SAVED := "Backup saved · keep it somewhere safe"
const TOAST_SAVE_FAILED := "Couldn't save the backup file"
const TOAST_COPIED := "Save code copied · paste it into your notes"
const TOAST_BAD_CODE := "That save code couldn't be read"
const TOAST_NEWER := "That backup is from a newer version · refresh the game first"
const TOAST_IMPORT_FAILED := "Couldn't load that backup"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _save_file_button: Button = %SaveFileButton
@onready var _copy_code_button: Button = %CopyCodeButton
@onready var _load_file_button: Button = %LoadFileButton
@onready var _paste_code_button: Button = %PasteCodeButton
@onready var _back_button: Button = %BackButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The device side of a backup (share sheet, clipboard, file picker).
var _files := HallWebFiles.new()
## Which import button was tapped once (its next tap really imports), or null.
## Cleared when the sheet closes or another button is tapped.
var _armed_button: Button = null


func setup(main: HallMain) -> void:
	hall = main
	_save_file_button.pressed.connect(_on_save_file_pressed)
	_copy_code_button.pressed.connect(_on_copy_code_pressed)
	_load_file_button.pressed.connect(_on_import_pressed.bind(_load_file_button))
	_paste_code_button.pressed.connect(_on_import_pressed.bind(_paste_code_button))
	_back_button.pressed.connect(hall.close_backup)
	_dim.gui_input.connect(_on_dim_input)
	# closing the sheet takes back a half-made import
	visibility_changed.connect(func() -> void: _armed_button = null)

	_save_file_button.text = BUTTON_SAVE_FILE
	_copy_code_button.text = BUTTON_COPY_CODE
	_back_button.text = BUTTON_BACK
	for button in [_save_file_button, _copy_code_button, _load_file_button, _paste_code_button]:
		HallStyle.style_button(button, "paper", BUTTON_FONT_SIZE)
	HallStyle.style_button(_back_button, "wood", BUTTON_FONT_SIZE)


func refresh() -> void:
	_load_file_button.text = BUTTON_CONFIRM if _armed_button == _load_file_button else BUTTON_LOAD_FILE
	_paste_code_button.text = BUTTON_CONFIRM if _armed_button == _paste_code_button else BUTTON_PASTE_CODE


## Save backup file: the run as a .txt, through the share sheet or a download.
func _on_save_file_pressed() -> void:
	_disarm()
	var code := HallSaveTransfer.build_code(hall)
	var is_saved := _files.share_or_download(code, HallSaveTransfer.file_name_for(GameState.day))
	hall.show_toast(TOAST_SAVED if is_saved else TOAST_SAVE_FAILED)


## Copy save code: the same text as the file, on the clipboard.
func _on_copy_code_pressed() -> void:
	_disarm()
	_files.copy_text(HallSaveTransfer.build_code(hall))
	hall.show_toast(TOAST_COPIED)


## Load backup file / Paste save code. The first tap asks (the button reads
## BUTTON_CONFIRM); the second opens the file picker or the paste box.
## button: which of the two was tapped.
func _on_import_pressed(button: Button) -> void:
	if _armed_button != button:
		_armed_button = button
		refresh()
		return
	_disarm()
	if button == _load_file_button:
		_files.pick_file(self, _import_text)
	else:
		var text := _files.ask_for_text(PROMPT_PASTE)
		if not text.strip_edges().is_empty():
			_import_text(text)


## Read text as a save code and, if it's good, replace the run with it (the
## hall reloads). A bad code only shows a toast: the current run is untouched.
func _import_text(text: String) -> void:
	var result := HallSaveTransfer.parse_code(text)
	match result.error:
		HallSaveTransfer.ParseError.NEWER_VERSION:
			hall.show_toast(TOAST_NEWER)
		HallSaveTransfer.ParseError.NOT_A_CODE:
			hall.show_toast(TOAST_BAD_CODE)
		_:
			if not hall.import_run(result.snapshot):
				hall.show_toast(TOAST_IMPORT_FAILED)


## Take back a half-made import (the button goes back to its own label).
func _disarm() -> void:
	_armed_button = null
	refresh()


## Tapping the dimmed background closes Backup save and the Menu.
func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hall.close_backup(false)
