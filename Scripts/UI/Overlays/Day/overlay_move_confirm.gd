## Move confirmation: asked when the player taps an adventurer in Assign
## Party's picker who is already in another quest's party (picked or sent).
##   - who, and which quest they'd be taken off
##   - Cancel / Move (hall.toggle_in_party, which pulls them off the other
##     quest and pins them to the one on screen)
## It belongs to screen_assign.gd, which opens it; tapping the dim cancels.
## Drawn over the whole screen (top_level).
## Scene: Scenes/Overlays/Day/overlay_move_confirm.tscn
extends Control

## Font size of the buttons (design px; HallFontScale grows them with everything else).
const BUTTON_FONT_SIZE := 28
## Seconds the popup takes to fade in.
const FADE_IN_SECONDS := 0.15

# ---- TEXT
const TITLE := "Move %s?"
## The other quest's name, as the pick row writes it ("#2 Escort the...").
const TEXT_QUEST_NAME := "#%d %s"
const BODY_PICKED := "%s is picked for %s."
const BODY_SENT := "%s was already sent on %s."
const NOTE := "Moving them takes them off that quest."
## Added to the note when they're the last one on a sent quest.
const NOTE_LAST_SENT := "Moving them takes them off that quest, and it goes back to undecided."
const BUTTON_CANCEL := "Cancel"
const BUTTON_MOVE := "Move"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _title: Label = %Title
@onready var _body: Label = %Body
@onready var _note: Label = %Note
@onready var _cancel_button: Button = %CancelButton
@onready var _move_button: Button = %MoveButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## Who the popup is asking about (null = closed).
var _character: GuildCharacter


func setup(main: HallMain) -> void:
	hall = main
	_cancel_button.pressed.connect(close)
	_move_button.pressed.connect(_on_move_pressed)
	_dim.gui_input.connect(_on_dim_input)

	_cancel_button.text = BUTTON_CANCEL
	_move_button.text = BUTTON_MOVE
	HallStyle.style_button(_cancel_button, "wood", BUTTON_FONT_SIZE)
	HallStyle.style_button(_move_button, "gold", BUTTON_FONT_SIZE)


## Ask whether to move `character` off the quest they're on and onto the one
## on screen. Does nothing if they aren't in any quest's party.
func open(character: GuildCharacter) -> void:
	var other_index := hall.quest_index_of(character)
	if other_index < 0:
		return
	var other_entry: Dictionary = hall.quest_entries[other_index]
	var is_sent: bool = other_entry.state == HallStyle.QUEST_STATE_SENT
	var quest_name := TEXT_QUEST_NAME % [other_index + 1, other_entry.quest.questTitle]

	_character = character
	_title.text = TITLE % character.name
	_body.text = (BODY_SENT if is_sent else BODY_PICKED) % [character.name, quest_name]
	# the last one off a sent quest sends it back to open (hall._remove_from_party)
	_note.text = NOTE_LAST_SENT if is_sent and other_entry.party.size() == 1 else NOTE
	visible = true
	HallFx.fade_in(self, 0.0, FADE_IN_SECONDS)


func close() -> void:
	visible = false
	_character = null


## Move: close first (the move refreshes the screen), then pin them here.
func _on_move_pressed() -> void:
	var character := _character
	close()
	if character != null:
		hall.toggle_in_party(character)


## Tapping the dimmed background cancels.
func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
