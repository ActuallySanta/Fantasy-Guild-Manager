# Script for the end day button, when pressed, it finds every quest
# that's ready to go out runs the quest system's generateResults() 
# on each, and shows the Day Summary.
extends PanelContainer
 
@export var quest_list: QuestList
@export var day_summary: DaySummary
 
# Chance (0-100) passed to generateResults(). Placeholder until the
# quest system works it out from the party's stats.
@export var success_chance: float = 80.0
@onready var _end_day_button: Button = %EndDayButton
 
func _ready() -> void:
	_end_day_button.pressed.connect(end_day)
 
func end_day() -> void:
	if quest_list == null or day_summary == null:
		push_error("DayBar: drag ContentList into Quest List and DaySummary into Day Summary in the Inspector.")
		return
 
	# Each result is a Dictionary the summary screen shows
	var results := []
 
	for card in quest_list.get_dispatched_cards():
		var party := card.get_party()
 
		# generateResults() wants typed Array[GuildCharacter]
		# so copy the plain party Array into one.
		var typed_party: Array[GuildCharacter] = []
		typed_party.assign(party)
 
		var story: String = card.quest.generateResults(typed_party, success_chance)
 
		results.append({
			"quest": card.quest,
			"party": party,
			"story": story,
			"succeeded": _did_succeed(story),
		})
 
	# Only one End Day per day
	_end_day_button.disabled = true
 
	get_tree().call_group("roster", "close")
	day_summary.show_results(results)
 
 
# The quest system currently only reports success inside the story
# text so we gotta check it. 
static func _did_succeed(story: String) -> bool:
	return not story.contains("NOT SUCCESSFUL")
