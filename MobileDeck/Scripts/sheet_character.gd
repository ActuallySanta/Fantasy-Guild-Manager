## Character bottom sheet (Scenes/Sheets/sheet_character.tscn): portrait, health,
## all five stats (with Armory bonuses) and backstory.
extends ColorRect

const S := preload("res://MobileDeck/Scripts/deck_style.gd")

var ui


func setup(main) -> void:
	ui = main
	%CloseButton.pressed.connect(func(): ui.close_sheet())


func refresh() -> void:
	var c: GuildCharacter = ui.sheet.character
	var hired: bool = CharacterContainer.active_characters.has(c)
	%SheetTitle.text = c.name
	%Portrait.show_character(c)
	%Role.text = "the %s" % S.role_name(c)
	%Injury.set_injury(c.injury_level)
	%InjuryCount.text = "No injuries yet" if c.injury_count == 0 else "%d injur%s taken" % [c.injury_count, "y" if c.injury_count == 1 else "ies"]
	var e: Dictionary = ui.entry_of(c)
	%OnQuest.visible = not e.is_empty()
	if not e.is_empty():
		%OnQuest.text = "On quest: %s" % e.quest.questTitle
	for i in 5:
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		var bonus := 0
		if hired and i < 4:
			bonus = GuildUpgrades.get_stat_bonus(c, i)
		var row := get_node("%%Stat%d" % i)
		row.get_node("Value").text = str(val - bonus)
		row.get_node("Bonus").text = "+%d" % bonus if bonus > 0 else ""
	%ArmoryNote.visible = hired
	%ArmoryNote.text = "+N = Armory bonus (level %d), already counted in quest odds." % GuildUpgrades.get_level(GuildUpgrades.Building.ARMORY)
	var lines := PackedStringArray()
	for line in c.description.strip_edges().split("\n"):
		if line.strip_edges() != "":
			lines.append(line.strip_edges())
	%Backstory.text = "\n".join(lines)
