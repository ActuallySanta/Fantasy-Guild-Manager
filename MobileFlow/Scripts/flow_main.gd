## Mobile Flow: a phone-first UI for the guild game built as a guided day loop.
## Scene: MobileFlow/flow_main.tscn
##
## Each day walks through three steps:
##   1. Hire     - today's recruits (skippable)
##   2. Quests   - one quest per screen with the party picker under it;
##                 Send or Deny moves straight on to the next quest
##   3. End Day  - today's plan, upgrades, and the End Day button
## The Guild button in the header opens the roster / upgrades at any time.
##
## This script owns the day's state and every game action. The screens
## (steps, sheets, overlays) call the ACTIONS below and read the QUERIES; after
## any change this script calls refresh() on whatever is showing.
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Nothing in those scripts is changed.
##
## Sections: SETTINGS · TEXT · STATE · NODES · SETUP · QUERIES · ACTIONS ·
##           REFRESH · TOAST
extends Control

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")


# ============================================================ SETTINGS

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10
## Seconds a toast stays up before fading.
const TOAST_SECONDS := 2.0


# ============================================================ TEXT

const STEP_LABELS := {"hire": "1. Hire", "quests": "2. Quests", "end": "3. End Day"}
const STEP_QUESTS_LEFT := " (%d left)"
const TOAST_PARTY_SET := "Party set for %s"
const TOAST_DENIED := "Denied: %s"
const TOAST_HIRED := "%s joined the guild!"
const TOAST_UPGRADED := "%s upgraded to level %d!"
const TOAST_NEW_DAY := "Day %d begins"
const TOAST_MILESTONE_DAY := "Day %d. The Bone Drake is attacking!"


# ============================================================ STATE

## Current step: "hire" | "quests" | "end".
var step := "hire"
## Today's quests. Each entry:
##   {quest: CreatedQuest, state: "open" | "ready" | "denied", party: Array, milestone: bool}
var entries: Array = []
## Which quest the Quests step is showing, and the party being picked for it.
var quest_index := 0
var draft: Array = []
## Sheet over the step:
##   {} | {kind: "guild", seg: "roster" | "hire" | "upgrades"} | {kind: "character", character, back}
var sheet := {}
## Day report being shown: {live: bool, day: int, results: Array}. Empty = hidden.
var report := {}
## Yesterday's report, readable again from the End Day step.
var last_report := {}
var show_intro := true

var _refresh_queued := false
var _last_view := ""
var _toast_tween: Tween


# ============================================================ NODES

@onready var _day_value: Label = %DayValue
@onready var _gold_value: Label = %GoldValue
@onready var _standing_value: Label = %StandingValue
@onready var _guild_button: Button = %GuildButton
@onready var _step_buttons := {"hire": %StepHireButton, "quests": %StepQuestsButton, "end": %StepEndButton}
@onready var _steps := {"hire": %StepHire, "quests": %StepQuest, "end": %StepEnd}
@onready var _sheet_layer: Control = %SheetLayer
@onready var _sheet_guild: Control = %SheetGuild
@onready var _sheet_character: Control = %SheetCharacter
@onready var _overlay: Control = %Overlay
@onready var _report: Control = %OverlayReport
@onready var _intro: Control = %OverlayIntro
@onready var _toast: PanelContainer = %Toast
@onready var _toast_label: Label = %ToastLabel


# ============================================================ SETUP

func _ready() -> void:
	_guild_button.pressed.connect(open_guild)
	for s in _step_buttons:
		_step_buttons[s].pressed.connect(go_step.bind(s))
	for screen in [_steps.hire, _steps.quests, _steps.end, _sheet_guild, _sheet_character, _report, _intro]:
		screen.setup(self)
	_toast.visible = false

	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)

	_generate_quests()
	_start_of_day_step()
	refresh()


func _on_day_started(_day: int) -> void:
	_generate_quests()
	_start_of_day_step()
	queue_refresh()


## Mirrors QuestList.populate / _generate_quests.
func _generate_quests() -> void:
	entries.clear()
	if GameState.day == MILESTONE_DAY:
		entries.append(_new_entry(CreatedQuest.new(MILESTONE_DAY), true))
		return
	for i in QUESTS_PER_DAY:
		entries.append(_new_entry(CreatedQuest.new(), false))


func _new_entry(quest: CreatedQuest, milestone: bool) -> Dictionary:
	return {"quest": quest, "state": "open", "party": [], "milestone": milestone}


## Each morning: start on Hire if there's anyone to hire and room for them.
func _start_of_day_step() -> void:
	quest_index = 0
	draft = []
	step = "hire" if can_hire_anyone() else "quests"


