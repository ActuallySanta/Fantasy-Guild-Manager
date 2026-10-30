## One quest in the Day Report, written as a letter home: type seal, title,
## who sent it and at what odds, a Success / Failed stamp, who got hurt or
## died, what equipment was found, the story one line per beat, and a closing
## line signed by whoever came back.
## Scene: MobileHall/Scenes/Rows/report_entry.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const BeatRowScene := preload("res://MobileHall/Scenes/Rows/beat_row.tscn")

## CreatedQuest.generateResults writes bright BBCode colours meant for a dark
## screen; these swap them for inks that read on parchment.
const STORY_RECOLORS := {
	"[color=FFE700]": "[color=#6B5A1E]", "[color=gold]": "[color=#6B5A1E]",
	"[color=green]": "[color=#3D5A2A]",
	"[color=FD0000]": "[color=#8B2E2A]", "[color=red]": "[color=#8B2E2A]",
	# equipment found while searching (CreatedQuest._find_equipment)
	"[color=4FC3F7]": "[color=#2F4A66]",
}
## Story lines the letter says in its own words instead (the closing line, and
## the Found tag for "Equipment found").
const SKIPPED_LINE_STARTS := ["Summary", "However", "Equipment found"]
## Icon for a story line (matched on its plain text); the first matching rule wins.
const BEAT_ICON_RULES := [
	{"text": "succumbed", "icon": "skull"},
	{"text": "passed away", "icon": "skull"},
	{"text": "ATTACKED", "icon": "swords"},
	{"text": "INJUR", "icon": "swords"},
	{"text": "hidden cache", "icon": "chest"},
	{"text": "chest", "icon": "chest"},
	{"text": "lockbox", "icon": "chest"},
	{"text": "wallet", "icon": "chest"},
	{"text": "secret room", "icon": "chest"},
	{"text": "artifact", "icon": "chest"},
]
const BEAT_ICON_DEFAULT := "scroll"

# ---- TEXT
const TEXT_SUCCESS := "Success"
const TEXT_FAILED := "Failed"
const TEXT_FROM := "From %s · sent at %d%%"
const TEXT_INJURED := "Hurt: %s"
const TEXT_DIED := "Died: %s"
const TEXT_FOUND := "Found: %s"
const TEXT_WON := "It is done, master. The reward is ours: %d gold. — %s."
const TEXT_LOST_GOLD := "Sorry, master. No reward this time, but %s brought back %d gold. — %s."
const TEXT_LOST := "Sorry, master. No reward this time. — %s."
const TEXT_NOBODY_CAME_BACK := "Nobody came back to write this letter."

# ---- NODES
# Head
@onready var _type_seal: PanelContainer = %TypeSeal
@onready var _type_tag: Label = %TypeTag
@onready var _title: Label = %Title
@onready var _from_line: Label = %From
@onready var _result_stamp: Control = %Stamp
@onready var _stamp_text: Label = %StampText
@onready var _injured_tag: Control = %HurtTag
@onready var _injured_text: Label = %HurtText
@onready var _died_tag: Control = %DiedTag
@onready var _died_text: Label = %DiedText
@onready var _found_tag: Control = %FoundTag
@onready var _found_text: Label = %FoundText
# Story and sign-off
@onready var _beat_list: VBoxContainer = %Beats
@onready var _closing_line: Label = %Closing

## Matches BBCode tags, to test story lines on their plain text.
var _bbcode_tags := RegEx.create_from_string("\\[[^\\]]*\\]")


## result = one quest result from hall_main._run_quest.
func setup(result: Dictionary) -> void:
	var succeeded: bool = result.succeeded
	var type_info := Style.quest_type_info(result)
	Style.style_tag(_type_seal, _type_tag, type_info.tag, type_info.color)
	_title.text = result.quest.questTitle
	_from_line.text = TEXT_FROM % [Style.join_names(result.party), mini(int(result.chance), 100)]

	# the stamp is white art inked green or red (a death turns it red even on a success)
	var died: Array = result.get("died", [])
	_stamp_text.text = TEXT_SUCCESS if succeeded else TEXT_FAILED
	var stamp_ink := Style.GREEN_TEXT if succeeded and died.is_empty() else Style.RED
	Style.tint_art(_result_stamp, stamp_ink)
	Style.set_font_color(_stamp_text, stamp_ink)

	var injured: Array = result.get("injured", [])
	_injured_tag.visible = not injured.is_empty()
	_injured_text.text = TEXT_INJURED % Style.join_names(injured, ", ")
	_died_tag.visible = not died.is_empty()
	_died_text.text = TEXT_DIED % Style.join_names(died, ", ")

	# equipment found while searching; the guild keeps it even on a failed quest
	# (results from before this feature have no "items" key, so default to none)
	var found_items: Array = result.get("items", [])
	var found_item_names := PackedStringArray()
	for found_item in found_items:
		found_item_names.append(found_item.name)
	_found_tag.visible = not found_items.is_empty()
	_found_text.text = TEXT_FOUND % ", ".join(found_item_names)

	_build_story_beats(result.story)
	_closing_line.text = _closing_text(result)


## One beat row per story line (summary lines are left to the sign-off).
func _build_story_beats(story: String) -> void:
	for bright_tag in STORY_RECOLORS:
		story = story.replace(bright_tag, STORY_RECOLORS[bright_tag])
	for line in story.split("\n"):
		var beat_text := line.strip_edges()
		var plain_text := _bbcode_tags.sub(beat_text, "", true).strip_edges()
		if plain_text == "" or SKIPPED_LINE_STARTS.any(func(start): return plain_text.begins_with(start)):
			continue
		Style.add_row(_beat_list, BeatRowScene).setup(_icon_for_beat(plain_text), Style.TEXT_SOFT, beat_text)


func _icon_for_beat(plain_text: String) -> String:
	for rule in BEAT_ICON_RULES:
		if plain_text.contains(rule.text):
			return rule.icon
	return BEAT_ICON_DEFAULT


## "Sorry, master. ... — M." signed with the initials of whoever came back.
func _closing_text(result: Dictionary) -> String:
	var died: Array = result.get("died", [])
	var survivors: Array = result.party.filter(func(character): return not died.has(character))
	if survivors.is_empty():
		return TEXT_NOBODY_CAME_BACK
	var initials := PackedStringArray()
	for character in survivors:
		initials.append(character.name.left(1))
	var signature := " & ".join(initials)
	if result.succeeded:
		return TEXT_WON % [result.gold, signature]
	if result.gold > 0:
		var speaker := "I" if survivors.size() == 1 else "we"
		return TEXT_LOST_GOLD % [speaker, result.gold, signature]
	return TEXT_LOST % signature
