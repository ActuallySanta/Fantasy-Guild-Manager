## Character sheet: portrait, health, all five stats (with Armory bonuses) and backstory.
extends RefCounted

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const SheetGuild := preload("res://MobileFlow/Scripts/sheet_guild.gd")


static func build(ui) -> Control:
	var c: GuildCharacter = ui.sheet.character
	var hired: bool = CharacterContainer.active_characters.has(c)
	var parts := SheetGuild.frame(c.name, ui.close_sheet)
	var v: VBoxContainer = parts[1]

	var head := S.hbox(16)
	head.add_child(S.portrait(c, 160))
	var info := S.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(S.wrap(S.title(c.name, 30)))
	info.add_child(S.label("the %s" % S.role_name(c), 22, S.INK_SOFT))
	info.add_child(S.injury_chip(c.injury_level, 22))
	info.add_child(S.label("No injuries yet" if c.injury_count == 0 else "%d injur%s taken" % [c.injury_count, "y" if c.injury_count == 1 else "ies"], 20, S.INK_SOFT))
	var e: Dictionary = ui.entry_of(c)
	if not e.is_empty():
		info.add_child(S.wrap(S.label("On quest: %s" % e.quest.questTitle, 20, S.INFO)))
	if not hired:
		var full: bool = CharacterContainer.active_characters.size() >= CharacterContainer.max_characters
		var hb := S.button("Guild full" if full else "Hire (free)", "green", 22, 52)
		hb.disabled = full
		hb.pressed.connect(func():
			ui.hire(c)
			ui.close_sheet())
		info.add_child(hb)
	head.add_child(info)
	v.add_child(head)

	var stats := S.panel("card")
	var sv := S.vbox(4)
	stats.add_child(sv)
	sv.add_child(S.title("Stats", 24))
	for i in 5:
		var st: Dictionary = S.STATS[i]
		var val: int = c.pluck if i == 4 else int(c.stats[i])
		var bonus := 0
		if hired and i < 4:
			bonus = GuildUpgrades.get_stat_bonus(c, i)
		var r := S.hbox(10)
		r.custom_minimum_size.y = 40
		var n := S.label(st.name, 22, st.color)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		r.add_child(S.label(str(val - bonus), 22, st.color))
		var bl := S.label("+%d" % bonus if bonus > 0 else "", 20, S.GOOD)
		bl.custom_minimum_size.x = 44
		r.add_child(bl)
		sv.add_child(r)
	if hired:
		sv.add_child(S.wrap(S.label("+N = Armory bonus (level %d), already counted in quest odds." % GuildUpgrades.get_level(GuildUpgrades.Building.ARMORY), 18, S.INK_SOFT)))
	v.add_child(stats)

	var story := S.panel("card")
	var stv := S.vbox(6)
	story.add_child(stv)
	stv.add_child(S.title("Backstory", 24))
	for line in c.description.strip_edges().split("\n"):
		if line.strip_edges() != "":
			stv.add_child(S.wrap(S.label(line.strip_edges(), 20)))
	v.add_child(story)
	return parts[0]
