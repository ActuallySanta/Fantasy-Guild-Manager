## Mobile Flow: a phone-first UI for the guild game built as a guided day loop.
##
## Instead of free tabs, each day walks through three steps:
##   1. Hire     - recruits for today (skippable)
##   2. Quests   - one quest per screen, party picked on the same screen,
##                 then Send or Deny moves straight on to the next quest
##   3. End Day  - today's plan at a glance, upgrades, and the End Day button
## The Guild button in the header opens the roster / upgrades at any time.
##
## Every screen is an authored scene (see MobileFlow/Scenes). This script holds
## the day's state and the game-flow calls, and tells each screen to refresh.
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Nothing in those scripts is changed.
extends Control

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10

## Current step: "hire" | "quests" | "end".
var step := "hire"
## Today's quests: {quest: CreatedQuest, state: "open"|"ready"|"denied", party: Array, milestone: bool}
var entries: Array = []
## Which quest the Quests step is showing, and the party being picked for it.
var quest_index := 0
var draft: Array = []
## Bottom sheet over the step: {} | {kind: "guild", seg: "roster"|"hire"|"upgrades"} | {kind: "character", character}
var sheet := {}
## Day report being shown: {live: bool, day: int, results: Array}. Empty = hidden.
var report := {}
var last_report := {}
var show_intro := true

var _dirty := false
var _toast_tween: Tween
var _last_view := ""

@onready var _day_label: Label = %DayValue
@onready var _gold_label: Label = %GoldValue
@onready var _standing_label: Label = %StandingValue
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


func _ready() -> void:
	_guild_button.pressed.connect(open_guild)
	for s in _step_buttons:
		_step_buttons[s].pressed.connect(go_step.bind(s))
	for node in [_steps.hire, _steps.quests, _steps.end, _sheet_guild, _sheet_character, _report, _intro]:
		node.setup(self)
	_toast.visible = false
	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)
	_generate_quests()
	_start_steps()
	refresh()


# ================================================================ game state

## Mirrors QuestList.populate / _generate_quests.
func _generate_quests() -> void:
	entries.clear()
	if GameState.day == MILESTONE_DAY:
		entries.append({"quest": CreatedQuest.new(MILESTONE_DAY), "state": "open", "party": [], "milestone": true})
		return
	for i in QUESTS_PER_DAY:
		entries.append({"quest": CreatedQuest.new(), "state": "open", "party": [], "milestone": false})


func _on_day_started(_day: int) -> void:
	_generate_quests()
	_start_steps()
	queue_refresh()


## Each morning: start on Hire if there's anyone to hire and room for them.
func _start_steps() -> void:
	quest_index = 0
	draft = []
	step = "hire" if can_hire_anyone() else "quests"


func can_hire_anyone() -> bool:
	return not CharacterContainer.hireable_characters.is_empty() \
		and CharacterContainer.active_characters.size() < CharacterContainer.max_characters


## Quests that still need Send (with a party) or Deny - QuestCard.is_outstanding.
func outstanding() -> int:
	return entries.filter(func(e): return e.state == "open").size()


func ready_entries() -> Array:
	return entries.filter(func(e): return e.state == "ready")


func entry_of(character: GuildCharacter) -> Dictionary:
	for e in entries:
		if e.state == "ready" and e.party.has(character):
			return e
	return {}


func slot_count(entry: Dictionary) -> int:
	return QuestCard.get_slot_count(entry.quest)


## Success chance as the quest computes it (-1 = no party yet).
func chance_for(entry: Dictionary, party: Array) -> int:
	if party.is_empty():
		return -1
	return int(entry.quest.calcSuccessChance(party))


func current_entry() -> Dictionary:
	if entries.is_empty():
		return {}
	return entries[clampi(quest_index, 0, entries.size() - 1)]


# ================================================================ actions

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


## First undecided quest at or after `from` (wrapping), or -1.
func _next_open(from: int) -> int:
	for k in entries.size():
		var i := (from + k) % entries.size()
		if entries[i].state == "open":
			return i
	return -1


func _advance() -> void:
	var next := _next_open(quest_index + 1)
	if next < 0:
		step = "end"
	else:
		show_quest(next)
	queue_refresh()


func toggle_draft(c: GuildCharacter) -> void:
	var n := slot_count(current_entry())
	if draft.has(c):
		draft.erase(c)
	elif n == 1:
		draft = [c]
	elif draft.size() < n:
		draft.append(c)
	queue_refresh()


## A character can only be on one quest (CharacterSlot.assign).
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
	toast("Party set for %s" % entry.quest.questTitle)
	_advance()


