## Board tab: the home screen. Three pinned "Today" notes (recruits,
## quests decided, upgrades), then every quest of the day as a scroll in one
## list so they can be compared at a glance. Tap a quest to pick its party.
## Scene: MobileHall/Scenes/Tabs/tab_board.tscn
extends ScrollContainer

const QuestRowScene := preload("uid://dxhtjf067jytf")  # MobileHall/Scenes/Rows/quest_row.tscn

# ---- TEXT
# Today note titles
const TODAY_RECRUITS := "Recruits"
const TODAY_QUESTS := "Decided"
const TODAY_UPGRADES := "Upgrades"
# Today note values
const RECRUITS_NEW := "%d new"
const RECRUITS_FULL := "beds full"
const RECRUITS_IN_GUILD := "%d / %d hired"
const QUESTS_DECIDED := "%d / %d"
const UPGRADES_READY := "%d ready"
const UPGRADES_NONE := "none yet"
## While Pip still holds the Guild tab back (HallMain.is_tab_locked).
const UPGRADES_LOCKED := "opens Day %d"
# Quest list
const HEADING := "Today's Quests"
const HEADING_MILESTONE := "The Bone Drake"
const HEADING_FINAL := "The Final Battle"

# ---- NODES
@onready var _today_recruits = %TodayRecruits     # today_item.gd
@onready var _today_quests = %TodayQuests         # today_item.gd
@onready var _today_upgrades = %TodayUpgrades     # today_item.gd
@onready var _heading: Label = %Heading
@onready var _quest_list: VBoxContainer = %QuestList

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_today_recruits.pressed.connect(func(): hall.open_tab("guild", HallMain.GUILD_SECTION_HIRE))
	_today_quests.pressed.connect(_on_today_quests_pressed)
	_today_upgrades.pressed.connect(func(): hall.open_tab("upgrades", HallMain.UPGRADES_SECTION_BUILD))


func scroll_to_top() -> void:
	scroll_vertical = 0


func refresh() -> void:
	_show_today_checklist()
	_show_quest_list()


# ---- Today checklist

## Each note is "todo" (dark ink) when it wants a visit, "done" (green) or "idle" (faded).
func _show_today_checklist() -> void:
	_show_recruits_box()
	_show_quests_box()
	_show_upgrades_box()


func _show_recruits_box() -> void:
	var roster_size: int = CharacterContainer.living_count()
	if hall.is_roster_full():
		_today_recruits.set_item(TODAY_RECRUITS, RECRUITS_FULL, "nav_characters", "idle")
	elif hall.unseen_recruit_count() > 0 or roster_size == 0:
		var recruit_count := CharacterContainer.hireable_characters.size()
		_today_recruits.set_item(TODAY_RECRUITS, RECRUITS_NEW % recruit_count, "nav_characters", "todo")
	else:
		var value := RECRUITS_IN_GUILD % [roster_size, CharacterContainer.max_characters]
		_today_recruits.set_item(TODAY_RECRUITS, value, "nav_characters", "idle")


func _show_quests_box() -> void:
	var value := QUESTS_DECIDED % [hall.decided_count(), hall.quest_entries.size()]
	var look := "done" if hall.undecided_count() == 0 else "todo"
	_today_quests.set_item(TODAY_QUESTS, value, "nav_quests", look)


func _show_upgrades_box() -> void:
	if hall.is_tab_locked("upgrades"):
		_today_upgrades.set_item(TODAY_UPGRADES, UPGRADES_LOCKED % hall.tab_unlock_day("upgrades"), "nav_upgrades", "idle")
		return
	var affordable_count := hall.affordable_buildings().size()
	var value := UPGRADES_READY % affordable_count if affordable_count > 0 else UPGRADES_NONE
	var look := "todo" if affordable_count > 0 else "idle"
	_today_upgrades.set_item(TODAY_UPGRADES, value, "nav_upgrades", look)


## The Decided note jumps to the next undecided quest (does nothing once all are decided).
func _on_today_quests_pressed() -> void:
	if hall.undecided_count() > 0:
		hall.do_next_step()


# ---- quest list

func _show_quest_list() -> void:
	var is_milestone_day: bool = not hall.quest_entries.is_empty() and hall.quest_entries[0].milestone
	var is_final_day: bool = not hall.quest_entries.is_empty() and hall.quest_entries[0].get("final", false)
	if is_final_day:
		_heading.text = HEADING_FINAL
	else:
		_heading.text = HEADING_MILESTONE if is_milestone_day else HEADING
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
