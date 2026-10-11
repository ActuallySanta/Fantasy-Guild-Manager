## Settings tab: help, plus the upgrades page's debug buttons (when enabled).
extends RefCounted

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")


static func build(ui) -> Control:
	var v := S.vbox(26)
	v.add_child(S.divider("Settings", 38))

	var help := S.panel("card", Vector4(26, 22, 26, 24))
	var hv := S.vbox(14)
	help.add_child(hv)
	hv.add_child(S.title("Help", 32))
	hv.add_child(S.wrap(S.label("See the welcome steps again.", 25, S.INK_SOFT)))
	var w := S.button("Show the welcome", "paper", 28)
	w.pressed.connect(func():
		ui.show_welcome = true
		ui.queue_refresh())
	hv.add_child(w)
	v.add_child(help)

	if GuildUpgrades.SHOW_DEBUG_BUTTONS:
		var dbg := S.panel("inset", Vector4(26, 22, 26, 24))
		var dv := S.vbox(14)
		dbg.add_child(dv)
		dv.add_child(S.title("Prototype tools", 32))
		dv.add_child(S.wrap(S.label("The upgrades page's debug buttons, kept here so they stay out of the way of play.", 25, S.INK_SOFT)))
		var row := S.hbox(14)
		var g := S.button("+200 Gold", "wood", 28)
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.pressed.connect(GuildUpgrades.add_gold.bind(200))
		row.add_child(g)
		var st := S.button("+1 Standing", "wood", 28)
		st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		st.pressed.connect(GuildUpgrades.add_standing.bind(1))
		row.add_child(st)
		dv.add_child(row)
		var r := S.button("Reset upgrades", "paper", 28)
		r.pressed.connect(func():
			GuildUpgrades.reset()
			ui.toast("Upgrades reset"))
		dv.add_child(r)
		v.add_child(dbg)
	return v
