## One adventurer in the Guild tab's roster (a parchment card): portrait, health, what they're
## doing today, and all five stats. Tap for details.
## Scene: MobileHall/Scenes/Rows/member_card.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_FREE := "Free today"
const TEXT_DRAFT := "Picked for #%d"
const TEXT_SENT := "Sent on #%d"

# ---- NODES
@onready var _portrait = %Portrait
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _health = %HealthChip
@onready var _task = %TaskChip
@onready var _stats = %Stats


func setup(main, c: GuildCharacter) -> void:
	pressed.connect(main.open_character.bind(c))
	_portrait.show_character(c)
	_name.text = c.name
	_role.text = TEXT_ROLE % S.role_name(c)
	_health.set_health(c)
	_stats.show_stats(c)
	var i: int = main.entry_index_of(c)
	if i < 0:
		_task.set_chip(TEXT_FREE, S.INK_SOFT)
	elif main.entries[i].state == "ready":
		_task.set_chip(TEXT_SENT % (i + 1), S.GREEN_TEXT, "check")
	else:
		_task.set_chip(TEXT_DRAFT % (i + 1), S.BLUE_TEXT, "scroll")
