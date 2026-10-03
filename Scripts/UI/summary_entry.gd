# One quest's result on the Day Summary:
# Raid the Goblin Caves - SUCCESS ( will be green or red)
# Party: Bill the KNIGHT, Emily the KNIGHT
# The story text from generateResults()
 
class_name SummaryEntry
extends PanelContainer
 
const SUCCESS_COLOR := Color(0.45, 0.85, 0.45)
const FAIL_COLOR := Color(0.9, 0.4, 0.4)

# unique labels for nodes
@onready var _header_label: RichTextLabel = %HeaderLabel
@onready var _party_label: RichTextLabel = %PartyLabel
@onready var _story_label: RichTextLabel = %StoryLabel
 
# result is a Dictionary built by day_bar.gd
# ["quest":, "party": [...], "story":, "succeeded": true/false]
func setup(result: Dictionary) -> void:
	var succeeded: bool = result["succeeded"]
 
	# Header: quest title + sucess or fail
	var outcome := "SUCCESS" if succeeded else "FAILED"
	_header_label.text = "%s - %s" % [QuestCard.get_title(result["quest"]), outcome]
	_header_label.add_theme_color_override("font_color", SUCCESS_COLOR if succeeded else FAIL_COLOR)
 
	# Party: the names of everyone who went on quest
	var names: Array = result["party"].map(func(c): return CharacterButton.get_display_name(c))
	var party_text := "Party: " + ", ".join(PackedStringArray(names))
	if result.has("chance"):
		party_text += " (%d%% sucess chance)" % roundi(result["chance"])
	_party_label.text = party_text
	 
	# The full story of what happened on the quest.
	_story_label.text = result["story"]
 
