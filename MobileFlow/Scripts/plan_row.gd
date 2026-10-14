## One quest in the End Day step's "Today's plan" (Rows/plan_row.tscn). Tap to revisit it.
extends VBoxContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


func setup(ui, i: int, last: bool) -> void:
	var e: Dictionary = ui.entries[i]
	%QuestName.text = e.quest.questTitle
	match e.state:
		"ready":
			var names := []
			for c in e.party:
				names.append(c.name)
			%Status.set_chip("%s, %d%%" % [", ".join(PackedStringArray(names)), mini(ui.chance_for(e, e.party), 100)], S.GOOD_BG, S.GOOD)
		"denied":
			%Status.set_chip("Denied", S.BAD_BG, S.BAD)
		_:
			%Status.set_chip("Not decided", S.WARN_BG, S.WARN)
	%Line.visible = not last
	%Tap.pressed.connect(ui.show_quest.bind(i))