func deny_quest() -> void:
	var entry := current_entry()
	if entry.is_empty():
		return
	entry.party = []
	entry.state = "denied"
	toast("Denied: %s" % entry.quest.questTitle)
	_advance()


## Undo a decision so the quest can be decided again.
func reopen_quest() -> void:
	var entry := current_entry()
	entry.party = []
	entry.state = "open"
	draft = []
	queue_refresh()


func hire(character: GuildCharacter) -> void:
	if CharacterContainer.add_character_to_guild(character):
		toast("%s joined the guild!" % character.name)
	queue_refresh()


func upgrade(building: int) -> void:
	if GuildUpgrades.try_upgrade(building):
		toast("%s upgraded to level %d!" % [GuildUpgrades.get_building_name(building), GuildUpgrades.get_level(building)])
	queue_refresh()


## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the summary.
func end_day() -> void:
	if outstanding() > 0:
		go_step("quests")
		return
	var results := []
	for e in ready_entries():
		var typed_party: Array[GuildCharacter] = []
		typed_party.assign(e.party)
		var chance: float = DayBarLogic._get_success_chance(e.quest, typed_party)
		var story: String = e.quest.generateResults(typed_party, chance)
		var succeeded: bool = DayBarLogic._did_succeed(story)
		var gold: int = DayBarLogic._get_gold_earned(e.quest, succeeded)
		GameState.add_gold(gold)
		results.append({"quest": e.quest, "party": e.party.duplicate(), "story": story, "succeeded": succeeded, "chance": chance, "gold": gold})
	sheet = {}
	report = {"live": true, "day": GameState.day, "results": results}
	queue_refresh()


## DaySummary's "New Day" button.
func start_new_day() -> void:
	last_report = report.duplicate()
	last_report.live = false
	report = {}
	GameState.start_new_day()
	if GameState.day == MILESTONE_DAY:
		toast("Day %d. The Bone Drake is attacking!" % GameState.day)
	else:
		toast("Day %d begins" % GameState.day)
	queue_refresh()


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


func open_guild(seg: String = "roster") -> void:
	sheet = {"kind": "guild", "seg": seg}
	queue_refresh()


func open_character(c: GuildCharacter) -> void:
	sheet = {"kind": "character", "character": c, "back": sheet.duplicate()}
	queue_refresh()


func close_sheet() -> void:
	sheet = sheet.get("back", {}) if sheet.get("kind", "") == "character" else {}
	queue_refresh()


func close_intro() -> void:
	show_intro = false
	queue_refresh()


# ================================================================ refresh

func queue_refresh() -> void:
	if _dirty:
		return
	_dirty = true
	refresh.call_deferred()


func refresh() -> void:
	_dirty = false
	_day_label.text = str(GameState.day)
	_gold_label.text = str(GameState.gold)
	_standing_label.text = str(GameState.standing)
	_refresh_steps_bar()

	for s in _steps:
		_steps[s].visible = s == step
	_steps[step].refresh()
	var view := "%s:%d:%d" % [step, quest_index, GameState.day]
	if view != _last_view:
		_last_view = view
		_steps[step].scroll_to_top()

	var kind: String = sheet.get("kind", "")
	_sheet_guild.visible = kind == "guild"
	_sheet_character.visible = kind == "character"
	_sheet_layer.mouse_filter = MOUSE_FILTER_IGNORE if kind == "" else MOUSE_FILTER_STOP
	# sheets cover the step but leave its footer in reach
	_sheet_layer.offset_bottom = -_steps[step].footer_height()
	if kind == "guild":
		_sheet_guild.refresh()
	elif kind == "character":
		_sheet_character.refresh()

	_report.visible = not report.is_empty()
	_intro.visible = report.is_empty() and show_intro
	_overlay.mouse_filter = MOUSE_FILTER_STOP if _report.visible or _intro.visible else MOUSE_FILTER_IGNORE
	if _report.visible:
		_report.refresh()


func _refresh_steps_bar() -> void:
	var out := outstanding()
	for s in _step_buttons:
		var b: Button = _step_buttons[s]
		var done := false
		match s:
			"hire":
				b.text = "1. Hire"
				done = not can_hire_anyone() or CharacterContainer.active_characters.size() > 0
			"quests":
				b.text = "2. Quests" + (" (%d left)" % out if out > 0 else "")
				done = out == 0
			"end":
				b.text = "3. End Day"
		if s == step:
			S.style_button_active(b)
		else:
			S.style_button(b)
			if done:
				b.add_theme_color_override("font_color", S.GOOD)


func toast(text: String) -> void:
	_toast_label.text = text
	_toast.offset_bottom = -12 - _steps[step].footer_height()
	_toast.offset_top = _toast.offset_bottom - 58
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)
