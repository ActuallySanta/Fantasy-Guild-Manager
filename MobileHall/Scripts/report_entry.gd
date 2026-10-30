## One quest in the Day Report, short by default: result, gold, who went, who
## got hurt. "Read the story" opens the full story, one line per story beat.
## Scene: MobileHall/Scenes/Rows/report_entry.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const BeatRowScene := preload("res://MobileHall/Scenes/Rows/beat_row.tscn")

## CreatedQuest.generateResults writes bright BBCode colours meant for a dark
## screen; these swap them for darker ones that read on a light card.
const STORY_RECOLORS := {
	"[color=FFE700]": "[color=#7A5A12]", "[color=gold]": "[color=#7A5A12]",
	"[color=green]": "[color=#2F6A22]",
	"[color=FD0000]": "[color=#A3262A]", "[color=red]": "[color=#A3262A]",
}

## Icon for a story line; the first matching rule wins.
##   test: "contains" | "starts_with", text: what to look for, icon: icon name
## The special icon SUMMARY_ICON becomes a tick or cross from the quest's result.
const SUMMARY_ICON := "SUMMARY"
const BEAT_ICON_RULES := [
	{"test": "contains", "text": "passed away", "icon": "injury"},
	{"test": "contains", "text": "INJUR", "icon": "injury"},
	{"test": "contains", "text": "chest", "icon": "coins"},
	{"test": "contains", "text": "without sustaining", "icon": "defense"},
	{"test": "starts_with", "text": "Summary", "icon": SUMMARY_ICON},
	{"test": "starts_with", "text": "However", "icon": "coins"},
]
const BEAT_ICON_DEFAULT := "nav_quests"

const CARD_PADDING := Vector4(18, 14, 18, 14)

# ---- TEXT
const TEXT_SUCCESS := "Success"
const TEXT_FAILED := "Failed"
const TEXT_GOLD := "+%d"
const TEXT_PARTY := "%s · %d%% chance"
const TEXT_INJURED := "Hurt: %s"
const TEXT_NO_INJURIES := "Everyone came back unhurt"
const TEXT_DIED := "Died: %s"
const BUTTON_OPEN_STORY := "Read the story"
const BUTTON_HIDE_STORY := "Hide the story"

# ---- NODES
# Summary
@onready var _result_stamp = %Stamp           # chip.gd
@onready var _title: Label = %Title
@onready var _gold_chip = %GoldChip           # chip.gd
@onready var _party_line: Label = %PartyLine
@onready var _injured_line: Label = %HurtLine
@onready var _died_line: Label = %DiedLine
# Story
@onready var _story_button: Button = %StoryButton
@onready var _beat_list: VBoxContainer = %Beats

## The raw story text, turned into beat rows the first time it's opened.
var _story_text := ""
var _succeeded := false


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


## Stamp, title, gold, who went (with their chance), who got hurt, who died.
func _show_summary(result: Dictionary) -> void:
	if _succeeded:
		_result_stamp.set_chip(TEXT_SUCCESS, Style.GREEN, Style.WHITE, "check")
	else:
		_result_stamp.set_chip(TEXT_FAILED, Style.RED, Style.WHITE, "x")
	_title.text = result.quest.questTitle
	_gold_chip.set_chip(TEXT_GOLD % result.gold, Style.GOLD_BG, Style.GOLD_TEXT, "coins")
	_party_line.text = TEXT_PARTY % [Style.join_names(result.party), mini(int(result.chance), 100)]

	var injured: Array = result.get("injured", [])
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


# ---- story

func _toggle_story() -> void:
	if _beat_list.get_child_count() == 0:
		_build_story_beats()
	_beat_list.visible = not _beat_list.visible
	_story_button.text = BUTTON_HIDE_STORY if _beat_list.visible else BUTTON_OPEN_STORY


## One beat row per non-empty line of the story.
func _build_story_beats() -> void:
	var story := _story_text
	for bright_tag in STORY_RECOLORS:
		story = story.replace(bright_tag, STORY_RECOLORS[bright_tag])

	for line in story.split("\n"):
		var beat_text := line.strip_edges()
		if beat_text == "":
			continue
		var icon_name := _icon_for_beat(beat_text)
		var icon_tint := Color.WHITE
		if icon_name == SUMMARY_ICON:
			icon_name = "check" if _succeeded else "x"
			icon_tint = Style.GREEN_TEXT if _succeeded else Style.RED
		Style.add_row(_beat_list, BeatRowScene).setup(icon_name, icon_tint, beat_text)


func _icon_for_beat(beat_text: String) -> String:
	for rule in BEAT_ICON_RULES:
		var is_match: bool
		if rule.test == "starts_with":
			is_match = beat_text.begins_with(rule.text)
		else:
			is_match = beat_text.contains(rule.text)
		if is_match:
			return rule.icon
	return BEAT_ICON_DEFAULT
