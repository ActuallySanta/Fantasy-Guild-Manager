## One hero in a Training Yard or Hospital card (Upgrades > Tonight, see
## home_section.gd). The card picks one of the show_* functions; each fills
## the same row differently:
##   training slot  - stat picker (Str / Def / Wis / Slz) and Remove
##   can train      - Add (or "Move here" if they're in a quest's party)
##   can't train    - faded, with the reason
##   patient        - recovery bar and Discharge
##   needs care     - nights at home vs in a bed, and Admit
##   fallen         - Revive at Hospital level 5
## Scene: MobileHall/Scenes/Rows/home_row.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

## Rows for heroes who can't do anything here fade back.
const FADED_OPACITY := 0.6
## Card colours for heroes in a slot / bed.
const TRAINING_CARD_BG := Color("#E8F5E9")
const HOSPITAL_CARD_BG := Color("#FBE7CF")
const HOSPITAL_BORDER := Color("#E09A4F")

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_GAIN := "%s %d → %d tonight"
const TEXT_FREE := "Free today"
const TEXT_PICKED_FOR := "Picked for #%d"
const TEXT_SENT_ON := "Sent on #%d"
const TEXT_TOO_HURT := "Too hurt to train"
const TEXT_IN_BED := "In a Hospital bed"
const TEXT_NIGHTS_IN_BED := "Healthy in %s"
const TEXT_NIGHTS_COMPARE := "Healthy in %s at home, %s in a bed"
const TEXT_REVIVE_READY := "The Hospital can bring one hero back"
const TEXT_REVIVE_LOCKED := "Revive unlocks at Hospital level %d"
const TEXT_REVIVE_USED := "This run's revive is used up"
const BUTTON_REMOVE := "Remove"
const BUTTON_ADD := "Add"
const BUTTON_MOVE := "Move here"
const BUTTON_FULL := "Full"
const BUTTON_DISCHARGE := "Discharge"
const BUTTON_ADMIT := "Admit"
const BUTTON_PULL_ADMIT := "Pull & admit"
const BUTTON_REVIVE := "Revive"

# ---- NODES
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _health_chip = %HealthChip       # chip.gd
@onready var _task_chip = %TaskChip           # chip.gd
@onready var _note: Label = %Note
@onready var _side_button: Button = %SideButton
@onready var _main_button: Button = %MainButton
@onready var _stat_picker: HBoxContainer = %StatPicker

var hall: HallMain
var character: GuildCharacter


func _fill(main: HallMain, hero: GuildCharacter) -> void:
	hall = main
	character = hero
	_portrait.show_character(character)
	_name.text = character.name
	_role.text = TEXT_ROLE % Style.role_name(character)
	_health_chip.set_health(character)
	_show_task_chip()
	_note.visible = false
	_side_button.visible = false
	_main_button.visible = false
	_stat_picker.visible = false
	modulate = Color.WHITE
	Style.style_panel(self, Style.CARD_BG, Style.BORDER, 2, 16)


## "Free today", "Picked for #2" or "Sent on #2".
func _show_task_chip() -> void:
	var quest_index := hall.quest_index_of(character)
	if quest_index < 0:
		_task_chip.set_chip(TEXT_FREE, Style.NEUTRAL_BG, Style.TEXT_SOFT)
	elif hall.quest_entries[quest_index].state == Style.QUEST_STATE_SENT:
		_task_chip.set_chip(TEXT_SENT_ON % (quest_index + 1), Style.GREEN_BG, Style.GREEN_TEXT, "check")
	else:
		_task_chip.set_chip(TEXT_PICKED_FOR % (quest_index + 1), Style.BLUE_BG, Style.BLUE_TEXT, "nav_quests")


func _set_note(text: String, color: Color = Style.TEXT_SOFT) -> void:
	_note.text = text
	_note.visible = true
	Style.set_font_color(_note, color)


func _set_button(button: Button, text: String, kind: String, action: Callable) -> void:
	button.text = text
	button.visible = true
	button.disabled = false
	Style.style_button(button, kind, 22)
	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection.callable)
	button.pressed.connect(action)


func _nights_text(nights: int) -> String:
	return Style.count_text(nights, "night", "nights")

# ---- Training Yard


func show_training_slot(main: HallMain, hero: GuildCharacter) -> void:
	_fill(main, hero)
	var stat := GuildUpgrades.get_training_stat(character)
	var value := Style.stat_value(character, stat)
	_set_note(TEXT_GAIN % [Style.STATS[stat].short, value, value + GuildUpgrades.get_training_gain()], Style.GREEN_TEXT)
	_task_chip.visible = false
	_set_button(_side_button, BUTTON_REMOVE, "paper", hall.stop_training.bind(character))
	Style.style_panel(self, TRAINING_CARD_BG, Style.GREEN, 3, 16)
	_show_stat_picker(stat)


