## One adventurer in the Guild tab's roster (a parchment card): portrait,
## what they're doing today, and health with their two strongest stats.
## Tap for details (the character page shows every stat). On the right: their
## status (on a quest, idle, training, in hospital, fallen), then a caret
## pointing down to say there's more.
## Scene: Scenes/Rows/Heroes/member_card.tscn
extends TapPanel


## SIMPLIFIED: the "Sent on #2" / "Picked for #2" chip for heroes in a quest's party.
const SHOW_QUEST_TASK := false
## SIMPLIFIED: the "Free today" chip (no chip already means free).
const SHOW_FREE_TASK := false
## The "Training Pow" / "In a Hospital bed" chips. Off: the status on the
## right of the card says the same thing.
const SHOW_FACILITY_TASK := false

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_FREE := "Free today"
const TEXT_PICKED_FOR := "Picked for #%d"
const TEXT_SENT_ON := "Sent on #%d"
const TEXT_TRAINING := "Training %s"
const TEXT_IN_BED := "In a Hospital bed"
const TEXT_DIED_ON := "Died on Day %d"
# Status (right of the card, before the caret). Two short lines where it has
# a detail, so the column stays narrow and the stat chips keep one line.
const STATUS_ON_QUEST := "On quest\n#%d"
const STATUS_IDLE := "Idle"
const STATUS_TRAINING := "Training\n%s"
const STATUS_IN_HOSPITAL := "In\nhospital"
const STATUS_FALLEN := "Fallen"

## How many stats a roster card shows (the strongest ones).
const SHOWN_STAT_COUNT := 2

# ---- NODES
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _task_chip = %TaskChip           # chip.gd
@onready var _stats = %Stats                  # stat_strip.gd
@onready var _chevron: Label = %Chevron
@onready var _status: Label = %Status


func _ready() -> void:
	# the caret points down, like the report letters' "tap to read" caret
	HallStyle.turn_caret(_chevron, HallStyle.CARET_DOWN)


func setup(hall: HallMain, character: GuildCharacter) -> void:
	pressed.connect(hall.open_character.bind(character))
	_chevron.visible = not hall.is_locked(OverlayTutorial.FEATURE_HERO_PAGE)
	_portrait.show_character(character)
	_name.text = character.name
	_role.text = TEXT_ROLE % HallStyle.role_name(character)
	_stats.show_health(character)
	_stats.show_stats(character, [] as Array[int], false, SHOWN_STAT_COUNT)
	_show_task(hall, character)
	_show_status(hall, character)


## The status on the right: on a quest (green, with its number), idle (soft
## ink), training a stat (that stat's ink), in a Hospital bed (orange), or
## fallen (the Dead ink). A hero in a quest's party is always sent (pinning
## sends a quest), so there's no separate "picked" status.
func _show_status(hall: HallMain, character: GuildCharacter) -> void:
	var quest_index := hall.quest_index_of(character)
	var text := STATUS_IDLE
	var ink := HallStyle.TEXT_SOFT
	if HallStyle.is_dead(character):
		text = STATUS_FALLEN
		ink = HallStyle.INJURY_LOOKS[GuildCharacter.InjuryLevel.DEAD].text
	elif quest_index >= 0:
		text = STATUS_ON_QUEST % (quest_index + 1)
		ink = HallStyle.GREEN_TEXT
	elif GuildUpgrades.is_patient(character):
		text = STATUS_IN_HOSPITAL
		ink = HallStyle.INJURY_LOOKS[2].text
	elif GuildUpgrades.is_training(character):
		var stat: Dictionary = HallStyle.STATS[GuildUpgrades.get_training_stat(character)]
		text = STATUS_TRAINING % stat.short
		ink = stat.color
	_status.text = text
	HallStyle.set_font_color(_status, ink)


## Today's task in ink: free, picked for a quest (blue), sent on one (green),
## training a stat (that stat's ink, in a pill), in a Hospital bed (orange), or
## the day they died (hidden if that wasn't recorded; the Dead chip says enough).
func _show_task(hall: HallMain, character: GuildCharacter) -> void:
	var quest_index := hall.quest_index_of(character)
	if HallStyle.is_dead(character):
		var dead_look: Dictionary = HallStyle.INJURY_LOOKS[GuildCharacter.InjuryLevel.DEAD]
		_task_chip.set_chip(TEXT_DIED_ON % character.died_on_day, dead_look.bg, dead_look.text, "skull", true)
		_task_chip.visible = character.died_on_day >= 0
	elif quest_index < 0 and GuildUpgrades.is_patient(character):
		var bed_look: Dictionary = HallStyle.INJURY_LOOKS[2]
		_task_chip.set_chip(TEXT_IN_BED, bed_look.bg, bed_look.text, "bed")
		_task_chip.visible = SHOW_FACILITY_TASK
	elif quest_index < 0 and GuildUpgrades.is_training(character):
		var stat: Dictionary = HallStyle.STATS[GuildUpgrades.get_training_stat(character)]
		_task_chip.set_chip(TEXT_TRAINING % stat.short, stat.bg, stat.color, "", true)
		_task_chip.visible = SHOW_FACILITY_TASK
	elif quest_index < 0:
		_task_chip.set_chip(TEXT_FREE, HallStyle.NEUTRAL_BG, HallStyle.TEXT_SOFT)
		_task_chip.visible = SHOW_FREE_TASK
	elif hall.quest_entries[quest_index].state == HallStyle.QUEST_STATE_SENT:
		_task_chip.set_chip(TEXT_SENT_ON % (quest_index + 1), HallStyle.GREEN_BG, HallStyle.GREEN_TEXT, "check")
		_task_chip.visible = SHOW_QUEST_TASK
	else:
		_task_chip.set_chip(TEXT_PICKED_FOR % (quest_index + 1), HallStyle.BLUE_BG, HallStyle.BLUE_TEXT, "nav_quests")
		_task_chip.visible = SHOW_QUEST_TASK
