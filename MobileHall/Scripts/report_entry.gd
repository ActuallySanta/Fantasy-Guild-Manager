## One quest in the Day Report, written as a letter home: type seal, title,
## who sent it and at what odds, a Success / Failed stamp, who got hurt, the
## story one line per beat, and a closing line signed by the party.
## Scene: MobileHall/Scenes/Rows/report_entry.tscn
extends PanelContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const BeatRow := preload("res://MobileHall/Scenes/Rows/beat_row.tscn")

## generateResults writes bright BBCode colours meant for a dark screen;
## these swap them for inks that read on parchment.
const RECOLOR := {
	"[color=FFE700]": "[color=#6B5A1E]", "[color=gold]": "[color=#6B5A1E]",
	"[color=green]": "[color=#3D5A2A]",
	"[color=FD0000]": "[color=#8B2E2A]", "[color=red]": "[color=#8B2E2A]",
}
## Story lines the letter says in its own words instead (the closing line).
const SKIP_LINES := ["Summary", "However"]
## Icon for a story line (matched on the plain text); first match wins.
const BEAT_ICONS := [
	["succumbed", "skull"],
	["ATTACKED", "swords"],
	["INJUR", "swords"],
	["chest", "chest"],
	["lockbox", "chest"],
	["wallet", "chest"],
	["secret room", "chest"],
	["artifact", "chest"],
]
const BEAT_ICON_DEFAULT := "scroll"

# ---- TEXT
const TEXT_SUCCESS := "Success"
const TEXT_FAILED := "Failed"
const TEXT_FROM := "From %s · sent at %d%%"
const TEXT_HURT := "Hurt: %s"
const TEXT_WON := "It is done, master. The reward is ours: %d gold. — %s."
const TEXT_LOST_GOLD := "Sorry, master. No reward this time, but %s brought back %d gold. — %s."
const TEXT_LOST := "Sorry, master. No reward this time. — %s."

# ---- NODES
@onready var _type_seal: PanelContainer = %TypeSeal
@onready var _type_tag: Label = %TypeTag
@onready var _title: Label = %Title
@onready var _from: Label = %From
@onready var _hurt_tag: Control = %HurtTag
@onready var _hurt_text: Label = %HurtText
@onready var _beats: VBoxContainer = %Beats
@onready var _closing: Label = %Closing
@onready var _stamp: Control = %Stamp
@onready var _stamp_text: Label = %StampText

var _tags := RegEx.create_from_string("\\[[^\\]]*\\]")


func setup(r: Dictionary) -> void:
	var ok: bool = r.succeeded
	var info := S.type_info(r)
	S.seal(_type_seal, _type_tag, info.tag, info.color)
	_title.text = r.quest.questTitle
	_from.text = TEXT_FROM % [S.names(r.party), mini(int(r.chance), 100)]
	_stamp_text.text = TEXT_SUCCESS if ok else TEXT_FAILED
	var ink := S.GREEN_TEXT if ok else S.WAX
	S.tint(_stamp, ink)
	S.color(_stamp_text, ink)
	var hurt: Array = r.get("hurt", [])
	_hurt_tag.visible = not hurt.is_empty()
	_hurt_text.text = TEXT_HURT % S.names(hurt, ", ")
	_fill_story(r.story)
	_closing.text = _closing_line(r)


func _fill_story(story: String) -> void:
	for k in RECOLOR:
		story = story.replace(k, RECOLOR[k])
	for line in story.split("\n"):
		var text := line.strip_edges()
		var plain := _tags.sub(text, "", true).strip_edges()
		if plain == "" or SKIP_LINES.any(func(w): return plain.begins_with(w)):
			continue
		S.add_row(_beats, BeatRow).setup(_beat_icon(plain), text)


func _beat_icon(plain: String) -> String:
	for rule in BEAT_ICONS:
		if plain.contains(rule[0]):
			return rule[1]
	return BEAT_ICON_DEFAULT


## "Sorry, master. ... — M." signed with the party's initials.
func _closing_line(r: Dictionary) -> String:
	var initials := PackedStringArray()
	for c in r.party:
		initials.append(c.name.left(1))
	var signed := " & ".join(initials)
	if r.succeeded:
		return TEXT_WON % [r.gold, signed]
	if r.gold > 0:
		return TEXT_LOST_GOLD % ["I" if r.party.size() == 1 else "we", r.gold, signed]
	return TEXT_LOST % signed
