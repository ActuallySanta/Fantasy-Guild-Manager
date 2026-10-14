## Mobile Ledger: a phone-first UI for the guild game, styled after the
## "Guild Ledger" reference art (parchment, wood, wax seals, bookmark tabs).
## Scene: MobileLedger/ledger_main.tscn
##
## Five bottom tabs (Characters, Quests, Home, Upgrades, Settings), two
## full-screen pages over them (Mission Charter, Adventurer Codex), the day bar
## above the tabs, and the day report / welcome card over everything.
##
## This script owns the day's state and every game action. The pages call the
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

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")


# ============================================================ SETTINGS

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10
## Bottom tabs, left to right (ids match the Tab_<id> buttons in the scene).
const TABS := ["characters", "quests", "home", "upgrades", "settings"]
## Seconds a toast stays up before fading.
const TOAST_SECONDS := 2.4


# ============================================================ TEXT

const DAY_BAR_UNDECIDED := "%d %s undecided"
const DAY_BAR_UNDECIDED_SUB := "Accept with a party or deny each one"
const DAY_BAR_REVIEW := "Review"
const DAY_BAR_READY := "Ready to end Day %d"
const DAY_BAR_PARTIES := "%d %s set out tonight"
const DAY_BAR_NO_PARTIES := "No parties going out today"
const DAY_BAR_END := "End Day"
const TOAST_PARTY_READY := "Party ready for %s"
const TOAST_DENIED := "Denied: %s"
const TOAST_HIRED := "%s joined the guild!"
const TOAST_UPGRADED := "%s upgraded to level %d!"
const TOAST_RESET := "Upgrades reset"
const TOAST_NEW_DAY := "Day %d begins · %d new quests · %d for hire"
const TOAST_MILESTONE_DAY := "Day %d. The Bone Drake is attacking!"


# ============================================================ STATE

## Which bottom tab is showing, and which half of the Characters tab ("guild" | "hire").
var tab := "home"
var seg := "guild"
## Today's quests. Each entry:
##   {quest: CreatedQuest, state: "open" | "ready" | "denied", party: Array, milestone: bool}
var entries: Array = []
## Full-screen page over the tabs:
##   {} | {kind: "charter", entry, draft: Array} | {kind: "codex", character}
var page := {}
## Day report being shown: {live: bool, day: int, results: Array}. Empty = hidden.
var report := {}
## Yesterday's report, readable again from Home.
var last_report := {}
## Codex backstory expanded?
var story_open := true
var show_welcome := false

var _refresh_queued := false
var _last_tab := ""
var _last_page := ""
var _toast_tween: Tween


# ============================================================ NODES

@onready var _day_value: Label = %DayValue
@onready var _gold_value: Label = %GoldValue
@onready var _standing_value: Label = %StandingValue
@onready var _scroll: ScrollContainer = %Scroll
@onready var _pages := {"home": %PageHome, "quests": %PageQuests, "characters": %PageCharacters, "upgrades": %PageUpgrades, "settings": %PageSettings}
@onready var _page_layer: Control = %PageLayer
@onready var _screens := {"charter": %ScreenCharter, "codex": %ScreenCodex}
@onready var _day_bar: Control = %DayBar
@onready var _day_bar_title: Label = %DayBarTitle
@onready var _day_bar_subtitle: Label = %DayBarSubtitle
@onready var _day_bar_button: Button = %DayBarButton
@onready var _overlay: Control = %Overlay
@onready var _report: Control = %OverlayReport
@onready var _welcome: Control = %OverlayWelcome
@onready var _toast: PanelContainer = %Toast
@onready var _toast_label: Label = %ToastLabel


# ============================================================ SETUP

func _ready() -> void:
	for t in TABS:
		_tab_button(t).pressed.connect(open_tab.bind(t))
	_day_bar_button.pressed.connect(_on_day_bar_button)
	for screen in _pages.values() + _screens.values() + [_report, _welcome]:
		screen.setup(self)
	_toast.visible = false

	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)

	_generate_quests()
	show_welcome = true
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
	return {"quest": quest, "state": "open", "party": [], "milestone": milestone}


