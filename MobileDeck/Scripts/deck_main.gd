## Mobile Deck: a phone-first UI for the guild game built as a swipeable card deck.
## Scene: MobileDeck/deck_main.tscn
##
## Each day is a stack of cards:
##   recruit cards   -> swipe right to hire, left to pass
##   quest cards     -> tap adventurers in the bottom tray to add them, then
##                      swipe right to send the party, left to deny the quest
##   end-of-day card -> today's plan, upgrades, End Day
## Every swipe also has a button under the card. Back undoes the last card.
##
## This script owns the day's state, every game action and the swipe handling.
## The card faces, sheets and report call the ACTIONS below and read the
## QUERIES; after any change this script calls refresh() on whatever is showing.
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Nothing in those scripts is changed.
##
## Sections: SETTINGS · TEXT · STATE · NODES · SETUP · QUERIES · ACTIONS ·
##           SWIPING · REFRESH · TOAST
extends Control

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")
const ProgressDot := preload("res://MobileDeck/Scenes/Rows/progress_dot.tscn")
const TrayTile := preload("res://MobileDeck/Scenes/Rows/tray_tile.tscn")


# ============================================================ SETTINGS

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10
## How far (px) a card must be dragged to count as a swipe.
const SWIPE_DISTANCE := 170.0
## How much the card tilts while dragged (radians per px).
const DRAG_TILT := 0.0006
## Gap between the card and the edges of its stage.
const CARD_MARGIN := Vector2(16, 12)
## Seconds a toast stays up before fading.
const TOAST_SECONDS := 2.0


# ============================================================ TEXT

const TEXT_PROGRESS_RECRUITS := "Recruits"
const TEXT_PROGRESS_QUEST := "Quest %d of %d"
const TEXT_PROGRESS_END := "End of day"
## Button words under each card kind: [left, right].
const BUTTON_WORDS := {"hire": ["Pass", "Hire"], "quest": ["Deny", "Send party"]}
## Stamp shown while dragging: [right, left].
const STAMP_WORDS := {"hire": ["HIRE", "PASS"], "quest": ["SEND", "DENY"]}
const STAMP_NEED_PARTY := "Add adventurers first"
const STAMP_GUILD_FULL := "Guild full"
const TEXT_TRAY := "Your guild %d/%d  ·  %s"
const TEXT_TRAY_HINT_QUEST := "tap to add to this quest"
const TEXT_TRAY_HINT_OTHER := "tap for details"
const TOAST_HIRED := "%s joined the guild!"
const TOAST_SENT := "Party sent to %s"
const TOAST_DENIED := "Denied: %s"
const TOAST_PARTY_FULL := "Party is full. Tap someone on the card to remove them."
const TOAST_NEED_PARTY := "Tap adventurers in the tray below to add them first"
const TOAST_NO_ADVENTURERS := "No adventurers yet. Go Back to the recruits, or deny."
const TOAST_GUILD_FULL := "Your guild is full. Upgrade the Barracks for more room."
const TOAST_UPGRADED := "%s upgraded to level %d!"
const TOAST_NEW_DAY := "Day %d begins"
const TOAST_MILESTONE_DAY := "Day %d. The Bone Drake is attacking!"


# ============================================================ STATE

## Today's quests. Each entry:
##   {quest: CreatedQuest, state: "open" | "ready" | "denied", party: Array, milestone: bool}
var entries: Array = []
## Today's cards, in order:
##   {kind: "hire", character} | {kind: "quest", entry} | {kind: "end"}
var deck: Array = []
## The card on top.
var index := 0
## Party being built on the current quest card.
var draft: Array = []
## Sheet over everything:
##   {} | {kind: "upgrades"} | {kind: "character", character} | {kind: "intro"}
var sheet := {"kind": "intro"}
## Day report being shown: {live: bool, day: int, results: Array}. Empty = hidden.
var report := {}
## Yesterday's report, readable again from the end-of-day card.
var last_report := {}

var _refresh_queued := false
var _drag_from := Vector2.ZERO
var _dragging := false
var _toast_tween: Tween


# ============================================================ NODES

