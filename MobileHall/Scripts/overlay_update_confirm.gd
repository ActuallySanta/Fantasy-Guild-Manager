## Update confirmation: shown by Debug tools' Check for update when the live
## site has a newer build than the one running (HallWebUpdate.check_latest).
##   - which build this is and which is newest
##   - whether the run comes back after the reload (saving on, not a debug
##     run) or would be lost, so export it first
##   - Export save: the run as a backup file (same as Menu > Backup save)
##   - Cancel / Update (HallWebUpdate.update_now: save, then reload into the
##     new deploy)
## It belongs to overlay_debug.gd, which opens it; tapping the dim cancels.
## Drawn over the whole screen (top_level).
## Scene: MobileHall/Scenes/Overlays/overlay_update_confirm.tscn
extends Control

## Font size of the buttons (design px; HallFontScale grows them with everything else).
const BUTTON_FONT_SIZE := 28

# ---- TEXT
const TITLE := "A new version is ready"
const BUILDS := "This build: %s\nNewest: %s"
const NOTE_SAVED := "Your run is saved and loads back after the update."
const NOTE_NOT_SAVED := "This run isn't being saved · export it first or it's lost."
const BUTTON_EXPORT := "Export save"
const BUTTON_CANCEL := "Cancel"
const BUTTON_UPDATE := "Update"
## Same wording as the Backup save sheet (overlay_backup.gd).
const TOAST_SAVED := "Backup saved · keep it somewhere safe"
const TOAST_SAVE_FAILED := "Couldn't save the backup file"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _title: Label = %Title
@onready var _builds: Label = %Builds
@onready var _note: Label = %Note
@onready var _export_button: Button = %ExportButton
@onready var _cancel_button: Button = %CancelButton
@onready var _update_button: Button = %UpdateButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The device side of a backup file (share sheet or download).
var _files := HallWebFiles.new()


func setup(main: HallMain) -> void:
	hall = main
	_export_button.pressed.connect(_on_export_pressed)
	_cancel_button.pressed.connect(close)
	_update_button.pressed.connect(_on_update_pressed)
	_dim.gui_input.connect(_on_dim_input)

	_title.text = TITLE
	_export_button.text = BUTTON_EXPORT
	_cancel_button.text = BUTTON_CANCEL
	_update_button.text = BUTTON_UPDATE
	HallStyle.style_button(_export_button, "paper", BUTTON_FONT_SIZE)
	HallStyle.style_button(_cancel_button, "wood", BUTTON_FONT_SIZE)
	HallStyle.style_button(_update_button, "gold", BUTTON_FONT_SIZE)


## Show the popup. current_stamp / latest_stamp: this build's and the site's
## build stamps (HallBuildInfo.stamp() / what check_latest fetched).
func open(current_stamp: String, latest_stamp: String) -> void:
	_builds.text = BUILDS % [current_stamp, latest_stamp]
	# HallMain.save_now writes nothing in these two cases
	var is_saved := hall.is_save_enabled and not hall.is_debug_run
	_note.text = NOTE_SAVED if is_saved else NOTE_NOT_SAVED
	visible = true
	HallFx.fade_in(self, 0.0, 0.15)


func close() -> void:
	visible = false


## Export save: the run as a .txt, through the share sheet or a download.
## Straight from the press, so the browser allows it. The popup stays open.
func _on_export_pressed() -> void:
	var code := HallSaveTransfer.build_code(hall)
	var is_saved := _files.share_or_download(code, HallSaveTransfer.file_name_for(GameState.day))
	hall.show_toast(TOAST_SAVED if is_saved else TOAST_SAVE_FAILED)


func _on_update_pressed() -> void:
	close()
	HallWebUpdate.update_now(hall)


## Tapping the dimmed background cancels.
func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
