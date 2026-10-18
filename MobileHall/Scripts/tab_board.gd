## Board tab: the home screen. A three-box "Today" checklist (recruits,
## quests, upgrades), then every quest of the day in one list so they can be
## compared at a glance. Tap a quest to pick its party.
## Scene: MobileHall/Scenes/Tabs/tab_board.tscn
extends ScrollContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const QuestRow := preload("res://MobileHall/Scenes/Rows/quest_row.tscn")

# ---- TEXT
const TODAY_RECRUITS := "Recruits"
const TODAY_QUESTS := "Quests"
const TODAY_UPGRADES := "Upgrades"
const RECRUITS_NEW := "%d new"
const RECRUITS_FULL := "Beds full"
const RECRUITS_SEEN := "%d / %d in guild"
const QUESTS_DONE := "%d / %d decided"
const UPGRADES_READY := "%d ready"
const UPGRADES_NONE := "None ready"
const HEADING := "Today's Quests"
const HEADING_MILESTONE := "The Bone Drake"
const HINT := "Tap a quest to pick its party. Picks are kept until you send them."
const HINT_DONE := "Every quest is decided. Tap one to change your mind."

# ---- NODES
@onready var _today_recruits = %TodayRecruits
@onready var _today_quests = %TodayQuests
@onready var _today_upgrades = %TodayUpgrades
@onready var _heading: Label = %Heading
@onready var _hint: Label = %Hint
@onready var _list: VBoxContainer = %QuestList

var ui


func setup(main) -> void:
	ui = main
	_today_recruits.pressed.connect(func(): ui.open_tab("guild", "hire"))
	_today_quests.pressed.connect(func(): ui.primary_action() if ui.outstanding() > 0 else null)
	_today_upgrades.pressed.connect(func(): ui.open_tab("upgrades"))


func scroll_to_top() -> void:
	scroll_vertical = 0


func refresh() -> void:
	_show_today()
	_show_quests()


func _show_today() -> void:
	var new: int = ui.new_recruits()
	if ui.roster_full():
		_today_recruits.set_item(TODAY_RECRUITS, RECRUITS_FULL, "nav_characters", "idle")
	elif new > 0 or ui.roster().is_empty():
		_today_recruits.set_item(TODAY_RECRUITS, RECRUITS_NEW % CharacterContainer.hireable_characters.size(), "nav_characters", "todo")
	else:
		_today_recruits.set_item(TODAY_RECRUITS, RECRUITS_SEEN % [ui.roster().size(), CharacterContainer.max_characters], "nav_characters", "idle")

	var total: int = ui.entries.size()
	_today_quests.set_item(TODAY_QUESTS, QUESTS_DONE % [ui.decided(), total], "nav_quests", "done" if ui.outstanding() == 0 else "todo")

	var ups: int = ui.upgradable().size()
	_today_upgrades.set_item(TODAY_UPGRADES, UPGRADES_READY % ups if ups > 0 else UPGRADES_NONE, "nav_upgrades", "todo" if ups > 0 else "idle")


func _show_quests() -> void:
	var milestone: bool = not ui.entries.is_empty() and ui.entries[0].milestone
	_heading.text = HEADING_MILESTONE if milestone else HEADING
	_hint.text = HINT_DONE if ui.outstanding() == 0 else HINT
	S.clear(_list)
	for i in ui.entries.size():
		S.add_row(_list, QuestRow).setup(ui, i)
