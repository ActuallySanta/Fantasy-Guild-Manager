## A filled party slot on a quest card (Scenes/Rows/slot_filled.tscn). Tap to remove.
extends Button


func setup(ui, ch: GuildCharacter, size: float) -> void:
	custom_minimum_size = Vector2(size, size + 30)
	%Portrait.custom_minimum_size = Vector2(size, size)
	%Portrait.show_character(ch)
	%CharName.text = "%s  x" % ch.name
	pressed.connect(ui.toggle_draft.bind(ch))