# ============================================================ QUERIES

## How many quests still need Accept (with a party) or Deny. QuestCard.is_outstanding.
func outstanding() -> int:
	return entries.filter(func(e): return e.state == "open").size()


func ready_entries() -> Array:
	return entries.filter(func(e): return e.state == "ready")


func denied_count() -> int:
	return entries.filter(func(e): return e.state == "denied").size()


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


## How many buildings can be upgraded right now.
func upgrades_ready() -> int:
	var n := 0
	for b in GuildUpgrades.Building.values():
		if GuildUpgrades.get_upgrade_status(b) == GuildUpgrades.UpgradeStatus.READY:
			n += 1
	return n


# ============================================================ ACTIONS

# ---- navigation

## Switch bottom tab (optionally also the Characters half). Closes any page.
func open_tab(t: String, segment: String = "") -> void:
	tab = t
	if segment != "":
		seg = segment
	page = {}
	queue_refresh()


## Characters tab: "guild" or "hire".
func set_segment(segment: String) -> void:
	seg = segment
	queue_refresh()


func open_charter(entry: Dictionary) -> void:
	page = {"kind": "charter", "entry": entry, "draft": entry.party.duplicate()}
	queue_refresh()


func open_codex(character: GuildCharacter) -> void:
	page = {"kind": "codex", "character": character}
	story_open = true
	queue_refresh()


func close_page() -> void:
	page = {}
	queue_refresh()


func toggle_story() -> void:
	story_open = not story_open
	queue_refresh()


func open_welcome() -> void:
	show_welcome = true
	queue_refresh()


## Leaving the welcome card with nobody hired goes straight to For Hire.
func close_welcome() -> void:
	show_welcome = false
	if CharacterContainer.active_characters.is_empty():
		tab = "characters"
		seg = "hire"
	queue_refresh()


# ---- quests

## Mission Charter: tap an adventurer to add or remove them from the draft party.
func toggle_charter_pick(c: GuildCharacter) -> void:
	var n := slot_count(page.entry)
	var draft: Array = page.draft
	if draft.has(c):
		draft.erase(c)
	elif n == 1:
		page.draft = [c]
	elif draft.size() < n:
		draft.append(c)
	queue_refresh()


## Mission Charter: send the draft party and close the charter.
func dispatch_charter() -> void:
	var entry: Dictionary = page.entry
	if page.draft.is_empty():
		return
	set_party(entry, page.draft)
	page = {}
	toast(TOAST_PARTY_READY % entry.quest.questTitle)
	queue_refresh()


## A character can only sit in one quest's party (CharacterSlot.assign), so
## they leave any other party first.
func set_party(entry: Dictionary, party: Array) -> void:
	for e in entries:
		if e == entry:
			continue
		e.party = e.party.filter(func(c): return not party.has(c))
		if e.state == "ready" and e.party.is_empty():
			e.state = "open"
	entry.party = party.duplicate()
	entry.state = "ready" if not party.is_empty() else "open"
	queue_refresh()


func deny(entry: Dictionary) -> void:
	entry.party = []
	entry.state = "denied"
	toast(TOAST_DENIED % entry.quest.questTitle)
	queue_refresh()


## Undo an accepted party so the quest can be decided again.
func cancel(entry: Dictionary) -> void:
	entry.party = []
	entry.state = "open"
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


## Settings' debug button.
func reset_upgrades() -> void:
	GuildUpgrades.reset()
	toast(TOAST_RESET)


# ---- end of day

## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the report.
func end_day() -> void:
	if outstanding() > 0:
		open_tab("quests")
		return
	var results := []
	for e in ready_entries():
		results.append(_run_quest(e))
	page = {}
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


