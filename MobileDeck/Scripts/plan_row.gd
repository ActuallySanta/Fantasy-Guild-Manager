## One quest on the end-of-day card (Scenes/Rows/plan_row.tscn). Tap to change it.
extends VBoxContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")


func setup(ui, e: Dictionary) -> void:
	%QuestName.text = e.quest.questTitle
	match e.state:
		"ready":
			var names := []
			for c in e.party:
				names.append(c.name)
			%Status.set_chip("%s · %d%%" % [", ".join(PackedStringArray(names)), mini(ui.chance_for(e, e.party), 100)], S.GOOD_BG, S.GOOD, -1, false)
		"denied":
			%Status.set_chip("Denied", S.BAD_BG, S.BAD, -1, false)
		_:
			%Status.set_chip("Undecided", S.WARN_BG, S.WARN, -1, false)
	%Tap.pressed.connect(ui.jump_to_entry.bind(e))
