## Mobile Deck: a phone-first UI for the guild game built as a swipeable card deck.
##
## Each day is a stack of cards:
##   recruit cards  -> swipe right to hire, left to pass
##   quest cards    -> tap adventurers in the bottom tray to add them, then
##                     swipe right to send the party, left to deny the quest
##   end-of-day card -> today's plan, upgrades, End Day
## Every swipe also has a button under the card. Back undoes the last card.
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Nothing in those scripts is changed.
extends Control

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")
const Cards := preload("res://MobileDeck/Scripts/deck_cards.gd")
const Sheets := preload("res://MobileDeck/Scripts/deck_sheets.gd")
const OverlayReport := preload("res://MobileDeck/Scripts/overlay_report.gd")

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

var _stat_labels := {}
var _progress: HBoxContainer
var _stage: Control
var _actions: HBoxContainer
var _tray: PanelContainer
var _overlay: Control
var _toast: PanelContainer
var _dirty := false
var _card: Control
var _drag_from := Vector2.ZERO
var _dragging := false
var _swipe_hint: Label


func _ready() -> void:
	theme = S.make_theme()
	_build_shell()
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

	# header
	var head := S.panel("bar", Vector4(16, 10, 12, 10))
	var hh := S.hbox(18)
	head.add_child(hh)
	for c in [["sun", "day", "Day", S.INK], ["coins", "gold", "", S.GOLD], ["rook", "standing", "", S.INK]]:
		var cell := S.hbox(6)
		cell.add_child(S.icon(c[0], 32, c[3]))
		if c[2] != "":
			cell.add_child(S.label(c[2], 22, S.INK_SOFT))
		var num := S.label("0", 24, c[3])
		cell.add_child(num)
		hh.add_child(cell)
		_stat_labels[c[1]] = num
	hh.add_child(S.spacer())
	var up := S.button("Upgrades", "", 20, 48)
	up.pressed.connect(open_sheet.bind("upgrades"))
	hh.add_child(up)
	var help := S.button("?", "", 20, 48)
	help.custom_minimum_size.x = 48
	help.pressed.connect(open_sheet.bind("intro"))
	hh.add_child(help)
	col.add_child(head)

	# progress through today's deck
	_progress = S.hbox(6)
	col.add_child(S.margin(_progress, 16, 10, 16, 0))

	# card stage
	_stage = Control.new()
	_stage.size_flags_vertical = SIZE_EXPAND_FILL
	_stage.resized.connect(_layout_card)
	col.add_child(_stage)

	# buttons under the card
	_actions = S.hbox(12)
	col.add_child(S.margin(_actions, 16, 6, 16, 10))

	# roster tray
	_tray = S.panel("bar", Vector4(12, 8, 12, 10))
	col.add_child(_tray)

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
	_build_progress()
	_build_card()
	_build_actions()
	_build_tray()

	S.clear(_overlay)
	_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	var o: Control = null
	if not report.is_empty():
		o = OverlayReport.build(self)
	elif not sheet.is_empty():
		o = Sheets.build(self)
	if o:
		_overlay.add_child(o)
		_overlay.mouse_filter = MOUSE_FILTER_STOP


func _build_progress() -> void:
	S.clear(_progress)
	var c := current()
	var quests := entries.size()
	var qi := entries.find(c.entry) if c.kind == "quest" else -1
	var txt := "Recruits" if c.kind == "hire" else ("Quest %d of %d" % [qi + 1, quests] if c.kind == "quest" else "End of day")
	_progress.add_child(S.label(txt, 22, S.INK_SOFT))
	_progress.add_child(S.spacer())
	for i in deck.size():
		var d: Dictionary = deck[i]
		var col := S.BOX_ALT
		if d.kind == "quest":
			col = {"open": S.BOX_ALT, "ready": S.GOOD, "denied": S.BAD}[d.entry.state]
		elif i < index:
			col = S.INK_SOFT
		var dot := Panel.new()
		var sz := 16 if i == index else 10
		dot.custom_minimum_size = Vector2(sz, sz)
		dot.size_flags_vertical = SIZE_SHRINK_CENTER
		dot.add_theme_stylebox_override("panel", S.flat(S.INFO if i == index else col, sz, 0))
		_progress.add_child(dot)


# ---------------------------------------------------------------- the card + swiping

func _build_card() -> void:
	S.clear(_stage)
	_dragging = false
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", S.flat(S.BOX, 26, 1, S.LINE, Vector4(26, 22, 26, 22)))
	card.mouse_filter = MOUSE_FILTER_STOP
	card.add_child(Cards.build(self))
	_stage.add_child(card)
	_card = card
	# stamp shown while dragging
	_swipe_hint = S.label("", 40, S.GOOD)
	_swipe_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_swipe_hint.mouse_filter = MOUSE_FILTER_IGNORE
	_swipe_hint.modulate.a = 0.0
	_stage.add_child(_swipe_hint)
	_layout_card.call_deferred()
	if current().kind != "end":
		card.gui_input.connect(_on_card_input)


