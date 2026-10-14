## Welcome card: the intro blurb, split into four short steps. All content is
## in overlay_welcome.tscn; this only wires the button.
extends ColorRect

var ui


func setup(main) -> void:
	ui = main
	%OpenButton.pressed.connect(func(): ui.close_welcome())


func refresh() -> void:
	pass
