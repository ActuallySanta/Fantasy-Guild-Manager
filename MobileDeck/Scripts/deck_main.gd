## Mobile Deck: a phone-first UI for the guild game built as a swipeable card deck.
##
## Each day is a stack of cards:
##   recruit cards  -> swipe right to hire, left to pass
##   quest cards    -> tap adventurers in the bottom tray to add them, then
##                     swipe right to send the party, left to deny the quest
##   end-of-day card -> today's plan, upgrades, End Day
## Every swipe also has a button under the card. Back undoes the last card.
##
## Every screen is an authored scene (see MobileDeck/Scenes). This script holds
## the day's state, the game-flow calls and the swipe handling, and tells each
## part of the screen to refresh.
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Nothing in those scripts is changed.
extends Control

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")
const ProgressDot := preload("res://MobileDeck/Scenes/Rows/progress_dot.tscn")
const TrayTile := preload("res://MobileDeck/Scenes/Rows/tray_tile.tscn")

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10
## How far (px) a card must be dragged to count as a swipe.
const SWIPE_DISTANCE := 170.0

## Today's quests: {quest: CreatedQuest, state: "open"|"ready"|"denied", party: Array, milestone: bool}
var entries: Array = []
## Today's deck: {kind: "hire", character} | {kind: "quest", entry} | {kind: "end"}
var deck: Array = []
var index := 0
## Party being built on the current quest card.
var draft: Array = []
## Sheet over everything: {} | {kind: "upgrades"} | {kind: "character", character} | {kind: "intro"}
var sheet := {"kind": "intro"}
var report := {}
var last_report := {}

var _dirty := false
var _drag_from := Vector2.ZERO
var _dragging := false
var _toast_tween: Tween

@onready var _stage: Control = %Stage
@onready var _card: PanelContainer = %Card
@onready var _faces := {"hire": %CardHire, "quest": %CardQuest, "end": %CardEnd}
@onready var _swipe_hint: Label = %SwipeHint
@onready var _sheets := {"upgrades": %SheetUpgrades, "character": %SheetCharacter, "intro": %SheetIntro}
@onready var _report: Control = %OverlayReport
@onready var _overlay: Control = %Overlay
@onready var _toast: PanelContainer = %Toast


func _ready() -> void:
	%UpgradesButton.pressed.connect(open_sheet.bind("upgrades"))
	%HelpButton.pressed.connect(open_sheet.bind("intro"))
	%BackButton.pressed.connect(back)
	%NoButton.pressed.connect(press_swipe.bind(-1))
	%YesButton.pressed.connect(press_swipe.bind(1))
	_stage.resized.connect(_layout_card)
	_card.gui_input.connect(_on_card_input)
	for n in [_faces.hire, _faces.quest, _faces.end, _sheets.upgrades, _sheets.character, _sheets.intro, _report]:
		n.setup(self)
	_toast.visible = false
	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)
	_new_day_deck()
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


func _new_day_deck() -> void:
	_generate_quests()
	deck.clear()
	if room() > 0:
		for c in CharacterContainer.hireable_characters:
			deck.append({"kind": "hire", "character": c})
	for e in entries:
		deck.append({"kind": "quest", "entry": e})
	deck.append({"kind": "end"})
	index = 0
	draft = []
	_skip_dead_cards()


func _on_day_started(_day: int) -> void:
	_new_day_deck()
	queue_refresh()


func room() -> int:
	return CharacterContainer.max_characters - CharacterContainer.active_characters.size()


## Recruit cards stop mattering once the guild is full (or they've been hired).
func _skip_dead_cards() -> void:
	while index < deck.size() - 1 and deck[index].kind == "hire" \
			and (room() <= 0 or not CharacterContainer.hireable_characters.has(deck[index].character)):
		index += 1


func current() -> Dictionary:
	return deck[clampi(index, 0, deck.size() - 1)]


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


# ================================================================ card actions

## dir: +1 = right (hire / send), -1 = left (pass / deny). Returns false if not allowed.
func can_swipe(dir: int) -> bool:
	var c := current()
	match c.kind:
		"hire":
			return dir < 0 or room() > 0
		"quest":
			return dir < 0 or not draft.is_empty()
	return false


