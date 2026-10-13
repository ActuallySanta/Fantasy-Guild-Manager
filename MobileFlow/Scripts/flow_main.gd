## Mobile Flow: a phone-first UI for the guild game built as a guided day loop.
##
## Instead of free tabs, each day walks through three steps:
##   1. Hire     - recruits for today (skippable)
##   2. Quests   - one quest per screen, party picked on the same screen,
##                 then Send or Deny moves straight on to the next quest
##   3. End Day  - today's plan at a glance, upgrades, and the End Day button
## The Guild button in the header opens the roster / upgrades at any time.
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Nothing in those scripts is changed.
extends Control

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")
const StepHire := preload("res://MobileFlow/Scripts/step_hire.gd")
const StepQuest := preload("res://MobileFlow/Scripts/step_quest.gd")
const StepEnd := preload("res://MobileFlow/Scripts/step_end.gd")
const SheetGuild := preload("res://MobileFlow/Scripts/sheet_guild.gd")
const SheetCharacter := preload("res://MobileFlow/Scripts/sheet_character.gd")
const OverlayReport := preload("res://MobileFlow/Scripts/overlay_report.gd")
const OverlayIntro := preload("res://MobileFlow/Scripts/overlay_intro.gd")

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10

const STEPS := [["hire", "1. Hire"], ["quests", "2. Quests"], ["end", "3. End Day"]]

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

var _stat_labels := {}
var _steps_bar: HBoxContainer
var _content: VBoxContainer
var _scroll: ScrollContainer
var _footer: PanelContainer
var _sheet_layer: Control
var _overlay: Control
var _body: Control
var _toast: PanelContainer
var _dirty := false


func _ready() -> void:
	theme = S.make_theme()
	_build_shell()
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


# ================================================================ shell

func _build_shell() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = S.BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var col := S.vbox(0)
	col.set_anchors_preset(PRESET_FULL_RECT)
	add_child(col)

	# header: resources + Guild button
	var head := S.panel("panel")
	var hh := S.hbox(18)
	head.add_child(hh)
	for c in [["sun", "day", "Day"], ["coins", "gold", "Gold"], ["rook", "standing", "Standing"]]:
		var cell := S.hbox(6)
		cell.add_child(S.icon(c[0], 30))
		var num := S.label("0", 24)
		cell.add_child(S.label(c[2] + ":", 22, S.INK_SOFT))
		cell.add_child(num)
		hh.add_child(cell)
		_stat_labels[c[1]] = num
	hh.add_child(S.spacer())
	var gb := S.button("Guild", "", 22, 52)
	gb.icon = S.icon_tex("nav_characters")
	gb.pressed.connect(open_guild)
	hh.add_child(gb)
	col.add_child(head)

	# step bar
	var sb := S.panel("bar", Vector4(10, 8, 10, 8))
	_steps_bar = S.hbox(8)
	sb.add_child(_steps_bar)
	col.add_child(sb)

	# body: scrolling step content, with sheets on top
	_body = Control.new()
	_body.size_flags_vertical = SIZE_EXPAND_FILL
	_body.clip_contents = true
	col.add_child(_body)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.set_anchors_preset(PRESET_FULL_RECT)
	_body.add_child(_scroll)
	_content = S.vbox(14)
	_content.size_flags_horizontal = SIZE_EXPAND_FILL
	var m := S.margin(_content, 16, 16, 16, 24)
	m.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(m)
	_sheet_layer = Control.new()
	_sheet_layer.set_anchors_preset(PRESET_FULL_RECT)
	_sheet_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_body.add_child(_sheet_layer)

	# footer: the step's main action(s), always in thumb reach
	_footer = S.panel("bar", Vector4(14, 10, 14, 10))
	col.add_child(_footer)

	_overlay = Control.new()
	_overlay.set_anchors_preset(PRESET_FULL_RECT)
	_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_overlay)


func queue_refresh() -> void:
	if _dirty:
		return
	_dirty = true
	refresh.call_deferred()


func refresh() -> void:
	_dirty = false
	_stat_labels.day.text = str(GameState.day)
	_stat_labels.gold.text = str(GameState.gold)
	_stat_labels.standing.text = str(GameState.standing)
	_build_steps_bar()

	S.clear(_content)
	S.clear(_footer)
	var built: Dictionary
	match step:
		"hire":
			built = StepHire.build(self)
		"quests":
			built = StepQuest.build(self)
		_:
			built = StepEnd.build(self)
	_content.add_child(built.body)
	_footer.add_child(built.footer)
	_scroll.scroll_vertical = 0

	S.clear(_sheet_layer)
	_sheet_layer.mouse_filter = MOUSE_FILTER_IGNORE
	match sheet.get("kind", ""):
		"guild":
			_sheet_layer.add_child(SheetGuild.build(self))
			_sheet_layer.mouse_filter = MOUSE_FILTER_STOP
		"character":
			_sheet_layer.add_child(SheetCharacter.build(self))
			_sheet_layer.mouse_filter = MOUSE_FILTER_STOP

	S.clear(_overlay)
	_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	if not report.is_empty():
		_overlay.add_child(OverlayReport.build(self))
		_overlay.mouse_filter = MOUSE_FILTER_STOP
	elif show_intro:
		_overlay.add_child(OverlayIntro.build(self))
		_overlay.mouse_filter = MOUSE_FILTER_STOP


func _build_steps_bar() -> void:
	S.clear(_steps_bar)
	var out := outstanding()
	for st in STEPS:
		var active: bool = st[0] == step
		var label: String = st[1]
		var done := false
		match st[0]:
			"hire":
				done = not can_hire_anyone() or CharacterContainer.active_characters.size() > 0
			"quests":
				label += " (%d left)" % out if out > 0 else ""
				done = out == 0
		var b := S.button(label, "", 20, 48)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		if active:
			for s in ["normal", "hover"]:
				b.add_theme_stylebox_override(s, S.flat(S.INFO_BG, 0, 2, S.INFO, Vector4(6, 4, 6, 4)))
			b.add_theme_color_override("font_color", S.INFO)
			b.add_theme_color_override("font_hover_color", S.INFO)
		elif done:
			b.add_theme_color_override("font_color", S.GOOD)
		b.pressed.connect(go_step.bind(st[0]))
		_steps_bar.add_child(b)


func toast(text: String) -> void:
	if _toast and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", S.flat(Color("#333333"), 0, 0, S.INK, Vector4(16, 10, 16, 10)))
	var l := S.wrap(S.label(text, 22, S.WHITE))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(l)
	_toast.mouse_filter = MOUSE_FILTER_IGNORE
	_toast.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_toast.offset_left = 30
	_toast.offset_right = -30
	_toast.offset_top = -70
	_toast.offset_bottom = -12
	_body.add_child(_toast)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_toast.queue_free)
