## Adventurer Codex: one character's portrait, health, backstory and stats.
extends TextureRect

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")

var ui


func setup(main) -> void:
	ui = main
	%TopBar.back_pressed.connect(func(): ui.close_page())
	%StoryToggle.pressed.connect(func():
		ui.story_open = not ui.story_open
		ui.queue_refresh())
	%AssignButton.pressed.connect(func(): ui.open_tab("quests"))
	%HireButton.pressed.connect(func():
		ui.hire(ui.page.character)
		ui.close_page())


func scroll_to_top() -> void:
	%PageScroll.scroll_vertical = 0


func refresh() -> void:
	var c: GuildCharacter = ui.page.character
	var hired: bool = CharacterContainer.active_characters.has(c)

	# --- portrait in the ornate frame, name and health ribbon
	var osb: StyleBoxFlat = %Oval.get_theme_stylebox("panel").duplicate()
	osb.bg_color = S.ROLE_GROUNDS[clampi(c.role, 0, 3)]
	%Oval.add_theme_stylebox_override("panel", osb)
	%Art.texture = ExternalContentContainer.get_character_icon(c.role)
	%CharName.text = c.name
	%Role.text = "the %s" % S.role_name(c)
	var inj: Array = S.INJURY[clampi(c.injury_level, 0, 4)]
	%Ribbon.add_theme_stylebox_override("panel", S.flat(inj[1], 4, 3, inj[2].darkened(0.1), Vector4(26, 4, 26, 6)))
	%RibbonText.text = inj[0]
	%RibbonText.add_theme_color_override("font_color", inj[2])
	%InjuryCount.text = "No injuries yet" if c.injury_count == 0 else "%d injur%s taken" % [c.injury_count, "y" if c.injury_count == 1 else "ies"]
	var e: Dictionary = ui.entry_of(c)
	%Questing.visible = not e.is_empty()
	if not e.is_empty():
		%Questing.text = "Questing: %s" % e.quest.questTitle

	# --- backstory (collapsible)
	%Chevron.texture = S.icon_tex("chev_up" if ui.story_open else "chev_down")
	%Backstory.visible = ui.story_open
	var lines := PackedStringArray()
	for line in c.description.strip_edges().split("\n"):
		if line.strip_edges() != "":
			lines.append(line.strip_edges())
	%Backstory.text = "\n".join(lines)

	# --- stats
	for i in 5:
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		var bonus := 0
		if hired and i < 4:
			bonus = GuildUpgrades.get_stat_bonus(c, i)
		var row := get_node("%%Stat%d" % i)
		row.get_node("Value").text = str(val - bonus)
		row.get_node("BonusBox/Bonus").visible = bonus > 0
		row.get_node("BonusBox/Bonus").text = "+%d" % bonus
		row.get_node("BonusBox/None").visible = bonus <= 0
		if bonus > 0:
			row.get_node("BonusBox").add_theme_stylebox_override("panel", S.flat(Color("#E3EFD2"), 8, 2, Color("#4F7A3A"), Vector4(4, 0, 4, 2)))
		else:
			row.get_node("BonusBox").add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	%ArmoryNote.visible = hired
	%ArmoryNote.text = "Green bonuses come from the Armory (level %d) and already count toward quest odds." % GuildUpgrades.get_level(GuildUpgrades.Building.ARMORY)

	# --- actions
	%AssignButton.visible = hired
	%HireButton.visible = not hired
	if not hired:
		var full: bool = CharacterContainer.active_characters.size() >= CharacterContainer.max_characters
		%HireButton.text = "Guild full" if full else "Hire %s (free)" % c.name
		%HireButton.disabled = full
