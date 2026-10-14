## Characters tab: "Your Guild" (the roster) and "For Hire" (today's recruits),
## as two clearly different halves of one tab.
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const RosterCard := preload("res://MobileLedger/Scenes/Rows/roster_card.tscn")
const HireCard := preload("res://MobileLedger/Scenes/Rows/hire_card.tscn")
const EmptyBunk := preload("res://MobileLedger/Scenes/Rows/empty_bunk.tscn")

var ui


func setup(main) -> void:
	ui = main
	for b in [[%GuildSegButton, "guild"], [%HireSegButton, "hire"], [%SeeHiresButton, "hire"]]:
		b[0].pressed.connect(func():
			ui.seg = b[1]
			ui.queue_refresh())


func refresh() -> void:
	var roster: Array = CharacterContainer.active_characters
	var hires: Array = CharacterContainer.hireable_characters
	var cap: int = CharacterContainer.max_characters

	# --- segmented switch
	%GuildSegButton.text = "Your Guild  %d/%d" % [roster.size(), cap]
	%HireSegButton.text = "For Hire  ·  %d" % hires.size()
	for b in [[%GuildSegButton, "guild"], [%HireSegButton, "hire"]]:
		var on: bool = ui.seg == b[1]
		S.style_button(b[0], "red" if on else "paper", 27)
		b[0].add_theme_constant_override("icon_max_width", 34)
		for s in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
			b[0].add_theme_color_override(s, S.WHITE if on else S.INK)

	%GuildPage.visible = ui.seg == "guild"
	%HirePage.visible = ui.seg != "guild"
	if ui.seg == "guild":
		S.clear(%RosterList)
		for c in roster:
			S.add_row(%RosterList, RosterCard).setup(ui, c)
		%EmptyGuild.visible = roster.is_empty()
		S.clear(%Bunks)
		if not roster.is_empty():
			for i in maxi(0, cap - roster.size()):
				S.add_row(%Bunks, EmptyBunk)
	else:
		var full := roster.size() >= cap
		%HireNote.text = "Your guild is full (%d/%d). Upgrade the Barracks for more room." % [roster.size(), cap] if full else "Hiring is free. Room for %d more. New faces arrive every morning." % (cap - roster.size())
		S.clear(%HireList)
		for c in hires:
			S.add_row(%HireList, HireCard).setup(ui, c, full)
		%HireEmpty.visible = hires.is_empty()