# ============================================================ QUERIES

func can_hire_anyone() -> bool:
	return not CharacterContainer.hireable_characters.is_empty() \
		and CharacterContainer.active_characters.size() < CharacterContainer.max_characters


## How many quests still need Send (with a party) or Deny. QuestCard.is_outstanding.
func outstanding() -> int:
	return entries.filter(func(e): return e.state == "open").size()


func ready_entries() -> Array:
	return entries.filter(func(e): return e.state == "ready")


## The quest a character is already sent on today, or {}.
func entry_of(character: GuildCharacter) -> Dictionary:
	for e in entries:
		if e.state == "ready" and e.party.has(character):
			return e
	return {}


## How many adventurers a quest takes.
func slot_count(entry: Dictionary) -> int:
	return QuestCard.get_slot_count(entry.quest)


## Success chance as the quest computes it (-1 = no party yet).
func chance_for(entry: Dictionary, party: Array) -> int:
	if party.is_empty():
		return -1
	return int(entry.quest.calcSuccessChance(party))


## The quest the Quests step is showing, or {} if there are none.
func current_entry() -> Dictionary:
	if entries.is_empty():
		return {}
	return entries[clampi(quest_index, 0, entries.size() - 1)]


## First undecided quest at or after `from` (wrapping around), or -1.
func _next_open(from: int) -> int:
	for k in entries.size():
		var i := (from + k) % entries.size()
		if entries[i].state == "open":
			return i
	return -1


# ============================================================ ACTIONS

# ---- moving around

func go_step(s: String) -> void:
	step = s
	sheet = {}
	if s == "quests":
		var next := _next_open(quest_index)
		show_quest(next if next >= 0 else quest_index)
	queue_refresh()


func show_quest(i: int) -> void:
	quest_index = clampi(i, 0, maxi(entries.size() - 1, 0))
	var e := current_entry()
	draft = e.party.duplicate() if not e.is_empty() else []
	step = "quests"
	queue_refresh()


## Go to the next undecided quest, or to End Day when there are none left.
func advance() -> void:
	var next := _next_open(quest_index + 1)
	if next < 0:
		step = "end"
	else:
		show_quest(next)
	queue_refresh()


func open_guild(seg: String = "roster") -> void:
	sheet = {"kind": "guild", "seg": seg}
	queue_refresh()


func set_guild_tab(seg: String) -> void:
	sheet.seg = seg
	queue_refresh()


## Character details. Closing goes back to whatever sheet was open before.
func open_character(c: GuildCharacter) -> void:
	sheet = {"kind": "character", "character": c, "back": sheet.duplicate()}
	queue_refresh()


func close_sheet() -> void:
	sheet = sheet.get("back", {}) if sheet.get("kind", "") == "character" else {}
	queue_refresh()


func open_intro() -> void:
	show_intro = true
	queue_refresh()


func close_intro() -> void:
	show_intro = false
	queue_refresh()


# ---- quests

## Tap an adventurer in the picker: add or remove them from the draft party.
func toggle_draft(c: GuildCharacter) -> void:
	var n := slot_count(current_entry())
	if draft.has(c):
		draft.erase(c)
	elif n == 1:
		draft = [c]
	elif draft.size() < n:
		draft.append(c)
	queue_refresh()


## Send the draft party. A character can only be on one quest
## (CharacterSlot.assign), so they leave any other party first.
func send_party() -> void:
	var entry := current_entry()
	if draft.is_empty() or entry.is_empty():
		return
	for e in entries:
		if e == entry:
			continue
		e.party = e.party.filter(func(c): return not draft.has(c))
		if e.state == "ready" and e.party.is_empty():
			e.state = "open"
	entry.party = draft.duplicate()
	entry.state = "ready"
	toast(TOAST_PARTY_SET % entry.quest.questTitle)
	advance()


func deny_quest() -> void:
	var entry := current_entry()
	if entry.is_empty():
		return
	entry.party = []
	entry.state = "denied"
	
	# Right now just reduce standing by the quest difficulty, 
	#but in the future we can reduce the standing 
	#depending on the importance
	GameState.reduce_standing(entry.quest.difficulty)
	
	toast(TOAST_DENIED % entry.quest.questTitle)
	advance()


## Undo a decision so the quest can be decided again.
func reopen_quest() -> void:
	var entry := current_entry()
	entry.party = []
	entry.state = "open"
	draft = []
	queue_refresh()


# ---- guild

func hire(character: GuildCharacter) -> void:
	if CharacterContainer.add_character_to_guild(character):
		toast(TOAST_HIRED % character.name)
	queue_refresh()


