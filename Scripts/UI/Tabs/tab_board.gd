## Board tab: the home screen. Every quest of the day as a scroll in one
## list so they can be compared at a glance. Tap a quest to pick its party.
## Under the list, the End Day button (the only way to end the day): it opens
## the End Day check, or the next undecided quest if any are left
## (hall.open_end_check).
## Scene: Scenes/Tabs/tab_board.tscn
extends ScrollContainer

const QuestRowScene := preload("uid://dxhtjf067jytf")  # Scenes/Rows/Quests/quest_row.tscn

# ---- TEXT
# End Day
const BUTTON_END_DAY := "End Day %d"

# ---- NODES
@onready var _quest_list: VBoxContainer = %QuestList
@onready var _end_day_button: Button = %EndDayButton

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_end_day_button.pressed.connect(hall.open_end_check)


func scroll_to_top() -> void:
	scroll_vertical = 0


## The End Day button, for Pip to point at (hall.end_day_button).
func end_day_button() -> Button:
	return _end_day_button


func refresh() -> void:
	_show_quest_list()
	_end_day_button.text = BUTTON_END_DAY % GameState.day


# ---- quest list

func _show_quest_list() -> void:
	HallStyle.clear_children(_quest_list)
	for quest_index in _board_order():
		HallStyle.add_row(_quest_list, QuestRowScene).setup(hall, quest_index)


## Indexes into hall.quest_entries in the order the Board lists them: story
## quests (HallStyle.is_story_quest) first, then the rest, each in day order.
func _board_order() -> Array:
	var story_indexes := []
	var other_indexes := []
	for quest_index in hall.quest_entries.size():
		if HallStyle.is_story_quest(hall.quest_entries[quest_index]):
			story_indexes.append(quest_index)
		else:
			other_indexes.append(quest_index)
	return story_indexes + other_indexes