## DaySummary's "New Day" button. Opens on the Quests tab.
func start_new_day() -> void:
	last_report = report.duplicate()
	last_report.live = false
	report = {}
	tab = "quests"
	GameState.start_new_day()
	if GameState.day == MILESTONE_DAY:
		toast(TOAST_MILESTONE_DAY % GameState.day)
	else:
		toast(TOAST_NEW_DAY % [GameState.day, entries.size(), CharacterContainer.hireable_characters.size()])
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


## Day bar button: "Review" while quests are undecided, then "End Day".
func _on_day_bar_button() -> void:
	if outstanding() > 0:
		open_tab("quests")
	else:
		end_day()


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
	_refresh_tab()
	_refresh_page()
	_refresh_day_bar()
	_refresh_nav()
	_refresh_overlays()


func _refresh_tab() -> void:
	for t in _pages:
		_pages[t].visible = t == tab
	_pages[tab].refresh()
	# back to the top only when the tab changes, not on every tap
	if _last_tab != tab:
		_scroll.scroll_vertical = 0
	_last_tab = tab


## Mission Charter / Adventurer Codex over the tabs.
func _refresh_page() -> void:
	# a charter whose quest got denied (or replaced by a new day) closes itself
	if page.get("kind", "") == "charter" and not (entries.has(page.entry) and page.entry.state != "denied"):
		page = {}
	var kind: String = page.get("kind", "")
	for s in _screens:
		_screens[s].visible = s == kind
	_page_layer.mouse_filter = MOUSE_FILTER_IGNORE if kind == "" else MOUSE_FILTER_STOP
	if kind != "":
		_screens[kind].refresh()
		if kind != _last_page:
			_screens[kind].scroll_to_top()
	_last_page = kind


func _refresh_day_bar() -> void:
	_day_bar.visible = page.is_empty()
	var out := outstanding()
	if out > 0:
		_day_bar_title.text = DAY_BAR_UNDECIDED % [out, S.plural(out, "quest", "quests")]
		_day_bar_subtitle.text = DAY_BAR_UNDECIDED_SUB
		_day_bar_button.text = DAY_BAR_REVIEW
		S.style_button(_day_bar_button, "blue", 28)
	else:
		var going := ready_entries().size()
		_day_bar_title.text = DAY_BAR_READY % GameState.day
		_day_bar_subtitle.text = DAY_BAR_PARTIES % [going, S.plural(going, "party", "parties")] if going > 0 else DAY_BAR_NO_PARTIES
		_day_bar_button.text = DAY_BAR_END
		S.style_button(_day_bar_button, "green", 30)


## Bottom tabs: the open one gets the raised tile + ribbon; badges for
## undecided quests ("5") and an empty guild ("!").
func _refresh_nav() -> void:
	var current := tab
	if page.get("kind", "") == "charter":
		current = "quests"
	elif page.get("kind", "") == "codex":
		current = "characters"
	for t in TABS:
		var b := _tab_button(t)
		var active: bool = t == current
		var sb := S.sbtex("tab_tile_active.png" if active else "tab_tile.png", 22, Vector4(4, 16, 4, 12), 4)
		for s in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, sb)
		b.get_node("Ribbon").visible = active
		var badge := _badge_for(t)
		b.get_node("Badge").visible = badge != ""
		b.get_node("Badge/Text").text = badge


func _badge_for(t: String) -> String:
	if t == "quests" and outstanding() > 0:
		return str(outstanding())
	if t == "characters" and CharacterContainer.active_characters.is_empty():
		return "!"
	return ""


func _tab_button(t: String) -> Button:
	return get_node("%%Tab_%s" % t)


func _refresh_overlays() -> void:
	_report.visible = not report.is_empty()
	_welcome.visible = report.is_empty() and show_welcome
	_overlay.mouse_filter = MOUSE_FILTER_STOP if _report.visible or _welcome.visible else MOUSE_FILTER_IGNORE
	if _report.visible:
		_report.refresh()


# ============================================================ TOAST

## Short message at the top of the content that fades out.
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