@onready var _day_value: Label = %DayValue
@onready var _gold_value: Label = %GoldValue
@onready var _standing_value: Label = %StandingValue
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _help_button: Button = %HelpButton
@onready var _progress_label: Label = %ProgressLabel
@onready var _dots: Container = %Dots
@onready var _stage: Control = %Stage
@onready var _card: PanelContainer = %Card
@onready var _faces := {"hire": %CardHire, "quest": %CardQuest, "end": %CardEnd}
@onready var _swipe_stamp: Label = %SwipeHint
@onready var _no_button: Button = %NoButton
@onready var _back_button: Button = %BackButton
@onready var _yes_button: Button = %YesButton
@onready var _tray_label: Label = %TrayLabel
@onready var _tray_list: Container = %TrayList
@onready var _tray_empty: Control = %TrayEmpty
@onready var _overlay: Control = %Overlay
@onready var _sheets := {"upgrades": %SheetUpgrades, "character": %SheetCharacter, "intro": %SheetIntro}
@onready var _report: Control = %OverlayReport
@onready var _toast: PanelContainer = %Toast
@onready var _toast_label: Label = %ToastLabel


# ============================================================ SETUP

func _ready() -> void:
	_upgrades_button.pressed.connect(open_sheet.bind("upgrades"))
	_help_button.pressed.connect(open_sheet.bind("intro"))
	_back_button.pressed.connect(back)
	_no_button.pressed.connect(press_swipe.bind(-1))
	_yes_button.pressed.connect(press_swipe.bind(1))
	_stage.resized.connect(_layout_card)
	_card.gui_input.connect(_on_card_input)
	for screen in [_faces.hire, _faces.quest, _faces.end, _sheets.upgrades, _sheets.character, _sheets.intro, _report]:
		screen.setup(self)
	_toast.visible = false

	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)

	_deal_new_day()
	refresh()


func _on_day_started(_day: int) -> void:
	_deal_new_day()
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


## Today's deck: recruits (if there's room), then quests, then the end card.
func _deal_new_day() -> void:
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


# ============================================================ QUERIES

## The card on top.
func current() -> Dictionary:
	return deck[clampi(index, 0, deck.size() - 1)]


## Free places in the guild.
func room() -> int:
	return CharacterContainer.max_characters - CharacterContainer.active_characters.size()


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


## dir: +1 = right (hire / send), -1 = left (pass / deny).
func can_swipe(dir: int) -> bool:
	match current().kind:
		"hire":
			return dir < 0 or room() > 0
		"quest":
			return dir < 0 or not draft.is_empty()
	return false


# ============================================================ ACTIONS

# ---- cards

## Decide the top card. dir: +1 = hire / send, -1 = pass / deny.
func swipe(dir: int) -> void:
	if not can_swipe(dir):
		_nudge()
		return
	var c := current()
	match c.kind:
		"hire":
			if dir > 0 and CharacterContainer.add_character_to_guild(c.character):
				toast(TOAST_HIRED % c.character.name)
		"quest":
			if dir > 0:
				_send_draft_to(c.entry)
			else:
				_deny(c.entry)
	index += 1
	draft = []
	_skip_dead_cards()
	# a quest whose party got moved elsewhere comes back undecided: send the player to it
	if current().kind == "end" and outstanding() > 0:
		_go_to_first_open()
	_load_draft()
	queue_refresh()


## A character can only be on one quest (CharacterSlot.assign), so they leave
## any other party first.
func _send_draft_to(e: Dictionary) -> void:
	for other in entries:
		if other == e:
			continue
		other.party = other.party.filter(func(x): return not draft.has(x))
		if other.state == "ready" and other.party.is_empty():
			other.state = "open"
	e.party = draft.duplicate()
	e.state = "ready"
	toast(TOAST_SENT % e.quest.questTitle)


func _deny(e: Dictionary) -> void:
	e.party = []
	e.state = "denied"
	toast(TOAST_DENIED % e.quest.questTitle)


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
		_reopen(c.entry)
	queue_refresh()


## End-of-day card: tap a quest to go back to it and decide again.
func jump_to_entry(e: Dictionary) -> void:
	for i in deck.size():
		if deck[i].kind == "quest" and deck[i].entry == e:
			index = i
			_reopen(e)
	queue_refresh()


## Put a quest's party back in the draft and mark it undecided.
func _reopen(e: Dictionary) -> void:
	draft = e.party.duplicate()
	e.party = []
	e.state = "open"


