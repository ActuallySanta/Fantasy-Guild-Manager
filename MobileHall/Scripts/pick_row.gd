## One adventurer in Assign Party's picker: portrait, health, the four quest
## stats (favored one outlined), how much they'd add to the odds, and which
## quest they're already on. Tap to add / remove; "i" opens their details.
## Scene: MobileHall/Scenes/Rows/pick_row.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

## Adventurers who can't go fade back.
const CANT_GO_OPACITY := 0.6

# ---- TEXT
# Who they are
const TEXT_ROLE := "the %s"
# Where they already are
const TEXT_PICKED_FOR := "Picked for %s"
const TEXT_SENT_ON := "Sent on %s"
const TEXT_QUEST_NAME := "#%d %s"
const TEXT_TRAINING := "Training %s"
# Right-hand box
const TEXT_ADDS := "+%d%%"
const TEXT_ADDS_SUB := "to odds"
const TEXT_IN_PARTY := "Added"
const TEXT_IN_PARTY_SUB := "in party"
const TEXT_CANT_GO := "-"
const TEXT_CANT_GO_SUB := "Can't go"
const TEXT_IN_BED_SUB := "In a bed"
const TEXT_TRAINING_SUB := "Training"

# ---- NODES
# Who they are
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _health_chip = %HealthChip       # chip.gd
@onready var _stats = %Stats                  # stat_strip.gd
@onready var _info_button: Button = %InfoButton
# Where they already are
@onready var _elsewhere_label: Label = %Where
# Right-hand box
@onready var _adds_value: Label = %AddValue
@onready var _adds_sub: Label = %AddSub


func setup(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> void:
	pressed.connect(hall.toggle_in_party.bind(character))
	_info_button.pressed.connect(hall.open_character.bind(character))
	_portrait.show_character(character)
	_name.text = character.name
	_role.text = TEXT_ROLE % Style.role_name(character)
	_health_chip.set_health(character)
	_stats.show_stats(character, Style.favored_stat_index(entry.quest), false)
	_show_elsewhere(hall, entry, character)
	_show_pick_state(hall, entry, character)


## "Picked for #2 Escort..." when they're in another quest's party.
func _show_elsewhere(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> void:
	var other_index := hall.quest_index_of(character)
	var other_entry: Dictionary = hall.quest_entries[other_index] if other_index >= 0 else {}
	if other_index < 0 and GuildUpgrades.is_training(character):
		_elsewhere_label.visible = true
		_elsewhere_label.text = TEXT_TRAINING % Style.STATS[GuildUpgrades.get_training_stat(character)].name
		Style.set_font_color(_elsewhere_label, Style.BLUE_TEXT)
		return
	_elsewhere_label.visible = other_index >= 0 and other_entry != entry
	if not _elsewhere_label.visible:
		return
	var is_sent: bool = other_entry.state == Style.QUEST_STATE_SENT
	var quest_name := TEXT_QUEST_NAME % [other_index + 1, other_entry.quest.questTitle]
	_elsewhere_label.text = (TEXT_SENT_ON if is_sent else TEXT_PICKED_FOR) % quest_name
	Style.set_font_color(_elsewhere_label, Style.GREEN_TEXT if is_sent else Style.BLUE_TEXT)


## Right-hand box and row colours: in this party (green), can't go (faded),
## or how much they'd add to the odds.
func _show_pick_state(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> void:
	if entry.party.has(character):
		_adds_value.text = TEXT_IN_PARTY
		_adds_sub.text = TEXT_IN_PARTY_SUB
		Style.set_font_color(_adds_value, Style.GREEN_TEXT)
		Style.style_panel(self, Style.SENT_CARD_BG, Style.GREEN, 4, 16)
	elif not hall.can_go_on_quests(character):
		_adds_value.text = TEXT_CANT_GO
		if Style.is_dead(character):
			_adds_sub.text = TEXT_CANT_GO_SUB
		elif GuildUpgrades.is_patient(character):
			_adds_sub.text = TEXT_IN_BED_SUB
		else:
			_adds_sub.text = TEXT_TRAINING_SUB
		Style.set_font_color(_adds_value, Style.TEXT_SOFT)
		Style.style_panel(self, Style.DENIED_CARD_BG, Style.BORDER, 2, 16)
		modulate = Color(1, 1, 1, CANT_GO_OPACITY)
	else:
		var chance_added := hall.chance_added_by(entry, character)
		_adds_value.text = TEXT_ADDS % mini(chance_added, 100)
		_adds_sub.text = TEXT_ADDS_SUB
		Style.set_font_color(_adds_value, Style.odds_look(chance_added).text_color)
		Style.style_panel(self, Style.CARD_BG, Style.BORDER, 2, 16)
