## One quest in the Day Report (Rows/report_entry.tscn).
extends PanelContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const PortraitScene := preload("res://MobileFlow/Scenes/Components/portrait.tscn")


## generateResults uses bright BBCode colours meant for a dark screen; map them
## to the UI's meaning colours (gold = gold, green = good, red = bad).
static func recolor(t: String) -> String:
	var map := {
		"[color=FFE700]": S.GOLD, "[color=gold]": S.GOLD, "[color=green]": S.GOOD,
		"[color=FD0000]": S.BAD, "[color=red]": S.BAD,
	}
	for k in map:
		t = t.replace(k, "[color=#%s]" % map[k].to_html(false))
	return t


func setup(r: Dictionary) -> void:
	%QuestName.text = r.quest.questTitle
	var ok: bool = r.succeeded
	%Badge.set_chip("Success" if ok else "Failed", S.GOOD_BG if ok else S.BAD_BG, S.GOOD if ok else S.BAD)
	var names := []
	for c in r.party:
		var p := PortraitScene.instantiate()
		p.custom_minimum_size = Vector2(56, 56)
		%Portraits.add_child(p)
		p.show_character(c)
		names.append(c.name)
	%Names.text = " & ".join(PackedStringArray(names))
	%ChanceChip.set_chip("%d%% chance" % mini(int(r.chance), 100))
	%GoldChip.set_icon_chip("coins", "+%d gold" % r.gold if r.gold > 0 else "No gold", S.GOLD_BG, S.GOLD)
	var injuries: int = r.story.count("INJURED")
	if injuries > 0:
		%InjuryChip.set_chip("%d injur%s" % [injuries, "y" if injuries == 1 else "ies"], S.BAD_BG, S.BAD)
	else:
		%InjuryChip.set_chip("No injuries", S.GOOD_BG, S.GOOD)
	var beats := PackedStringArray()
	for line in recolor(r.story).split("\n"):
		if line.strip_edges() != "":
			beats.append(line.strip_edges())
	%Story.text = "\n".join(beats)