func swipe(dir: int) -> void:
	if not can_swipe(dir):
		_nudge()
		return
	var c := current()
	match c.kind:
		"hire":
			if dir > 0 and CharacterContainer.add_character_to_guild(c.character):
				toast("%s joined the guild!" % c.character.name)
		"quest":
			var e: Dictionary = c.entry
			if dir > 0:
				for other in entries:
					if other == e:
						continue
					other.party = other.party.filter(func(x): return not draft.has(x))
					if other.state == "ready" and other.party.is_empty():
						other.state = "open"
				e.party = draft.duplicate()
				e.state = "ready"
				toast("Party sent to %s" % e.quest.questTitle)
			else:
				e.party = []
				e.state = "denied"
				toast("Denied: %s" % e.quest.questTitle)
	index += 1
	draft = []
	_skip_dead_cards()
	# a quest whose party got moved elsewhere comes back as undecided: send the player to it
	if current().kind == "end" and outstanding() > 0:
		_go_to_first_open()
	_load_draft()
	queue_refresh()


## Back: step to the previous card and undo its decision.
func back() -> void:
	var i := index - 1
	while i >= 0 and deck[i].kind == "hire" and not CharacterContainer.hireable_characters.has(deck[i].character):
		i -= 1
	if i < 0:
		return
	index = i
	var c := current()
	if c.kind == "quest":
		var e: Dictionary = c.entry
		draft = e.party.duplicate()
		e.party = []
		e.state = "open"
	queue_refresh()


func _go_to_first_open() -> void:
	for i in deck.size():
		if deck[i].kind == "quest" and deck[i].entry.state == "open":
			index = i
			return


func _load_draft() -> void:
	var c := current()
	draft = c.entry.party.duplicate() if c.kind == "quest" else []


func jump_to_entry(e: Dictionary) -> void:
	for i in deck.size():
		if deck[i].kind == "quest" and deck[i].entry == e:
			index = i
			draft = e.party.duplicate()
			e.party = []
			e.state = "open"
	queue_refresh()


## Tray tap on a quest card: add / remove from the party.
func toggle_draft(c: GuildCharacter) -> void:
	var cur := current()
	if cur.kind != "quest":
		open_character(c)
		return
	var n := slot_count(cur.entry)
	if draft.has(c):
		draft.erase(c)
	elif n == 1:
		draft = [c]
	elif draft.size() < n:
		draft.append(c)
	else:
		toast("Party is full. Tap someone on the card to remove them.")
	queue_refresh()


func upgrade(building: int) -> void:
	if GuildUpgrades.try_upgrade(building):
		toast("%s upgraded to level %d!" % [GuildUpgrades.get_building_name(building), GuildUpgrades.get_level(building)])
	queue_refresh()


## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the summary.
func end_day() -> void:
	if outstanding() > 0:
		_go_to_first_open()
		queue_refresh()
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


func start_new_day() -> void:
	last_report = report.duplicate()
	last_report.live = false
	report = {}
	GameState.start_new_day()
	toast("Day %d. The Bone Drake is attacking!" % GameState.day if GameState.day == MILESTONE_DAY else "Day %d begins" % GameState.day)
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


func open_sheet(kind: String) -> void:
	sheet = {"kind": kind}
	queue_refresh()


func open_character(c: GuildCharacter) -> void:
	sheet = {"kind": "character", "character": c}
	queue_refresh()


func close_sheet() -> void:
	sheet = {}
	queue_refresh()


# ================================================================ refresh

func queue_refresh() -> void:
	if _dirty:
		return
	_dirty = true
	refresh.call_deferred()


func refresh() -> void:
	_dirty = false
	%DayValue.text = str(GameState.day)
	%GoldValue.text = str(GameState.gold)
	%StandingValue.text = str(GameState.standing)
	_refresh_progress()
	_refresh_card()
	_refresh_actions()
	_refresh_tray()

	var kind: String = sheet.get("kind", "")
	_report.visible = not report.is_empty()
	for k in _sheets:
		_sheets[k].visible = not _report.visible and k == kind
	if _report.visible:
		_report.refresh()
	elif _sheets.has(kind):
		_sheets[kind].refresh()
	_overlay.mouse_filter = MOUSE_FILTER_STOP if _report.visible or _sheets.has(kind) else MOUSE_FILTER_IGNORE


func _refresh_progress() -> void:
	var c := current()
	var qi := entries.find(c.entry) if c.kind == "quest" else -1
	%ProgressLabel.text = "Recruits" if c.kind == "hire" else ("Quest %d of %d" % [qi + 1, entries.size()] if c.kind == "quest" else "End of day")
	S.clear(%Dots)
	for i in deck.size():
		var d: Dictionary = deck[i]
		var col := S.BOX_ALT
		if d.kind == "quest":
			col = {"open": S.BOX_ALT, "ready": S.GOOD, "denied": S.BAD}[d.entry.state]
		elif i < index:
			col = S.INK_SOFT
		S.add_row(%Dots, ProgressDot).setup(S.INFO if i == index else col, i == index)


# ---------------------------------------------------------------- the card + swiping

