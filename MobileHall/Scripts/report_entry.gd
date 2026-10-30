## One quest in the Day Report, written as a letter home: type seal, title,
## who sent it and at what odds, a Success / Failed stamp, who got hurt or
## died, the story one line per beat, and a closing line signed by whoever
## came back.
## Scene: MobileHall/Scenes/Rows/report_entry.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const BeatRowScene := preload("res://MobileHall/Scenes/Rows/beat_row.tscn")

## CreatedQuest.generateResults writes bright BBCode colours meant for a dark
## screen; these swap them for inks that read on parchment.
const STORY_RECOLORS := {
	"[color=FFE700]": "[color=#7A5A12]", "[color=gold]": "[color=#7A5A12]",
	"[color=green]": "[color=#2F6A22]",
	"[color=FD0000]": "[color=#A3262A]", "[color=red]": "[color=#A3262A]",
	# found equipment
	"[color=4FC3F7]": "[color=#2F5F8A]",
}
## Story lines the letter says in its own words instead (the closing line).
const SKIPPED_LINE_STARTS := ["Summary", "However"]
## Icon for a story line (matched on its plain text); the first matching rule wins.
const BEAT_ICON_RULES := [
	{"test": "contains", "text": "passed away", "icon": "injury"},
	{"test": "contains", "text": "INJUR", "icon": "injury"},
	{"test": "contains", "text": "hidden cache", "icon": "rook"},
	{"test": "contains", "text": "Equipment found", "icon": "rook"},
	{"test": "contains", "text": "chest", "icon": "coins"},
	{"test": "contains", "text": "without sustaining", "icon": "defense"},
	{"test": "starts_with", "text": "Summary", "icon": SUMMARY_ICON},
	{"test": "starts_with", "text": "However", "icon": "coins"},
]
const BEAT_ICON_DEFAULT := "scroll"

# ---- TEXT
const TEXT_SUCCESS := "Success"
const TEXT_FAILED := "Failed"
const TEXT_FROM := "From %s · sent at %d%%"
const TEXT_INJURED := "Hurt: %s"
const TEXT_DIED := "Died: %s"
const TEXT_FOUND_ITEMS := "Found: %s"
const BUTTON_OPEN_STORY := "Read the story"
const BUTTON_HIDE_STORY := "Hide the story"
const TEXT_WON := "It is done, master. The reward is ours: %d gold. — %s."
const TEXT_LOST_GOLD := "Sorry, master. No reward this time, but %s brought back %d gold. — %s."
const TEXT_LOST := "Sorry, master. No reward this time. — %s."
const TEXT_NOBODY_CAME_BACK := "Nobody came back to write this letter."

# ---- NODES
# Head
@onready var _type_seal: PanelContainer = %TypeSeal
@onready var _type_tag: Label = %TypeTag
@onready var _title: Label = %Title
@onready var _gold_chip = %GoldChip           # chip.gd
@onready var _party_line: Label = %PartyLine
@onready var _injured_line: Label = %HurtLine
@onready var _died_line: Label = %DiedLine
@onready var _items_line: Label = %ItemsLine
# Story
@onready var _story_button: Button = %StoryButton
@onready var _from_line: Label = %From
@onready var _result_stamp: Control = %Stamp
@onready var _stamp_text: Label = %StampText
@onready var _injured_tag: Control = %HurtTag
@onready var _injured_text: Label = %HurtText
@onready var _died_tag: Control = %DiedTag
@onready var _died_text: Label = %DiedText
# Story and sign-off
@onready var _beat_list: VBoxContainer = %Beats
@onready var _closing_line: Label = %Closing

## Matches BBCode tags, to test story lines on their plain text.
var _bbcode_tags := RegEx.create_from_string("\\[[^\\]]*\\]")


## result = one quest result from hall_main._run_quest.
func setup(result: Dictionary) -> void:
	_succeeded = result.succeeded
	_story_text = result.story
	_show_summary(result)

	_story_button.pressed.connect(_toggle_story)
	_story_button.text = BUTTON_OPEN_STORY
	Style.style_button(_story_button, "paper", 22)
	_beat_list.visible = false

	# a death turns the card red even when the quest succeeded
	var anyone_died: bool = not result.get("died", []).is_empty()
	var border_color := Style.GREEN if _succeeded and not anyone_died else Style.RED
	Style.style_panel(self, Style.CARD_BG, border_color, 3, 16, CARD_PADDING)


## Stamp, title, gold, who went (with their chance), who got hurt, who died,
## and what equipment was found.
func _show_summary(result: Dictionary) -> void:
	if _succeeded:
		_result_stamp.set_chip(TEXT_SUCCESS, Style.GREEN, Style.WHITE, "check")
	else:
		_result_stamp.set_chip(TEXT_FAILED, Style.RED, Style.WHITE, "x")
	_title.text = result.quest.questTitle
	_from_line.text = TEXT_FROM % [Style.join_names(result.party), mini(int(result.chance), 100)]

	# the stamp is white art inked green or red (a death turns it red even on a success)
	var died: Array = result.get("died", [])
	if injured.is_empty():
		_injured_line.text = TEXT_NO_INJURIES
		Style.set_font_color(_injured_line, Style.GREEN_TEXT)
	else:
		_injured_line.text = TEXT_INJURED % Style.join_names(injured, ", ")
		Style.set_font_color(_injured_line, Style.RED)
	# "unhurt" would be wrong if someone died, so only the death line shows then
	_injured_line.visible = not injured.is_empty() or died.is_empty()

	_died_line.visible = not died.is_empty()
	_died_line.text = TEXT_DIED % Style.join_names(died, ", ")
	Style.set_font_color(_died_line, Style.RED)

	# equipment found while searching (kept whether or not the quest succeeded)
	var found_items: Array = result.get("items", [])
	var found_item_names: Array[String] = []
	for found_item in found_items:
		found_item_names.append(found_item.name)
	_items_line.visible = not found_items.is_empty()
	_items_line.text = TEXT_FOUND_ITEMS % ", ".join(found_item_names)
	Style.set_font_color(_items_line, Style.BLUE_TEXT)


	var injured: Array = result.get("injured", [])
	_injured_tag.visible = not injured.is_empty()
	_injured_text.text = TEXT_INJURED % Style.join_names(injured, ", ")
	_died_tag.visible = not died.is_empty()
	_died_text.text = TEXT_DIED % Style.join_names(died, ", ")

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
