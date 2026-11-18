## One adventurer in Assign Party's picker: portrait, health and the four quest
## stats on one line (favored stat with a heavy border), how much they'd add to the odds, and which
## quest (or training) they're already on. Tap to pin / unpin; "i" opens
## their details.
## Scene: Scenes/Rows/Quests/pick_row.tscn
extends TapPanel


## Adventurers who can't go fade back.
const CANT_GO_OPACITY := 0.6
## Adventurers already in another quest's party are greyed out this much
## (0 = invisible, 1 = normal).
const BUSY_OPACITY := 0.6
## SIMPLIFIED: the "to odds" caption under the "+12%" each adventurer adds.
const SHOW_ADDS_CAPTION := false

# ---- TEXT
# Who they are
const TEXT_ROLE := "the %s"
# Where they already are
const TEXT_PICKED_FOR := "Picked for %s"
const TEXT_SENT_ON := "Sent on %s"
const TEXT_QUEST_NAME := "#%d %s"
const TEXT_TRAINING := "Training %s"
# Right-hand column
const TEXT_ADDS := "+%d%%"
const TEXT_ADDS_SUB := "to odds"
const TEXT_IN_PARTY := "Assigned"
const TEXT_CANT_GO := "-"
const TEXT_CANT_GO_SUB := "can't go"
const TEXT_IN_BED_SUB := "in a bed"
const TEXT_TRAINING_SUB := "training"

# ---- NODES
# Who they are
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _stats = %Stats                  # stat_strip.gd
@onready var _info_button: Button = %InfoButton
# Where they already are
@onready var _elsewhere_label: Label = %Where
# Right-hand column
@onready var _adds_value: Label = %AddValue
@onready var _adds_sub: Label = %AddSub


## hall: the main hall script; entry: the quest being assigned; character: who
## this row shows. ask_to_move: called with `character` instead of pinning
## them when they're in another quest's party (Assign Party's move popup);
## left empty, the tap moves them straight away.
func setup(hall: HallMain, entry: Dictionary, character: GuildCharacter,
		ask_to_move: Callable = Callable()) -> void:
	if _is_busy_elsewhere(hall, entry, character) and ask_to_move.is_valid():
		pressed.connect(ask_to_move.bind(character))
	else:
		pressed.connect(hall.toggle_in_party.bind(character))
	_info_button.pressed.connect(hall.open_character.bind(character))
	_portrait.show_character(character)
	_name.text = character.name
	_role.text = TEXT_ROLE % HallStyle.role_name(character)
	_stats.show_health(character)
	_stats.show_stats(character, HallStyle.favored_stat_index(entry.quest), false)
	_show_elsewhere(hall, entry, character)
	_show_pick_state(hall, entry, character)


## "Picked for #2 Escort..." when they're in another quest's party,
## "Training Power" when they're in the Training Yard.
func _show_elsewhere(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> void:
	var other_index := hall.quest_index_of(character)
	var other_entry: Dictionary = hall.quest_entries[other_index] if other_index >= 0 else {}
	if other_index < 0 and GuildUpgrades.is_training(character):
		_elsewhere_label.visible = true
		_elsewhere_label.text = TEXT_TRAINING % HallStyle.STATS[GuildUpgrades.get_training_stat(character)].name
		HallStyle.set_font_color(_elsewhere_label, HallStyle.BLUE_TEXT)
		return
	_elsewhere_label.visible = other_index >= 0 and other_entry != entry
	if not _elsewhere_label.visible:
		return
	var is_sent: bool = other_entry.state == HallStyle.QUEST_STATE_SENT
	var quest_name := TEXT_QUEST_NAME % [other_index + 1, other_entry.quest.questTitle]
	_elsewhere_label.text = (TEXT_SENT_ON if is_sent else TEXT_PICKED_FOR) % quest_name
	HallStyle.set_font_color(_elsewhere_label, HallStyle.GREEN_TEXT if is_sent else HallStyle.BLUE_TEXT)


## True when `character` is in a party for a quest other than `entry`'s
## (picked or sent).
func _is_busy_elsewhere(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> bool:
	var quest_index := hall.quest_index_of(character)
	return quest_index >= 0 and hall.quest_entries[quest_index] != entry


## Right-hand column and paper tint: pinned to this party (green paper),
## can't go (faded), or how much they'd add to the odds (greyed out when
## they're already on another quest).
func _show_pick_state(hall: HallMain, entry: Dictionary, character: GuildCharacter) -> void:
	if entry.party.has(character):
		_adds_value.text = TEXT_IN_PARTY
		_adds_sub.visible = false
		HallStyle.set_font_color(_adds_value, HallStyle.GREEN_TEXT)
		HallStyle.style_panel(self, HallStyle.SENT_CARD_BG)
		# just pinned: "Assigned" stamps onto the row
		if hall.pending_fx.get("seat_in") == character:
			HallFx.stamp_in(_adds_value, 1.6)
	elif not hall.can_go_on_quests(character):
		_adds_value.text = TEXT_CANT_GO
		if HallStyle.is_dead(character):
			_adds_sub.text = TEXT_CANT_GO_SUB
		elif GuildUpgrades.is_patient(character):
			_adds_sub.text = TEXT_IN_BED_SUB
		else:
			_adds_sub.text = TEXT_TRAINING_SUB
		HallStyle.set_font_color(_adds_value, HallStyle.TEXT_SOFT)
		HallStyle.style_panel(self, HallStyle.DENIED_CARD_BG)
		modulate = Color(1, 1, 1, CANT_GO_OPACITY)
	else:
		var chance_added := hall.chance_added_by(entry, character)
		_adds_value.text = TEXT_ADDS % mini(chance_added, 100)
		_adds_sub.text = TEXT_ADDS_SUB
		_adds_sub.visible = SHOW_ADDS_CAPTION
		HallStyle.set_font_color(_adds_value, HallStyle.odds_look(chance_added).text_color)
		# on another quest: grey paper, faded
		if _is_busy_elsewhere(hall, entry, character):
			HallStyle.style_panel(self, HallStyle.DENIED_CARD_BG)
			modulate = Color(1, 1, 1, BUSY_OPACITY)