## Recruit cards stop mattering once the guild is full (or they've been hired).
func _skip_dead_cards() -> void:
	while index < deck.size() - 1 and deck[index].kind == "hire" \
			and (room() <= 0 or not CharacterContainer.hireable_characters.has(deck[index].character)):
		index += 1


func _go_to_first_open() -> void:
	for i in deck.size():
		if deck[i].kind == "quest" and deck[i].entry.state == "open":
			index = i
			return


func _load_draft() -> void:
	var c := current()
	draft = c.entry.party.duplicate() if c.kind == "quest" else []


## Tray tap. On a quest card: add / remove from the party. Otherwise: details.
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
		toast(TOAST_PARTY_FULL)
	queue_refresh()


# ---- guild

func upgrade(building: int) -> void:
	if GuildUpgrades.try_upgrade(building):
		toast(TOAST_UPGRADED % [GuildUpgrades.get_building_name(building), GuildUpgrades.get_level(building)])
	queue_refresh()


# ---- sheets

func open_sheet(kind: String) -> void:
	sheet = {"kind": kind}
	queue_refresh()


func open_character(c: GuildCharacter) -> void:
	sheet = {"kind": "character", "character": c}
	queue_refresh()


func close_sheet() -> void:
	sheet = {}
	queue_refresh()


# ---- end of day

## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the report.
func end_day() -> void:
	if outstanding() > 0:
		_go_to_first_open()
		queue_refresh()
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


# ============================================================ SWIPING

## Buttons under the card use the same fly-off animation as a swipe.
func press_swipe(dir: int) -> void:
	if not can_swipe(dir):
		_nudge()
		return
	_fly_off(dir)


func _on_card_input(ev: InputEvent) -> void:
	if current().kind == "end":
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_dragging = true
			_drag_from = ev.global_position
		elif _dragging:
			_dragging = false
			_on_release()
	elif ev is InputEventMouseMotion and _dragging:
		var dx: float = ev.global_position.x - _drag_from.x
		_card.position.x = CARD_MARGIN.x + dx
		_card.rotation = dx * DRAG_TILT
		_show_stamp(dx)


## Let go: far enough and allowed = swipe; otherwise spring back (and say why).
func _on_release() -> void:
	var dx := _card.position.x - CARD_MARGIN.x
	var dir := signi(int(dx))
	if absf(dx) >= SWIPE_DISTANCE and can_swipe(dir):
		_fly_off(dir)
		return
	if absf(dx) >= SWIPE_DISTANCE:
		_nudge()
	_spring_back()


## The big HIRE / PASS / SEND / DENY stamp, fading in as the card is dragged.
func _show_stamp(dx: float) -> void:
	var dir := signi(int(dx))
	var kind: String = current().kind
	var words: Array = STAMP_WORDS.get(kind, ["", ""])
	if can_swipe(dir):
		_swipe_stamp.text = words[0] if dir > 0 else words[1]
		S.color(_swipe_stamp, S.GOOD if dir > 0 else S.BAD)
	else:
		_swipe_stamp.text = STAMP_NEED_PARTY if kind == "quest" else STAMP_GUILD_FULL
		S.color(_swipe_stamp, S.WARN)
	_swipe_stamp.modulate.a = clampf(absf(dx) / SWIPE_DISTANCE, 0.0, 1.0)


func _spring_back() -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "position:x", CARD_MARGIN.x, 0.25)
	tw.tween_property(_card, "rotation", 0.0, 0.25)
	tw.tween_property(_swipe_stamp, "modulate:a", 0.0, 0.2)


func _fly_off(dir: int) -> void:
	_show_stamp(dir * SWIPE_DISTANCE)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_card, "position:x", CARD_MARGIN.x + dir * (size.x + 200), 0.22)
	tw.tween_property(_card, "rotation", dir * 0.35, 0.22)
	tw.chain().tween_callback(swipe.bind(dir))


## Explain why a right swipe isn't allowed.
func _nudge() -> void:
	match current().kind:
		"quest":
			toast(TOAST_NEED_PARTY if not CharacterContainer.active_characters.is_empty() else TOAST_NO_ADVENTURERS)
		"hire":
			toast(TOAST_GUILD_FULL)