func upgrade(building: int) -> void:
	if GuildUpgrades.try_upgrade(building):
		toast(TOAST_UPGRADED % [GuildUpgrades.get_building_name(building), GuildUpgrades.get_level(building)])
	queue_refresh()


# ---- end of day

## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the report.
func end_day() -> void:
	if outstanding() > 0:
		go_step("quests")
		return
	var results := []
	for e in ready_entries():
		results.append(_run_quest(e))
	sheet = {}
	report = {"live": true, "day": GameState.day, "results": results}
	queue_refresh()


## Play out one quest with DayBar's helpers and pay its gold.
func _run_quest(e: Dictionary) -> Dictionary:
	var party: Array[GuildCharacter] = []
	party.assign(e.party)
	var chance: float = DayBarLogic._get_success_chance(e.quest, party)
	var story: String = e.quest.generateResults(party, chance)
	var succeeded: bool = DayBarLogic._did_succeed(story)
	var gold: int = DayBarLogic._get_gold_earned(e.quest, succeeded)
	GameState.add_gold(gold)
	
	if(succeeded):
		GameState.add_standing(e.quest.difficulty+1)
	
	return {"quest": e.quest, "party": e.party.duplicate(), "story": story, "succeeded": succeeded, "chance": chance, "gold": gold}


## DaySummary's "New Day" button.
func start_new_day() -> void:
	last_report = report.duplicate()
	last_report.live = false
	report = {}
	GameState.start_new_day()
	toast((TOAST_MILESTONE_DAY if GameState.day == MILESTONE_DAY else TOAST_NEW_DAY) % GameState.day)
	queue_refresh()


## The report's button: starts the next day after End Day, otherwise just closes.
func close_report() -> void:
	if report.get("live", false):
		start_new_day()
	else:
		report = {}
		queue_refresh()


func open_last_report() -> void:
	if last_report.is_empty():
		return
	report = last_report.duplicate()
	report.live = false
	queue_refresh()


# ============================================================ REFRESH

## Ask for a refresh at the end of this frame (many changes = one refresh).
func queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	refresh.call_deferred()


func refresh() -> void:
	_refresh_queued = false
	_refresh_header()
	_refresh_steps_bar()
	_refresh_step()
	_refresh_sheets()
	_refresh_overlays()


func _refresh_header() -> void:
	_day_value.text = str(GameState.day)
	_gold_value.text = str(GameState.gold)
	_standing_value.text = str(GameState.standing)


## Step buttons: current step highlighted, finished steps in green.
func _refresh_steps_bar() -> void:
	var out := outstanding()
	var done := {
		"hire": not can_hire_anyone() or not CharacterContainer.active_characters.is_empty(),
		"quests": out == 0,
		"end": false,
	}
	for s in _step_buttons:
		var b: Button = _step_buttons[s]
		b.text = STEP_LABELS[s] + (STEP_QUESTS_LEFT % out if s == "quests" and out > 0 else "")
		if s == step:
			S.style_button_active(b)
		else:
			S.style_button(b)
			if done[s]:
				S.color(b, S.GOOD)


func _refresh_step() -> void:
	for s in _steps:
		_steps[s].visible = s == step
	_steps[step].refresh()
	# back to the top only when the screen changes, not on every tap
	var view := "%s:%d:%d" % [step, quest_index, GameState.day]
	if view != _last_view:
		_last_view = view
		_steps[step].scroll_to_top()


func _refresh_sheets() -> void:
	var kind: String = sheet.get("kind", "")
	_sheet_guild.visible = kind == "guild"
	_sheet_character.visible = kind == "character"
	_sheet_layer.mouse_filter = MOUSE_FILTER_IGNORE if kind == "" else MOUSE_FILTER_STOP
	# sheets cover the step but leave its footer buttons in reach
	_sheet_layer.offset_bottom = -_steps[step].footer_height()
	if _sheet_guild.visible:
		_sheet_guild.refresh()
	if _sheet_character.visible:
		_sheet_character.refresh()


func _refresh_overlays() -> void:
	_report.visible = not report.is_empty()
	_intro.visible = report.is_empty() and show_intro
	_overlay.mouse_filter = MOUSE_FILTER_STOP if _report.visible or _intro.visible else MOUSE_FILTER_IGNORE
	if _report.visible:
		_report.refresh()


# ============================================================ TOAST

## Short message above the footer that fades out.
func toast(text: String) -> void:
	_toast_label.text = text
	_toast.offset_bottom = -12 - _steps[step].footer_height()
	_toast.offset_top = _toast.offset_bottom - 58
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)
