## Mobile Hall: a phone-first UI for the guild game, built from the
## playtest feedback on the Deck, Flow and Ledger prototypes.
## Scene: MobileHall/hall_main.tscn
##
## Shell, top to bottom:
##   header      - day, Bone Drake countdown, gold, standing, menu button
##   content     - one of three tabs (Board, Guild, Upgrades), or a screen
##                 over them (Assign Party, Character)
##   action bar  - one big "what to do next" button (hidden on Assign Party,
##                 which has its own Deny / Send buttons there)
##   nav         - Board / Guild / Upgrades with badges, always visible
## Overlays over everything: End Day check, Day Report, Welcome, Menu.
##
## What the feedback asked for, and where it lives:
##   - every quest on one screen to compare        -> Board tab
##   - stats visible while picking a party         -> Assign Party picker rows
##   - parties kept without sending them           -> entry.party is a draft
##   - switch quests without losing your picks     -> quest strip on Assign Party
##   - one obvious next step                       -> action bar
##   - upgrades part of the loop                   -> Upgrades badge, Board
##                                                    checklist, End Day check
##   - denied quests can come back                 -> "Reconsider"
##   - new recruits noticed                        -> Guild badge each morning
##   - big buttons, little scrolling, short report -> everywhere / Day Report
##
## This script owns the day's state and every game action. Screens call the
## ACTIONS below and read the QUERIES; after any change this script calls
## refresh() on whatever is showing.
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Nothing in those scripts is changed.
##
## Sections: SETTINGS · TEXT · STATE · NODES · SETUP · QUERIES · ACTIONS ·
##           REFRESH · TOAST
extends Control

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")

# ============================================================ SETTINGS

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10
## Bottom tabs, left to right (ids match the Tab_<id> buttons in the scene).
const TABS := ["board", "guild", "upgrades"]
## Seconds a toast stays up before fading.
const TOAST_SECONDS := 2.2

# ============================================================ TEXT

const HEADER_DAY := "Day %d"
const HEADER_DRAKE := "Bone Drake in %d %s"
const HEADER_DRAKE_TODAY := "The Bone Drake attacks today!"
const HEADER_DRAKE_GONE := "The Bone Drake has come and gone"
## Countdown colour in the last two days (light red, readable on the dark header).
const DRAKE_WARNING := Color("#FF8A80")
## Nav tab that isn't open.
const NAV_IDLE := Color("#555A61")

const ACTION_HIRE := "Hire your first adventurer"
const ACTION_HIRE_HINT := "You need someone to send on quests"
const ACTION_HIRE_BUTTON := "For Hire"
const ACTION_DECIDE := "%s to decide"
const ACTION_DECIDE_HINT := "Next: %s"
const ACTION_DECIDE_BUTTON := "Next Quest"
const ACTION_END := "Ready to end Day %d"
const ACTION_END_HINT := "%s going out tonight"
const ACTION_END_HINT_NONE := "No parties going out tonight"
const ACTION_END_BUTTON := "End Day"

const TOAST_SENT := "Party sent: %s"
const TOAST_DENIED := "Denied: %s"
const TOAST_RECALLED := "Party recalled. Your picks are kept."
const TOAST_RECONSIDER := "Back on the board: %s"
const TOAST_MOVED := "%s moved from %s"
const TOAST_FULL := "Party is full. Tap someone in it to swap them out."
const TOAST_DEAD := "%s can't go on quests anymore."
const TOAST_HIRED := "%s joined the guild!"
const TOAST_ROSTER_FULL := "No room. Upgrade the Barracks for more beds."
const TOAST_UPGRADED := "%s upgraded to level %d!"
const TOAST_RESET := "Upgrades reset"
const TOAST_NEW_DAY := "Day %d · %s · %s for hire"
const TOAST_MILESTONE_DAY := "Day %d. The Bone Drake is attacking!"

# ============================================================ STATE