## One paper button per quest stat in that stat's ink; the one being drilled
## has its paper tinted with the stat's colour and a check mark.
func _show_stat_picker(selected_stat: int) -> void:
	_stat_picker.visible = true
	var buttons := _stat_picker.get_children()
	for stat_index in buttons.size():
		var button: Button = buttons[stat_index]
		var stat: Dictionary = Style.STATS[stat_index]
		var is_selected := stat_index == selected_stat
		button.text = stat.short
		Style.style_button(button, "paper")
		Style.tint_art(button, stat.bg if is_selected else Style.WHITE)
		button.icon = Style.icon_texture("check") if is_selected else null
		for font_state in Style.BUTTON_FONT_STATES:
			button.add_theme_color_override(font_state, stat.color)
		button.add_theme_color_override("icon_normal_color", stat.color)
		button.add_theme_color_override("icon_pressed_color", stat.color)
		for connection in button.pressed.get_connections():
			button.pressed.disconnect(connection.callable)
		button.pressed.connect(hall.train.bind(character, stat_index))


func show_can_train(main: HallMain, hero: GuildCharacter) -> void:
	_fill(main, hero)
	# new trainees drill their best quest stat until the player picks another
	var best_stat := 0
	for stat_index in Style.QUEST_STAT_COUNT:
		if Style.stat_value(character, stat_index) > Style.stat_value(character, best_stat):
			best_stat = stat_index
	if not GuildUpgrades.has_free_training_slot():
		_set_button(_main_button, BUTTON_FULL, "paper", func(): pass)
		_main_button.disabled = true
	elif hall.quest_index_of(character) >= 0:
		_set_button(_main_button, BUTTON_MOVE, "paper", hall.train.bind(character, best_stat))
	else:
		_set_button(_main_button, BUTTON_ADD, "blue", hall.train.bind(character, best_stat))


func show_cant_train(main: HallMain, hero: GuildCharacter) -> void:
	_fill(main, hero)
	_task_chip.visible = false
	_set_note(TEXT_IN_BED if GuildUpgrades.is_patient(character) else TEXT_TOO_HURT)
	Style.style_panel(self, Style.DENIED_CARD_BG, Style.BORDER, 2, 16)
	modulate = Color(1, 1, 1, FADED_OPACITY)

# ---- Hospital


func show_patient(main: HallMain, hero: GuildCharacter) -> void:
	_fill(main, hero)
	_task_chip.visible = false
	var nights := GuildUpgrades.get_nights_until_healthy(character, true)
	_set_note(TEXT_NIGHTS_IN_BED % _nights_text(nights), Style.INJURY_LOOKS[2].text)
	_set_button(_main_button, BUTTON_DISCHARGE, "paper", hall.discharge.bind(character))
	Style.style_panel(self, HOSPITAL_CARD_BG, HOSPITAL_BORDER, 3, 16)


func show_needs_care(main: HallMain, hero: GuildCharacter) -> void:
	_fill(main, hero)
	var at_home := GuildUpgrades.get_nights_until_healthy(character, false)
	var in_bed := GuildUpgrades.get_nights_until_healthy(character, true)
	_set_note(TEXT_NIGHTS_COMPARE % [_nights_text(at_home), _nights_text(in_bed)])
	var is_busy := hall.quest_index_of(character) >= 0 or GuildUpgrades.is_training(character)
	_set_button(_main_button, BUTTON_PULL_ADMIT if is_busy else BUTTON_ADMIT, "paper" if is_busy else "blue", hall.admit.bind(character))


func show_fallen(main: HallMain, hero: GuildCharacter) -> void:
	_fill(main, hero)
	_task_chip.visible = false
	if GuildUpgrades.can_revive():
		_set_note(TEXT_REVIVE_READY, Style.GREEN_TEXT)
		_set_button(_main_button, BUTTON_REVIVE, "green", hall.revive.bind(character))
	else:
		var is_used := GuildUpgrades.get_level(GuildUpgrades.Building.HOSPITAL) >= GuildUpgrades.REVIVE_LEVEL
		_set_note(TEXT_REVIVE_USED if is_used else TEXT_REVIVE_LOCKED % GuildUpgrades.REVIVE_LEVEL)
		Style.style_panel(self, Style.DENIED_CARD_BG, Style.BORDER, 2, 16)
		modulate = Color(1, 1, 1, FADED_OPACITY)