func _refresh_card() -> void:
	_dragging = false
	var kind: String = current().kind
	for k in _faces:
		_faces[k].visible = k == kind
	_faces[kind].refresh()
	_layout_card()


func _layout_card() -> void:
	var r := Rect2(Vector2(16, 12), _stage.size - Vector2(32, 18))
	_card.position = r.position
	_card.size = r.size
	_card.pivot_offset = Vector2(r.size.x / 2, r.size.y * 1.2)
	_card.rotation = 0.0
	_swipe_hint.position = Vector2(0, 30)
	_swipe_hint.size = Vector2(_stage.size.x, 60)
	_swipe_hint.modulate.a = 0.0


func _home_x() -> float:
	return 16.0


func _on_card_input(ev: InputEvent) -> void:
	if current().kind == "end":
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_dragging = true
			_drag_from = ev.global_position
		elif _dragging:
			_dragging = false
			var dx := _card.position.x - _home_x()
			if absf(dx) >= SWIPE_DISTANCE and can_swipe(signi(int(dx))):
				_fly_off(signi(int(dx)))
			else:
				if absf(dx) >= SWIPE_DISTANCE:
					_nudge()
				_spring_back()
	elif ev is InputEventMouseMotion and _dragging:
		var dx: float = ev.global_position.x - _drag_from.x
		_card.position.x = _home_x() + dx
		_card.rotation = dx * 0.0006
		_update_hint(dx)


func _update_hint(dx: float) -> void:
	var dir := signi(int(dx))
	var c := current()
	var words: Array = {"hire": ["HIRE", "PASS"], "quest": ["SEND", "DENY"]}.get(c.kind, ["", ""])
	var allowed := can_swipe(dir)
	_swipe_hint.text = (words[0] if dir > 0 else words[1]) if allowed else ("Add adventurers first" if c.kind == "quest" else "Guild full")
	_swipe_hint.add_theme_color_override("font_color", (S.GOOD if dir > 0 else S.BAD) if allowed else S.WARN)
	_swipe_hint.modulate.a = clampf(absf(dx) / SWIPE_DISTANCE, 0.0, 1.0)


func _spring_back() -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "position:x", _home_x(), 0.25)
	tw.tween_property(_card, "rotation", 0.0, 0.25)
	tw.tween_property(_swipe_hint, "modulate:a", 0.0, 0.2)


func _fly_off(dir: int) -> void:
	_update_hint(dir * SWIPE_DISTANCE)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_card, "position:x", _home_x() + dir * (size.x + 200), 0.22)
	tw.tween_property(_card, "rotation", dir * 0.35, 0.22)
	tw.chain().tween_callback(swipe.bind(dir))


## Buttons use the same animation as a swipe.
func press_swipe(dir: int) -> void:
	if not can_swipe(dir):
		_nudge()
		return
	_fly_off(dir)


func _nudge() -> void:
	var c := current()
	if c.kind == "quest":
		toast("Tap adventurers in the tray below to add them first" if not CharacterContainer.active_characters.is_empty() else "No adventurers yet. Go Back to the recruits, or deny.")
	elif c.kind == "hire":
		toast("Your guild is full. Upgrade the Barracks for more room.")


func _refresh_actions() -> void:
	var c := current()
	%BackButton.disabled = index == 0
	var choice: bool = c.kind != "end"
	%NoButton.visible = choice
	%YesButton.visible = choice
	if not choice:
		return
	var words: Array = {"hire": ["Pass", "Hire"], "quest": ["Deny", "Send party"]}[c.kind]
	%NoButton.text = "<  " + words[0]
	%YesButton.text = words[1] + "  >"
	%YesButton.disabled = not can_swipe(1)
	S.style_button(%YesButton, "green" if can_swipe(1) else "")


# ---------------------------------------------------------------- roster tray

func _refresh_tray() -> void:
	var roster: Array = CharacterContainer.active_characters
	var c := current()
	var hint := "tap to add to this quest" if c.kind == "quest" and not roster.is_empty() else "tap for details"
	%TrayLabel.text = "Your guild %d/%d  ·  %s" % [roster.size(), CharacterContainer.max_characters, hint]
	%TrayEmpty.visible = roster.is_empty()
	for t in %TrayList.get_children():
		if t != %TrayEmpty:
			%TrayList.remove_child(t)
			t.queue_free()
	for ch in roster:
		S.add_row(%TrayList, TrayTile).setup(self, ch)


func toast(text: String) -> void:
	%ToastLabel.text = text
	# over the top edge of the card
	_toast.offset_top = _stage.get_global_rect().position.y - global_position.y + 4
	_toast.offset_bottom = _toast.offset_top
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)