## Which bottom tab is showing, and which half of the Guild tab ("roster" | "hire").
var tab := "board"
var guild_seg := "roster"
## Today's quests. Each entry:
##   {quest: CreatedQuest, state: "open" | "ready" | "denied", party: Array, milestone: bool}
## An "open" quest's party is a draft: it is kept until sent, recalled or changed.
var entries: Array = []
## Screen over the tabs:
##   {} | {kind: "assign", index: int} | {kind: "character", character, back: Dictionary}
var screen := { }
## Overlays. report = {live: bool, day: int, results: Array}; empty = hidden.
var report := { }
var last_report := { }
var show_end_check := false
var show_welcome := true
var show_menu := false
## Assign Party: also list adventurers already in another quest's party
## (sent or picked). Off by default, so the list only shows who's free.
var show_busy := false
## The day the player last opened For Hire (the Guild badge clears then).
var hire_seen_day := 0

var _refresh_queued := false
var _last_view := ""
var _toast_tween: Tween

# ============================================================ NODES

@onready var _day_value: Label = %DayValue
@onready var _drake_value: Label = %DrakeValue
@onready var _gold_value: Label = %GoldValue
@onready var _standing_value: Label = %StandingValue
@onready var _menu_button: Button = %MenuButton
@onready var _tabs := { "board": %TabBoard, "guild": %TabGuild, "upgrades": %TabUpgrades }
@onready var _screens := { "assign": %ScreenAssign, "character": %ScreenCharacter }
@onready var _action_bar: Control = %ActionBar
@onready var _action_title: Label = %ActionTitle
@onready var _action_hint: Label = %ActionHint
@onready var _action_button: Button = %ActionButton
@onready var _end_check: Control = %OverlayEndDay
@onready var _report: Control = %OverlayReport
@onready var _welcome: Control = %OverlayWelcome
@onready var _menu: Control = %OverlayMenu
@onready var _toast: PanelContainer = %Toast
@onready var _toast_label: Label = %ToastLabel

# ============================================================ SETUP


func _ready() -> void:
	for t in TABS:
		_nav_button(t).pressed.connect(open_tab.bind(t))
	_menu_button.pressed.connect(open_menu)
	_action_button.pressed.connect(primary_action)
	for node in _tabs.values() + _screens.values() + [_end_check, _report, _welcome, _menu]:
		node.setup(self)
	_toast.visible = false

	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)

	_generate_quests()
	refresh()


func _on_day_started(_day: int) -> void:
	_generate_quests()
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
	return { "quest": quest, "state": "open", "party": [], "milestone": milestone }

# ============================================================ QUERIES


func roster() -> Array:
	return CharacterContainer.active_characters


func roster_full() -> bool:
	return roster().size() >= CharacterContainer.max_characters


func can_hire_anyone() -> bool:
	return not CharacterContainer.hireable_characters.is_empty() and not roster_full()


## Quests still needing Send or Deny. QuestCard.is_outstanding.
func outstanding() -> int:
	return entries.filter(func(e): return e.state == "open").size()


func decided() -> int:
	return entries.size() - outstanding()


func ready_entries() -> Array:
	return entries.filter(func(e): return e.state == "ready")


func denied_entries() -> Array:
	return entries.filter(func(e): return e.state == "denied")


## Index of the quest whose party (sent or draft) has this character, or -1.
func entry_index_of(c: GuildCharacter) -> int:
	for i in entries.size():
		if entries[i].party.has(c):
			return i
	return -1


## How many adventurers a quest takes.
func slot_count(entry: Dictionary) -> int:
	return QuestCard.get_slot_count(entry.quest)


## Success chance as the quest computes it (-1 = no party yet).
func chance_for(entry: Dictionary, party: Array) -> int:
	if party.is_empty():
		return -1
	return int(entry.quest.calcSuccessChance(party))


## How many points of success chance this character adds to a quest on their own.
func chance_added(entry: Dictionary, c: GuildCharacter) -> int:
	return int(entry.quest.calcSuccessChance([c]))


## The quest shown on Assign Party, or {}.
func current_entry() -> Dictionary:
	if screen.get("kind", "") != "assign" or entries.is_empty():
		return { }
	return entries[clampi(screen.index, 0, entries.size() - 1)]


