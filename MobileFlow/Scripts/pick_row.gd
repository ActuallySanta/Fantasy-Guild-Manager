## One adventurer in the Quests step's party picker. Tap to add / remove them.
## Scene: MobileFlow/Scenes/Rows/pick_row.tscn
extends "res://MobileFlow/Scripts/tap_area.gd"

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")

# ---- TEXT
const TEXT_ELSEWHERE := "Already on \"%s\". Picking moves them here."
const TEXT_PARTY_FULL := "Party is full"
const TEXT_ADDS := "+%d%%"

# ---- NODES
@onready var _card: PanelContainer = %Card
@onready var _check: CheckBox = %Check
@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _injury = %Injury
@onready var _stats = %Stats
@onready var _note: Label = %Note
@onready var _adds: Label = %Adds


func setup(ui: Main, e: Dictionary, c: GuildCharacter, slots: int) -> void:
	var chosen: bool = ui.draft.has(c)
	var full: bool = not chosen and slots > 1 and ui.draft.size() >= slots
	var elsewhere: Dictionary = ui.entry_of(c)
	if elsewhere == e:
		elsewhere = {}

	# chosen rows are blue; full-party rows are faded and can't be tapped
	_card.add_theme_stylebox_override("panel", S.flat(S.INFO_BG if chosen else S.BOX, 0, 1, S.INFO if chosen else S.LINE, Vector4(12, 10, 12, 10)))
	_card.modulate = Color(1, 1, 1, 0.5) if full else Color.WHITE
	disabled = full
	_check.button_pressed = chosen

	_portrait.show_character(c)
	_char_name.text = c.name
	_injury.set_injury(c.injury_level)
	_stats.show_stats(c, S.favored_index(e.quest), false)
	_adds.text = TEXT_ADDS % ui.chance_for(e, [c])

	_note.visible = not elsewhere.is_empty() or full
	if not elsewhere.is_empty():
		_note.text = TEXT_ELSEWHERE % elsewhere.quest.questTitle
		S.color(_note, S.INFO)
	elif full:
		_note.text = TEXT_PARTY_FULL
		S.color(_note, S.INK_SOFT)

	pressed.connect(ui.toggle_draft.bind(c))
