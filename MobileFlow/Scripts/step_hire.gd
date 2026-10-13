## Step 1: Hire. Today's recruits with their stats and a Hire button each.
## Skippable; on Day 1 it's where the player has to start.
extends RefCounted

const S := preload("res://MobileFlow/Scripts/flow_style.gd")


static func build(ui) -> Dictionary:
	var v := S.vbox(14)
	var roster: Array = CharacterContainer.active_characters
	var hires: Array = CharacterContainer.hireable_characters
	var cap: int = CharacterContainer.max_characters
	var room := cap - roster.size()

	v.add_child(S.heading("Hire adventurers", "Hiring is free. Your guild has room for %d more (%d/%d)." % [room, roster.size(), cap] if room > 0 else "Your guild is full (%d/%d). Upgrade the Barracks for more room." % [roster.size(), cap]))

	# current guild, as a strip of small portraits
	if not roster.is_empty():
		var strip := S.panel("inset", Vector4(10, 8, 10, 8))
		var sh := S.hbox(8)
		strip.add_child(sh)
		sh.add_child(S.label("Your guild:", 20, S.INK_SOFT))
		for c in roster:
			sh.add_child(S.portrait(c, 52))
		v.add_child(strip)

	for c in hires:
		v.add_child(_recruit(ui, c, room <= 0))
	if hires.is_empty():
		var p := S.panel("inset")
		p.add_child(S.wrap(S.label("Nobody is for hire right now. New faces arrive every morning.", 22, S.INK_SOFT)))
		v.add_child(p)

	# footer
	var f := S.vbox(4)
	if roster.is_empty():
		var w := S.label("Hire at least one adventurer to send on quests.", 20, S.WARN)
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		f.add_child(w)
	var next := S.button("Next: Quests  >", "" if roster.is_empty() else "green", 26)
	next.pressed.connect(ui.go_step.bind("quests"))
	f.add_child(next)
	return {"body": v, "footer": f}


static func _recruit(ui, c: GuildCharacter, full: bool) -> Control:
	var p := S.panel("card")
	var h := S.hbox(12)
	p.add_child(h)
	var pt := S.portrait(c, 96)
	pt.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(pt)
	var mid := S.vbox(6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nr := S.hbox(8)
	nr.add_child(S.title(c.name, 26))
	var rl := S.label(S.role_name(c), 20, S.INK_SOFT)
	rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nr.add_child(rl)
	mid.add_child(nr)
	mid.add_child(S.stat_row(c))
	var row := S.hbox(8)
	var more := S.button("Details", "", 20, 48)
	more.pressed.connect(ui.open_character.bind(c))
	row.add_child(more)
	var b := S.button("Guild full" if full else "Hire (free)", "green", 22, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = full
	b.pressed.connect(ui.hire.bind(c))
	row.add_child(b)
	mid.add_child(row)
	h.add_child(mid)
	return p
