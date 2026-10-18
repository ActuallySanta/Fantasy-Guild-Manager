## One quest in the Day Report, short by default: result, gold, who went, who
## got hurt. "Read the story" opens the full story, one line per beat.
## Scene: MobileHall/Scenes/Rows/report_entry.tscn
extends PanelContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const BeatRow := preload("res://MobileHall/Scenes/Rows/beat_row.tscn")

## generateResults writes bright BBCode colours meant for a dark screen;
## these swap them for inks that read on parchment.
const RECOLOR := {
	"[color=FFE700]": "[color=#7A5A12]", "[color=gold]": "[color=#7A5A12]",
	"[color=green]": "[color=#2F6A22]",
	"[color=FD0000]": "[color=#A3262A]", "[color=red]": "[color=#A3262A]",
}
## Icon for a story line; first match wins. ["has" | "starts", text, icon]
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
const TEXT_GOLD := "+%d"
const TEXT_PARTY := "%s · %d%% chance"
const TEXT_HURT := "Hurt: %s"
const TEXT_NO_HURT := "Everyone came back unhurt"
const TEXT_OPEN := "Read the story"
const TEXT_CLOSE := "Hide the story"

# ---- NODES
@onready var _stamp = %Stamp
@onready var _title: Label = %Title
@onready var _gold = %GoldChip
@onready var _party: Label = %PartyLine
@onready var _hurt: Label = %HurtLine
@onready var _story_button: Button = %StoryButton
@onready var _beats: VBoxContainer = %Beats

var _story := ""
var _ok := false


func setup(r: Dictionary) -> void:
	_ok = r.succeeded
	_story = r.story
	_stamp.set_chip(TEXT_SUCCESS if _ok else TEXT_FAILED, S.GREEN if _ok else S.WAX, S.WHITE, "check" if _ok else "x")
	_title.text = r.quest.questTitle
	_gold.set_chip(TEXT_GOLD % r.gold, S.GOLD_BG, S.GOLD_TEXT, "coins")
	_party.text = TEXT_PARTY % [S.names(r.party), mini(int(r.chance), 100)]
	var hurt: Array = r.get("hurt", [])
	_hurt.text = TEXT_HURT % S.names(hurt, ", ") if not hurt.is_empty() else TEXT_NO_HURT
	S.color(_hurt, S.WAX if not hurt.is_empty() else S.GREEN_TEXT)
	_story_button.pressed.connect(_toggle_story)
	S.style_button(_story_button, "paper", 22)
	_beats.visible = false
	_story_button.text = TEXT_OPEN
	S.style_panel(self, S.CREAM, S.GREEN if _ok else S.WAX, 3, 16, Vector4(18, 14, 18, 14))


func _toggle_story() -> void:
	if _beats.get_child_count() == 0:
		_fill_story()
	_beats.visible = not _beats.visible
	_story_button.text = TEXT_CLOSE if _beats.visible else TEXT_OPEN


func _fill_story() -> void:
	var story := _story
	for k in RECOLOR:
		story = story.replace(k, RECOLOR[k])
	for line in story.split("\n"):
		var text := line.strip_edges()
		if text == "":
			continue
		var icon := _beat_icon(text)
		var tint := Color.WHITE
		if icon == "SUMMARY":
			icon = "check" if _ok else "x"
			tint = S.GREEN_TEXT if _ok else S.WAX
		S.add_row(_beats, BeatRow).setup(icon, tint, text)


func _beat_icon(text: String) -> String:
	for rule in BEAT_ICONS:
		var found: bool = text.begins_with(rule[1]) if rule[0] == "starts" else text.contains(rule[1])
		if found:
			return rule[2]
	return BEAT_ICON_DEFAULT