## Put the card back in the middle of the stage, flat, with the stamp hidden.
func _layout_card() -> void:
	var r := Rect2(CARD_MARGIN, _stage.size - Vector2(CARD_MARGIN.x * 2, CARD_MARGIN.y + 6))
	_card.position = r.position
	_card.size = r.size
	_card.pivot_offset = Vector2(r.size.x / 2, r.size.y * 1.2)
	_card.rotation = 0.0
	_swipe_stamp.position = Vector2(0, 30)
	_swipe_stamp.size = Vector2(_stage.size.x, 60)
	_swipe_stamp.modulate.a = 0.0


# ============================================================ REFRESH

## Ask for a refresh at the end of this frame (many changes = one refresh).
func queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	refresh.call_deferred()


func refresh() -> void:
	_refresh_queued = false
	_day_value.text = str(GameState.day)
	_gold_value.text = str(GameState.gold)
	_standing_value.text = str(GameState.standing)
	_refresh_progress()
	_refresh_card()
	_refresh_buttons()
	_refresh_tray()
	_refresh_overlays()


## "Quest 2 of 5" and one dot per card: green = sent, red = denied, blue = current.
func _refresh_progress() -> void:
	var c := current()
	match c.kind:
		"hire":
			_progress_label.text = TEXT_PROGRESS_RECRUITS
		"quest":
			_progress_label.text = TEXT_PROGRESS_QUEST % [entries.find(c.entry) + 1, entries.size()]
		_:
			_progress_label.text = TEXT_PROGRESS_END
	S.clear(_dots)
	for i in deck.size():
		S.add_row(_dots, ProgressDot).setup(S.INFO if i == index else _dot_color(i), i == index)


func _dot_color(i: int) -> Color:
	var d: Dictionary = deck[i]
	if d.kind == "quest":
		return {"open": S.BOX_ALT, "ready": S.GOOD, "denied": S.BAD}[d.entry.state]
	return S.INK_SOFT if i < index else S.BOX_ALT


func _refresh_card() -> void:
	_dragging = false
	var kind: String = current().kind
	for k in _faces:
		_faces[k].visible = k == kind
	_faces[kind].refresh()
	_layout_card()


## Left / Back / Right under the card (just Back on the end card).
func _refresh_buttons() -> void:
	var kind: String = current().kind
	_back_button.disabled = index == 0
	_no_button.visible = kind != "end"
	_yes_button.visible = kind != "end"
	if kind == "end":
		return
	_no_button.text = "<  " + BUTTON_WORDS[kind][0]
	_yes_button.text = BUTTON_WORDS[kind][1] + "  >"
	_yes_button.disabled = not can_swipe(1)
	S.style_button(_yes_button, "green" if can_swipe(1) else "")


## The roster along the bottom.
func _refresh_tray() -> void:
	var roster: Array = CharacterContainer.active_characters
	var hint := TEXT_TRAY_HINT_QUEST if current().kind == "quest" and not roster.is_empty() else TEXT_TRAY_HINT_OTHER
	_tray_label.text = TEXT_TRAY % [roster.size(), CharacterContainer.max_characters, hint]
	_tray_empty.visible = roster.is_empty()
	for tile in _tray_list.get_children():
		if tile != _tray_empty:
			_tray_list.remove_child(tile)
			tile.queue_free()
	for c in roster:
		S.add_row(_tray_list, TrayTile).setup(self, c)


## The report wins over sheets; sheets cover the deck.
func _refresh_overlays() -> void:
	var kind: String = sheet.get("kind", "")
	_report.visible = not report.is_empty()
	for k in _sheets:
		_sheets[k].visible = not _report.visible and k == kind
	if _report.visible:
		_report.refresh()
	elif _sheets.has(kind):
		_sheets[kind].refresh()
	_overlay.mouse_filter = MOUSE_FILTER_STOP if _report.visible or _sheets.has(kind) else MOUSE_FILTER_IGNORE


# ============================================================ TOAST

## Short message over the top edge of the card that fades out.
func toast(text: String) -> void:
	_toast_label.text = text
	_toast.offset_top = _stage.get_global_rect().position.y - global_position.y + 4
	_toast.offset_bottom = _toast.offset_top
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)
