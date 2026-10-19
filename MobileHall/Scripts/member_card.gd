## One adventurer in the Guild tab's roster: portrait, health, what they're
## doing today, and all five stats. Tap for details.
## Scene: MobileHall/Scenes/Rows/member_card.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_FREE := "Free today"
const TEXT_PICKED_FOR := "Picked for #%d"
const TEXT_SENT_ON := "Sent on #%d"

# ---- NODES
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _health_chip = %HealthChip       # chip.gd
@onready var _task_chip = %TaskChip           # chip.gd
@onready var _stats = %Stats                  # stat_strip.gd


func setup(hall: HallMain, character: GuildCharacter) -> void:
	pressed.connect(hall.open_character.bind(character))
	_portrait.show_character(character)
	_name.text = character.name
	_role.text = TEXT_ROLE % Style.role_name(character)
	_health_chip.set_health(character)
	_stats.show_stats(character)
	_show_task(hall, character)
	Style.style_panel(self, Style.CARD_BG, Style.BORDER, 2, 16)


## Today's task chip: free, picked for a quest (blue) or sent on one (green).
func _show_task(hall: HallMain, character: GuildCharacter) -> void:
	var quest_index := hall.quest_index_of(character)
	if quest_index < 0:
		_task_chip.set_chip(TEXT_FREE, Style.NEUTRAL_BG, Style.TEXT_SOFT)
	elif hall.quest_entries[quest_index].state == Style.QUEST_STATE_SENT:
		_task_chip.set_chip(TEXT_SENT_ON % (quest_index + 1), Style.GREEN_BG, Style.GREEN_TEXT, "check")
	else:
		_task_chip.set_chip(TEXT_PICKED_FOR % (quest_index + 1), Style.BLUE_BG, Style.BLUE_TEXT, "nav_quests")
