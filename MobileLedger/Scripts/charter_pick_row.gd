## One adventurer in the Mission Charter's roster. Tap to add / remove them.
## Shows their four quest stats (the favored one outlined) and what they add
## to the odds on their own.
## Scene: MobileLedger/Scenes/Rows/charter_pick_row.tscn
extends "res://MobileLedger/Scripts/tap_area.gd"

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

const CHECKED := Color("#3F7A2E")

# ---- TEXT
const TEXT_ELSEWHERE := "On \"%s\" · picking moves them"
const TEXT_PARTY_FULL := "Party is full"
const TEXT_ADDS := "+%d%%"

# ---- NODES
@onready var _card: PanelContainer = %Card
@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _injury = %Injury
@onready var _stat_chips: Array = [%Stat0, %Stat1, %Stat2, %Stat3]
@onready var _note: Label = %Note
@onready var _contribution: Label = %Contribution
@onready var _check_box: PanelContainer = %CheckBox
@onready var _check: Control = %Check


func setup(ui: Main, e: Dictionary, c: GuildCharacter, draft: Array, slots: int) -> void:
	var chosen := draft.has(c)
	var full := not chosen and slots > 1 and draft.size() >= slots
	var elsewhere: Dictionary = ui.entry_of(c)
	if elsewhere == e:
		elsewhere = {}

	# chosen rows get the gold "ready" frame; full-party rows are faded and locked
	_card.add_theme_stylebox_override("panel", S.panel_box("ready" if chosen else "card", Vector4(18, 14, 18, 14)))
	_card.modulate = Color(1, 1, 1, 0.55) if full else Color.WHITE
	disabled = full

	_portrait.show_character(c)
	_char_name.text = c.name
	_injury.set_injury(c.injury_level)
	var fav := S.favored_index(e.quest)
	for i in 4:
		var st: Dictionary = S.STATS[i]
		_stat_chips[i].set_icon_chip(st.icon, str(c.stats[i]), st.bg, st.color, -1, i == fav)

	_note.visible = not elsewhere.is_empty() or full
	if not elsewhere.is_empty():
		_note.text = TEXT_ELSEWHERE % elsewhere.quest.questTitle
		S.color(_note, S.BLUE_TEXT)
	elif full:
		_note.text = TEXT_PARTY_FULL
		S.color(_note, S.INK_SOFT)

	_contribution.text = TEXT_ADDS % ui.chance_for(e, [c])
	_check_box.add_theme_stylebox_override("panel", S.flat(CHECKED if chosen else S.CREAM, 10, 3, S.INK, Vector4(6, 6, 6, 6)))
	_check.visible = chosen
	pressed.connect(ui.toggle_charter_pick.bind(c))