## First undecided quest at or after `from` (wrapping around), or -1.
func next_open(from: int = 0) -> int:
	for k in entries.size():
		var i := (from + k) % entries.size()
		if entries[i].state == "open":
			return i
	return -1


## Buildings that can be upgraded right now.
func upgradable() -> Array:
	return S.buildings_in_order().filter(func(b): return GuildUpgrades.get_upgrade_status(b) == GuildUpgrades.UpgradeStatus.READY)


## Recruits the player hasn't looked at yet today.
func new_recruits() -> int:
	if hire_seen_day == GameState.day or roster_full():
		return 0
	return CharacterContainer.hireable_characters.size()


func days_to_drake() -> int:
	return MILESTONE_DAY - GameState.day

# ============================================================ ACTIONS

# ---- navigation


## Switch bottom tab. Closes any screen; drafts stay on their quests.
func open_tab(t: String, segment: String = "") -> void:
	tab = t
	if segment != "":
		guild_seg = segment
	if tab == "guild" and guild_seg == "hire":
		hire_seen_day = GameState.day
	screen = { }
	queue_refresh()


func set_guild_seg(segment: String) -> void:
	open_tab("guild", segment)


func open_assign(i: int) -> void:
	if entries.is_empty():
		return
	screen = { "kind": "assign", "index": clampi(i, 0, entries.size() - 1) }
	tab = "board"
	queue_refresh()


func open_character(c: GuildCharacter) -> void:
	screen = { "kind": "character", "character": c, "back": screen.duplicate() }
	queue_refresh()


## Character goes back to wherever it was opened from; Assign goes to the Board.
func close_screen() -> void:
	screen = screen.get("back", { }) if screen.get("kind", "") == "character" else { }
	queue_refresh()


## The action bar's button: always the next thing to do.
func primary_action() -> void:
	if roster().is_empty() and can_hire_anyone():
		open_tab("guild", "hire")
	elif outstanding() > 0:
		open_assign(next_open(0))
	else:
		open_end_check()


func open_menu() -> void:
	show_menu = true
	queue_refresh()


func close_menu() -> void:
	show_menu = false
	queue_refresh()


func open_welcome() -> void:
	show_menu = false
	show_welcome = true
	queue_refresh()


## The welcome card leads to the Board; the action bar then says what's next.
func close_welcome() -> void:
	show_welcome = false
	open_tab("board")

# ---- quests


## Assign Party: tap an adventurer to add or remove them. Someone already in
## another quest's party (sent or draft) moves over, so nobody is in two.
func toggle_pick(c: GuildCharacter) -> void:
	var e := current_entry()
	if e.is_empty() or e.state == "denied":
		return
	if e.party.has(c):
		e.party.erase(c)
		if e.party.is_empty() and e.state == "ready":
			e.state = "open"
		queue_refresh()
		return
	if S.is_dead(c):
		toast(TOAST_DEAD % c.name)
		return
	var n := slot_count(e)
	if e.party.size() >= n and n > 1:
		toast(TOAST_FULL)
		return
	if n == 1:
		e.party.clear()
	var from := entry_index_of(c)
	if from >= 0:
		var other: Dictionary = entries[from]
		other.party.erase(c)
		if other.party.is_empty() and other.state == "ready":
			other.state = "open"
		toast(TOAST_MOVED % [c.name, other.quest.questTitle])
	e.party.append(c)
	queue_refresh()


## Assign Party's "Show busy" toggle.
func set_show_busy(on: bool) -> void:
	show_busy = on
	queue_refresh()


## Send the party, then jump to the next undecided quest (or back to the Board).
func send_party() -> void:
	var e := current_entry()
	if e.is_empty() or e.party.is_empty():
		return
	e.state = "ready"
	toast(TOAST_SENT % e.quest.questTitle)
	_advance()


func deny_quest() -> void:
	var e := current_entry()
	if e.is_empty():
		return
	e.party.clear()
	e.state = "denied"
	GameState.reduce_standing(e.quest.difficulty)
	toast(TOAST_DENIED % e.quest.questTitle)
	_advance()


