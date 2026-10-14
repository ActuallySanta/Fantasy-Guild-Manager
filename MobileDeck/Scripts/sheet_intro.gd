## How-to-play card (Scenes/Sheets/sheet_intro.tscn). All content is in the
## scene; this only wires the Start button.
extends ColorRect

var ui


func setup(main) -> void:
	ui = main
	%StartButton.pressed.connect(func(): ui.close_sheet())


func refresh() -> void:
	pass
