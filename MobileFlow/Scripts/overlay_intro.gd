## First-launch card explaining the three steps of each day. All content is in
## overlay_intro.tscn; this only wires the Start button.
extends ColorRect

var ui


func setup(main) -> void:
	ui = main
	%StartButton.pressed.connect(func(): ui.close_intro())


func refresh() -> void:
	pass
