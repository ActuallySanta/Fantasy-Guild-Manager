# Script for the end day button, when pressed, it finds every quest
# that's ready to go out runs the quest system's generateResults() 
# on each, and shows the Day Summary.
class_name DayBar
extends PanelContainer
 
@export var quest_list: QuestList
@export var day_summary: DaySummary

static func _get_success_chance(quest: CreatedQuest, party: Array[GuildCharacter]) -> float:
	return quest.calcSuccessChance(party)

@onready var _end_day_button: Button = %EndDayButton

# true after end day is pressed
var _day_ended := false

func _ready() -> void:
	_end_day_button.pressed.connect(end_day)
	
	if quest_list:
		# check button everytime quest board changes
		quest_list.board_changed.connect(_update_end_day_button)
	
	_update_end_day_button()
	GameState.day_started.connect(_on_day_started)

# make sure end day can be used again once the new quests are added
func _on_day_started(_day: int) -> void:
	_day_ended = false
	_update_end_day_button()

# Locks or unlocks end day button based on quests
func _update_end_day_button() -> void:
	if quest_list == null:
		return
	
	var outstanding := quest_list.get_outstanding_count()
	_end_day_button.disabled = _day_ended or outstanding > 0
 
func end_day() -> void:
	if quest_list == null or day_summary == null:
		push_error("drag ContentList into Quest List and DaySummary into Day Summary in the Inspector")
		return
	
	# check in case end_day() is ever called from code.
	if quest_list.get_outstanding_count() > 0:
		return
	
	# Each result is a Dictionary the summary screen shows
	var results := []
 
	for card: QuestCard in quest_list.get_dispatched_cards():
		var party := card.get_party()
 
		# generateResults() wants typed Array[GuildCharacter]
		# so copy the plain party Array into one.
		# without this every quest would fail
		var typed_party: Array[GuildCharacter] = []
		typed_party.assign(party)
		
		var chance := _get_success_chance(card.quest, typed_party)
		var story: String = card.quest.generateResults(typed_party, chance)
		
		var succeeded := _did_succeed(story)
		var gold_earned := _get_gold_earned(card.quest, succeeded)
		GameState.add_gold(gold_earned)
		# equipment found while searching is kept even if the quest failed
		ItemContainer.owned_items.append_array(card.quest.found_items)
		# an item quest's reward replaces its gold, so it's only paid on a success
		if succeeded and card.quest.pays_in_items():
			ItemContainer.owned_items.append_array(card.quest.reward_items)

		results.append({
			"quest": card.quest,
			"party": party,
			"story": story,
			"succeeded": _did_succeed(story),
			"chance": chance,
			"gold": gold_earned,
		})
	
	# end day
	_day_ended = true
	_update_end_day_button()
	
	get_tree().call_group("roster", "close")
	day_summary.show_results(results)
 
 
# The quest system currently only reports success inside the story
# text so we gotta check it. 
static func _did_succeed(story: String) -> bool:
	return not story.contains("NOT SUCCESSFUL")

# How much gold the guild actually gets
# (item quests start at 0 gold, so this is only the bonus gold found on the way)
static func _get_gold_earned(quest: CreatedQuest, succeeded: bool) -> int:
	if succeeded:
		return quest.goldReward
	return quest.goldReward - quest.startingGoldReward
	#return maxi(quest.goldReward - 200, 0)
