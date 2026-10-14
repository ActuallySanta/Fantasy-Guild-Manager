## One quest in the Day Report: result, party, gold / injuries, and the story.
## Scene: MobileFlow/Scenes/Rows/report_entry.tscn
extends PanelContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Portrait := preload("res://MobileFlow/Scenes/Components/portrait.tscn")

## generateResults writes bright BBCode colours meant for a dark screen;
## these swap them for the UI's meaning colours.
const RECOLOR := {
	"[color=FFE700]": S.GOLD, "[color=gold]": S.GOLD,
	"[color=green]": S.GOOD,
	"[color=FD0000]": S.BAD, "[color=red]": S.BAD,
}

# ---- TEXT
const TEXT_SUCCESS := "Success"
const TEXT_FAILED := "Failed"
const TEXT_CHANCE := "%d%% chance"
const TEXT_GOLD := "+%d gold"
const TEXT_NO_GOLD := "No gold"
const TEXT_INJURIES := "%d %s"
const TEXT_NO_INJURIES := "No injuries"

# ---- NODES
@onready var _quest_name: Label = %QuestName
@onready var _badge = %Badge
@onready var _portraits: Container = %Portraits
@onready var _names: Label = %Names
@onready var _chance_chip = %ChanceChip
@onready var _gold_chip = %GoldChip
@onready var _injury_chip = %InjuryChip
@onready var _story: RichTextLabel = %Story


func setup(r: Dictionary) -> void:
	var ok: bool = r.succeeded
	_quest_name.text = r.quest.questTitle
	_badge.set_chip(TEXT_SUCCESS if ok else TEXT_FAILED, S.GOOD_BG if ok else S.BAD_BG, S.GOOD if ok else S.BAD)
	_show_party(r.party)
	_show_chips(r)
	_story.text = _story_text(r.story)


func _show_party(party: Array) -> void:
	for c in party:
		var p := Portrait.instantiate()
		p.custom_minimum_size = Vector2(56, 56)
		_portraits.add_child(p)
		p.show_character(c)
	_names.text = S.names(party, " & ")


func _show_chips(r: Dictionary) -> void:
	_chance_chip.set_chip(TEXT_CHANCE % mini(int(r.chance), 100))
	_gold_chip.set_icon_chip("coins", TEXT_GOLD % r.gold if r.gold > 0 else TEXT_NO_GOLD, S.GOLD_BG, S.GOLD)
	var injuries: int = r.story.count("INJURED")
	if injuries > 0:
		_injury_chip.set_chip(TEXT_INJURIES % [injuries, S.plural(injuries, "injury", "injuries")], S.BAD_BG, S.BAD)
	else:
		_injury_chip.set_chip(TEXT_NO_INJURIES, S.GOOD_BG, S.GOOD)


## The story with recoloured BBCode and blank lines removed.
func _story_text(story: String) -> String:
	for k in RECOLOR:
		story = story.replace(k, "[color=#%s]" % RECOLOR[k].to_html(false))
	var beats := PackedStringArray()
	for line in story.split("\n"):
		if line.strip_edges() != "":
			beats.append(line.strip_edges())
	return "\n".join(beats)
