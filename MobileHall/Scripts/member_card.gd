## One adventurer in the Guild tab's roster (a parchment card): portrait,
## health, what they're doing today, and all five stats. Tap for details.
## Scene: MobileHall/Scenes/Rows/member_card.tscn
extends TapPanel


# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_FREE := "Free today"
const TEXT_PICKED_FOR := "Picked for #%d"
const TEXT_SENT_ON := "Sent on #%d"
const TEXT_TRAINING := "Training %s"
const TEXT_IN_BED := "In a Hospital bed"
const TEXT_DIED_ON := "Died on Day %d"

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
	_role.text = TEXT_ROLE % HallStyle.role_name(character)
	_health_chip.set_health(character)
	_stats.show_stats(character)
	_show_task(hall, character)


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
	elif quest_index < 0 and GuildUpgrades.is_training(character):
		var stat: Dictionary = HallStyle.STATS[GuildUpgrades.get_training_stat(character)]
		_task_chip.set_chip(TEXT_TRAINING % stat.short, stat.bg, stat.color, "", true)
	elif quest_index < 0:
		_task_chip.set_chip(TEXT_FREE, HallStyle.NEUTRAL_BG, HallStyle.TEXT_SOFT)
	elif hall.quest_entries[quest_index].state == HallStyle.QUEST_STATE_SENT:
		_task_chip.set_chip(TEXT_SENT_ON % (quest_index + 1), HallStyle.GREEN_BG, HallStyle.GREEN_TEXT, "check")
	else:
		_task_chip.set_chip(TEXT_PICKED_FOR % (quest_index + 1), HallStyle.BLUE_BG, HallStyle.BLUE_TEXT, "nav_quests")
