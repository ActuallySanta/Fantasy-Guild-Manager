## One quest in the Day Report: result badge, party, chips, then the story
## split into beats (one line each, with an icon).
## Scene: MobileLedger/Scenes/Rows/report_entry.tscn
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Portrait := preload("res://MobileLedger/Scenes/Components/portrait.tscn")
const BeatRow := preload("res://MobileLedger/Scenes/Rows/beat_row.tscn")

const PORTRAIT_SIZE := 64
const SUCCESS_GREEN := Color("#3F7A2E")

## generateResults writes bright BBCode colours meant for a dark screen;
## these swap them for inks that read on parchment.
const RECOLOR := {
	"[color=FFE700]": "[color=#7A5A12]", "[color=gold]": "[color=#7A5A12]",
	"[color=green]": "[color=#2F6A22]",
	"[color=FD0000]": "[color=#A3262A]", "[color=red]": "[color=#A3262A]",
}

## Icon for a story beat. Checked in order; the first match wins.
##   [how to match, text to look for, icon]
##   "has" = anywhere in the line, "starts" = at the start of the line.
##   The "Summary" line gets a green check or red x depending on the result.
const BEAT_ICONS := [
	["has", "INJUR", "injury"],
	["has", "chest", "coins"],
	["has", "without sustaining", "defense"],
	["starts", "Summary", "SUMMARY"],
	["starts", "However", "coins"],
]
const BEAT_ICON_DEFAULT := "nav_quests"

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
@onready var _beats: Container = %Beats


func setup(r: Dictionary) -> void:
	var ok: bool = r.succeeded
	_quest_name.text = r.quest.questTitle
	_badge.set_chip(TEXT_SUCCESS if ok else TEXT_FAILED, SUCCESS_GREEN if ok else S.WAX, S.WHITE, -1, false)
	_show_party(r.party)
	_show_chips(r)
	_show_story(r.story, ok)


func _show_party(party: Array) -> void:
	for c in party:
		var p := Portrait.instantiate()
		p.custom_minimum_size = Vector2.ONE * PORTRAIT_SIZE
		p.circle = true
		_portraits.add_child(p)
		p.show_character(c)
	_names.text = S.names(party)


func _show_chips(r: Dictionary) -> void:
	_chance_chip.set_chip(TEXT_CHANCE % mini(int(r.chance), 100), Color("#EAD6A8"), S.INK)
	_gold_chip.set_icon_chip("coins", TEXT_GOLD % r.gold if r.gold > 0 else TEXT_NO_GOLD, Color("#F4E5AC"), S.GOLD_TEXT)
	var injuries: int = r.story.count("INJURED")
	if injuries > 0:
		_injury_chip.set_icon_chip("injury", TEXT_INJURIES % [injuries, S.plural(injuries, "injury", "injuries")], Color("#F2CBC3"), Color("#8A1E22"))
	else:
		_injury_chip.set_icon_chip("heart", TEXT_NO_INJURIES, Color("#D9E8CF"), Color("#2F5A27"))


## One beat row per non-empty line of the story.
func _show_story(story: String, ok: bool) -> void:
	for k in RECOLOR:
		story = story.replace(k, RECOLOR[k])
	for line in story.split("\n"):
		var text := line.strip_edges()
		if text == "":
			continue
		var icon := _beat_icon(text)
		var tint := Color.WHITE
		if icon == "SUMMARY":
			icon = "check" if ok else "x"
			tint = S.GREEN_TEXT if ok else S.WAX
		S.add_row(_beats, BeatRow).setup(icon, tint, text)


func _beat_icon(text: String) -> String:
	for rule in BEAT_ICONS:
		var found: bool = text.begins_with(rule[1]) if rule[0] == "starts" else text.contains(rule[1])
		if found:
			return rule[2]
	return BEAT_ICON_DEFAULT
