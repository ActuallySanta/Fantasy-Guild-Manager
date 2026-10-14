## One quest in the Day Report (Scenes/Rows/report_entry.tscn).
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const PortraitScene := preload("res://MobileLedger/Scenes/Components/portrait.tscn")
const BeatRow := preload("res://MobileLedger/Scenes/Rows/beat_row.tscn")

## generateResults uses bright BBCode colours meant for a dark screen; swap
## them for inks that read on parchment.
const RECOLOR := {
	"[color=FFE700]": "[color=#7A5A12]", "[color=gold]": "[color=#7A5A12]",
	"[color=green]": "[color=#2F6A22]", "[color=FD0000]": "[color=#A3262A]", "[color=red]": "[color=#A3262A]",
}


func setup(r: Dictionary) -> void:
	var ok: bool = r.succeeded
	%QuestName.text = r.quest.questTitle
	%Badge.set_chip("Success" if ok else "Failed", Color("#3F7A2E") if ok else S.WAX, S.WHITE, -1, false)
	var names := []
	for c in r.party:
		var p := PortraitScene.instantiate()
		p.custom_minimum_size = Vector2(64, 64)
		p.circle = true
		%Portraits.add_child(p)
		p.show_character(c)
		names.append(c.name)
	%Names.text = " & ".join(PackedStringArray(names))
	%ChanceChip.set_chip("%d%% chance" % mini(int(r.chance), 100), Color("#EAD6A8"), S.INK)
	%GoldChip.set_icon_chip("coins", "+%d gold" % r.gold if r.gold > 0 else "No gold", Color("#F4E5AC"), S.GOLD_TEXT)
	var injuries: int = r.story.count("INJURED")
	if injuries > 0:
		%InjuryChip.set_icon_chip("injury", "%d injur%s" % [injuries, "y" if injuries == 1 else "ies"], Color("#F2CBC3"), Color("#8A1E22"))
	else:
		%InjuryChip.set_icon_chip("heart", "No injuries", Color("#D9E8CF"), Color("#2F5A27"))

	var story: String = r.story
	for k in RECOLOR:
		story = story.replace(k, RECOLOR[k])
	for line in story.split("\n"):
		var t := line.strip_edges()
		if t == "":
			continue
		var ic := "nav_quests"
		var tint := Color.WHITE
		if t.contains("INJUR"):
			ic = "injury"
		elif t.contains("chest"):
			ic = "coins"
		elif t.contains("without sustaining"):
			ic = "defense"
		elif t.begins_with("Summary"):
			ic = "check" if ok else "x"
			tint = S.GREEN_TEXT if ok else S.WAX
		elif t.begins_with("However"):
			ic = "coins"
		S.add_row(%Beats, BeatRow).setup(ic, tint, t)