## Undo Send: the party goes back to being a draft.
func recall_party() -> void:
	var e := current_entry()
	if e.is_empty():
		return
	e.state = "open"
	toast(TOAST_RECALLED)
	queue_refresh()


## Undo Deny.
func reconsider() -> void:
	var e := current_entry()
	if e.is_empty():
		return
	e.state = "open"
	toast(TOAST_RECONSIDER % e.quest.questTitle)
	queue_refresh()


func _advance() -> void:
	var next := next_open(screen.index + 1)
	if next < 0:
		screen = { }
	else:
		screen.index = next
	queue_refresh()

# ---- guild


func hire(c: GuildCharacter) -> void:
	if roster_full():
		toast(TOAST_ROSTER_FULL)
	elif CharacterContainer.add_character_to_guild(c):
		toast(TOAST_HIRED % c.name)
	queue_refresh()


func upgrade(building: int) -> void:
	if GuildUpgrades.try_upgrade(building):
		toast(TOAST_UPGRADED % [GuildUpgrades.get_building_name(building), GuildUpgrades.get_level(building)])
	queue_refresh()


## Menu's debug button.
func reset_upgrades() -> void:
	GuildUpgrades.reset()
	show_menu = false
	toast(TOAST_RESET)

# ---- end of day


## The End Day check: tonight's plan and anything worth buying first.
func open_end_check() -> void:
	if outstanding() > 0:
		open_assign(next_open(0))
		return
	show_end_check = true
	queue_refresh()


func close_end_check() -> void:
	show_end_check = false
	queue_refresh()


## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the report.
func end_day() -> void:
	if outstanding() > 0:
		return
	var results := []
	for e in ready_entries():
		results.append(_run_quest(e))
	show_end_check = false
	screen = { }
	report = { "live": true, "day": GameState.day, "results": results }
	queue_refresh()


## Play out one quest with DayBar's helpers and pay its gold.
func _run_quest(e: Dictionary) -> Dictionary:
	var party: Array[GuildCharacter] = []
	party.assign(e.party)
	var before := { }
	for c in party:
		before[c] = c.injury_level
	var chance: float = DayBarLogic._get_success_chance(e.quest, party)
	var story: String = e.quest.generateResults(party, chance)
	var succeeded: bool = DayBarLogic._did_succeed(story)
	var gold: int = DayBarLogic._get_gold_earned(e.quest, succeeded)
	var standing: int = e.quest.difficulty if succeeded else 0
	GameState.add_gold(gold)
	GameState.add_standing(standing)
	var hurt := []
	for c in party:
		if c.injury_level > before[c]:
			hurt.append(c)
	return {
		"quest": e.quest,
		"party": e.party.duplicate(),
		"story": story,
		"succeeded": succeeded,
		"chance": chance,
		"gold": gold,
		"standing": standing,
		"hurt": hurt,
		"milestone": e.milestone,
	}


## DaySummary's "New Day" button. Opens on the Board.
func start_new_day() -> void:
	last_report = report.duplicate()
	last_report.live = false
	report = { }
	tab = "board"
	screen = { }
	GameState.start_new_day()
	if GameState.day == MILESTONE_DAY:
		toast(TOAST_MILESTONE_DAY % GameState.day)
	else:
		toast(TOAST_NEW_DAY % [GameState.day, S.count(entries.size(), "new quest", "new quests"), CharacterContainer.hireable_characters.size()])
	queue_refresh()


## The report's button: starts the next day after End Day, otherwise just closes.
func close_report() -> void:
	if report.get("live", false):
		start_new_day()
	else:
		report = { }
		queue_refresh()


func open_last_report() -> void:
	show_menu = false
	if last_report.is_empty():
		queue_refresh()
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
	_refresh_content()
	_refresh_action_bar()
	_refresh_nav()
	_refresh_overlays()


func _refresh_header() -> void:
	_day_value.text = HEADER_DAY % GameState.day
	var left := days_to_drake()
	if left > 0:
		_drake_value.text = HEADER_DRAKE % [left, S.plural(left, "day", "days")]
	elif left == 0:
		_drake_value.text = HEADER_DRAKE_TODAY
	else:
		_drake_value.text = HEADER_DRAKE_GONE
	S.color(_drake_value, DRAKE_WARNING if left <= 2 and left >= 0 else S.CREAM)
	_gold_value.text = str(GameState.gold)
	_standing_value.text = str(GameState.standing)