func _layout_card() -> void:
	if not is_instance_valid(_card):
		return
	var r := Rect2(Vector2(16, 12), _stage.size - Vector2(32, 18))
	_card.position = r.position
	_card.size = r.size
	_card.pivot_offset = Vector2(r.size.x / 2, r.size.y * 1.2)
	_card.rotation = 0.0
	_swipe_hint.position = Vector2(0, 30)
	_swipe_hint.size = Vector2(_stage.size.x, 60)


func _home_x() -> float:
	return 16.0


func _on_card_input(ev: InputEvent) -> void:
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


func _build_actions() -> void:
	S.clear(_actions)
	var c := current()
	var bk := S.button("Back", "", 22, 60)
	bk.disabled = index == 0
	bk.custom_minimum_size.x = 120
	bk.pressed.connect(back)
	if c.kind == "end":
		_actions.add_child(bk)
		return
	var words: Array = {"hire": ["Pass", "Hire"], "quest": ["Deny", "Send party"]}[c.kind]
	var no := S.button("<  " + words[0], "red", 24, 64)
	no.size_flags_horizontal = SIZE_EXPAND_FILL
	no.pressed.connect(press_swipe.bind(-1))
	var yes := S.button(words[1] + "  >", "green" if can_swipe(1) else "", 24, 64)
	yes.size_flags_horizontal = SIZE_EXPAND_FILL
	yes.disabled = not can_swipe(1)
	yes.pressed.connect(press_swipe.bind(1))
	_actions.add_child(no)
	_actions.add_child(bk)
	_actions.add_child(yes)


# ---------------------------------------------------------------- roster tray

func _build_tray() -> void:
	S.clear(_tray)
	var v := S.vbox(6)
	_tray.add_child(v)
	var roster: Array = CharacterContainer.active_characters
	var c := current()
	var hint := "tap to add to this quest" if c.kind == "quest" and not roster.is_empty() else "tap for details"
	v.add_child(S.label("Your guild %d/%d  ·  %s" % [roster.size(), CharacterContainer.max_characters, hint], 18, S.INK_SOFT))
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.y = 128
	v.add_child(sc)
	var h := S.hbox(10)
	sc.add_child(h)
	if roster.is_empty():
		h.add_child(S.label("Nobody yet. Swipe right on a recruit to hire them.", 20, S.INK_SOFT))
	for ch in roster:
		h.add_child(_tray_tile(ch, c))


func _tray_tile(ch: GuildCharacter, cur: Dictionary) -> Control:
	var chosen := draft.has(ch)
	var busy: Dictionary = entry_of(ch)
	var b := Button.new()
	b.focus_mode = FOCUS_NONE
	b.custom_minimum_size = Vector2(104, 124)
	var sb := S.flat(S.INFO_BG if chosen else S.BOX, 16, 2 if chosen else 1, S.INFO if chosen else S.LINE, Vector4(6, 6, 6, 6))
	sb.set_border_width_all(3 if chosen else 1)
	for s in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var v := S.vbox(2)
	v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	v.offset_left = 6
	v.offset_right = -6
	v.offset_top = 6
	v.mouse_filter = MOUSE_FILTER_IGNORE
	var p := S.portrait(ch, 64)
	v.add_child(p)
	var n := S.label(ch.name, 18)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(n)
	var inj: Array = S.INJURY[clampi(ch.injury_level, 0, 4)]
	var status := S.label(inj[0] if busy.is_empty() or chosen else "On a quest", 14, inj[2] if busy.is_empty() or chosen else S.INFO)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(status)
	for x in v.get_children():
		if x is Control:
			x.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(v)
	b.pressed.connect(toggle_draft.bind(ch))
	return b


func toast(text: String) -> void:
	if _toast and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", S.flat(Color("#000000CC"), 14, 0, S.INK, Vector4(16, 10, 16, 10)))
	var l := S.wrap(S.label(text, 22, S.WHITE))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(l)
	_toast.mouse_filter = MOUSE_FILTER_IGNORE
	# over the top edge of the card (the stage itself is rebuilt on refresh)
	_toast.set_anchors_preset(PRESET_TOP_WIDE)
	_toast.offset_left = 40
	_toast.offset_right = -40
	_toast.offset_top = _stage.get_global_rect().position.y - global_position.y + 4
	add_child(_toast)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_toast.queue_free)