func _refresh_content() -> void:
	# a screen whose quest vanished (new day) closes itself
	if screen.get("kind", "") == "assign" and screen.index >= entries.size():
		screen = { }
	var kind: String = screen.get("kind", "")
	for t in _tabs:
		_tabs[t].visible = kind == "" and t == tab
	for s in _screens:
		_screens[s].visible = s == kind
	var view: String
	if kind == "":
		_tabs[tab].refresh()
		view = "tab:%s:%s" % [tab, guild_seg]
	else:
		_screens[kind].refresh()
		view = "screen:%s:%d" % [kind, screen.get("index", 0)]
	# back to the top only when the view changes, not on every tap
	if view != _last_view:
		_last_view = view
		var node: Control = _screens[kind] if kind != "" else _tabs[tab]
		node.scroll_to_top()


func _refresh_action_bar() -> void:
	# screens put their own buttons in this spot (Deny / Send, Back / Hire)
	_action_bar.visible = screen.is_empty()
	if roster().is_empty() and can_hire_anyone():
		_set_action(ACTION_HIRE, ACTION_HIRE_HINT, ACTION_HIRE_BUTTON, "blue")
	elif outstanding() > 0:
		var out := outstanding()
		var next: Dictionary = entries[next_open(0)]
		_set_action(ACTION_DECIDE % S.count(out, "quest", "quests"), ACTION_DECIDE_HINT % next.quest.questTitle, ACTION_DECIDE_BUTTON, "blue")
	else:
		var going := ready_entries().size()
		var hint := ACTION_END_HINT % S.count(going, "party", "parties") if going > 0 else ACTION_END_HINT_NONE
		_set_action(ACTION_END % GameState.day, hint, ACTION_END_BUTTON, "green")


func _set_action(title: String, hint: String, button: String, kind: String) -> void:
	_action_title.text = title
	_action_hint.text = hint
	_action_button.text = button
	S.style_button(_action_button, kind, 30)


## Bottom tabs: the open one is white; each has a badge when it needs a visit.
func _refresh_nav() -> void:
	var current := "board" if screen.get("kind", "") == "assign" else tab
	for t in TABS:
		var b := _nav_button(t)
		var active: bool = t == current
		var sb := S.flat(S.WHITE if active else NAV_IDLE, 10, 3 if active else 0, S.BLUE_TEXT, Vector4(4, 8, 4, 8))
		for st in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, sb)
		for st in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(st, S.INK if active else S.WHITE)
		b.add_theme_color_override("icon_normal_color", S.INK if active else S.WHITE)
		b.add_theme_color_override("icon_hover_color", S.INK if active else S.WHITE)
		b.add_theme_color_override("icon_pressed_color", S.INK if active else S.WHITE)
		var badge := _badge_for(t)
		var badge_node: Control = b.get_node("Badge")
		badge_node.visible = badge != ""
		badge_node.get_node("Text").text = badge


func _badge_for(t: String) -> String:
	match t:
		"board":
			return str(outstanding()) if outstanding() > 0 else ""
		"guild":
			if roster().is_empty() and can_hire_anyone():
				return "!"
			return "%d new" % new_recruits() if new_recruits() > 0 else ""
		"upgrades":
			return str(upgradable().size()) if not upgradable().is_empty() else ""
	return ""


func _nav_button(t: String) -> Button:
	return get_node("%%Nav_%s" % t)


func _refresh_overlays() -> void:
	_report.visible = not report.is_empty()
	_end_check.visible = report.is_empty() and show_end_check
	_menu.visible = report.is_empty() and show_menu
	_welcome.visible = report.is_empty() and show_welcome
	for o in [_report, _end_check, _menu, _welcome]:
		if o.visible:
			o.refresh()

# ============================================================ TOAST


## Short message just above the action bar that fades out.
func toast(text: String) -> void:
	_toast_label.text = text
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)
