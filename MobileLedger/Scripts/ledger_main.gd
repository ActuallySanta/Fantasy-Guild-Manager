## Mobile Ledger — a phone-first UI for the guild game.
##
## UI only: every rule comes from the existing systems. Characters come from
## CharacterContainer / GuildCharacter, quests from CreatedQuest, results from
## CreatedQuest.generateResults (scored with the same helpers DayBar uses),
## days from GameState and upgrades from GuildUpgrades. Nothing in those
## scripts is changed; this scene just presents them differently.
##
## Every screen is an authored scene (see MobileLedger/Scenes). This script
## holds the day's state and the game-flow calls, and tells each screen to
## refresh whenever something changes.
extends Control

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone quest.
const MILESTONE_DAY := 10

const TABS := [
	["characters", "Characters", "nav_characters"],
	["quests", "Quests", "nav_quests"],
	["home", "Home", "nav_home"],
	["upgrades", "Upgrades", "nav_upgrades"],
	["settings", "Settings", "nav_settings"],
]

## Which bottom tab is showing, and which half of the Characters tab.
var tab := "home"
var seg := "guild"
## Today's quests: {quest: CreatedQuest, state: "open"|"ready"|"denied", party: Array}
var entries: Array = []
## Full-screen page over the content: {kind: "charter", entry, draft} or {kind: "codex", character}
var page := {}
## Day report being shown: {live: bool, day: int, results: Array}. Empty = hidden.
var report := {}
## Yesterday's results, readable again from Home.
var last_report := {}
var story_open := true
var show_welcome := false

var _dirty := false
var _last_tab := ""
var _last_page := ""
var _toast_tween: Tween

@onready var _scroll: ScrollContainer = %Scroll
@onready var _pages := {"home": %PageHome, "quests": %PageQuests, "characters": %PageCharacters, "upgrades": %PageUpgrades, "settings": %PageSettings}
@onready var _screens := {"charter": %ScreenCharter, "codex": %ScreenCodex}
@onready var _page_layer: Control = %PageLayer
@onready var _overlay: Control = %Overlay
@onready var _report: Control = %OverlayReport
@onready var _welcome: Control = %OverlayWelcome
@onready var _toast: PanelContainer = %Toast


func _ready() -> void:
	for t in TABS:
		_tab_button(t[0]).pressed.connect(open_tab.bind(t[0]))
	%DayBarButton.pressed.connect(_on_day_bar_button)
	for n in _pages.values() + _screens.values() + [_report, _welcome]:
		n.setup(self)
	_toast.visible = false
	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)
	_generate_quests()
	show_welcome = true
	refresh()


# ================================================================ game actions

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
	queue_refresh()


## Quests that still need Accept (with a party) or Deny — QuestCard.is_outstanding.
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


## A character can only sit in one quest's slots (CharacterSlot.assign).
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
	toast("Denied: %s" % entry.quest.questTitle)
	queue_refresh()


func cancel(entry: Dictionary) -> void:
	entry.party = []
	entry.state = "open"
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
		open_tab("quests")
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
	page = {}
	report = {"live": true, "day": GameState.day, "results": results}
	queue_refresh()


## DaySummary's "New Day" button.
func start_new_day() -> void:
	last_report = report.duplicate()
	last_report.live = false
	report = {}
	tab = "quests"
	GameState.start_new_day()
	if GameState.day == MILESTONE_DAY:
		toast("Day %d. The Bone Drake is attacking!" % GameState.day)
	else:
		toast("Day %d begins · %d new quests · %d for hire" % [GameState.day, entries.size(), CharacterContainer.hireable_characters.size()])
	queue_refresh()


# ================================================================ navigation

func open_tab(t: String, segment: String = "") -> void:
	tab = t
	if segment != "":
		seg = segment
	page = {}
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


func open_last_report() -> void:
	if last_report.is_empty():
		return
	report = last_report.duplicate()
	report.live = false
	queue_refresh()


func close_report() -> void:
	if report.get("live", false):
		start_new_day()
	else:
		report = {}
		queue_refresh()


func close_welcome() -> void:
	show_welcome = false
	if CharacterContainer.active_characters.is_empty():
		tab = "characters"
		seg = "hire"
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

	for t in _pages:
		_pages[t].visible = t == tab
	_pages[tab].refresh()
	if _last_tab != tab:
		_scroll.scroll_vertical = 0
	_last_tab = tab

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

	_refresh_day_bar()
	_refresh_nav()

	_report.visible = not report.is_empty()
	_welcome.visible = report.is_empty() and show_welcome
	_overlay.mouse_filter = MOUSE_FILTER_STOP if _report.visible or _welcome.visible else MOUSE_FILTER_IGNORE
	if _report.visible:
		_report.refresh()


func _refresh_day_bar() -> void:
	%DayBar.visible = page.is_empty()
	var out := outstanding()
	var ready := ready_entries().size()
	var b: Button = %DayBarButton
	if out > 0:
		%DayBarTitle.text = "%d quest%s undecided" % [out, "" if out == 1 else "s"]
		%DayBarSubtitle.text = "Accept with a party or deny each one"
		b.text = "Review"
		S.style_button(b, "blue", 28)
	else:
		%DayBarTitle.text = "Ready to end Day %d" % GameState.day
		%DayBarSubtitle.text = "%d part%s set out tonight" % [ready, "y" if ready == 1 else "ies"] if ready > 0 else "No parties going out today"
		b.text = "End Day"
		S.style_button(b, "green", 30)


func _on_day_bar_button() -> void:
	if outstanding() > 0:
		open_tab("quests")
	else:
		end_day()


func _tab_button(t: String) -> Button:
	return get_node("%%Tab_%s" % t)


func _refresh_nav() -> void:
	var current := tab
	if page.get("kind", "") == "charter":
		current = "quests"
	elif page.get("kind", "") == "codex":
		current = "characters"
	for t in TABS:
		var b := _tab_button(t[0])
		var active: bool = t[0] == current
		var sb := S.sbtex("tab_tile_active.png" if active else "tab_tile.png", 22, Vector4(4, 16, 4, 12), 4)
		for s in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, sb)
		b.get_node("Ribbon").visible = active
		var badge := ""
		if t[0] == "quests" and outstanding() > 0:
			badge = str(outstanding())
		if t[0] == "characters" and CharacterContainer.active_characters.is_empty():
			badge = "!"
		b.get_node("Badge").visible = badge != ""
		b.get_node("Badge/Text").text = badge


# ================================================================ toast

func toast(text: String) -> void:
	%ToastLabel.text = text
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)
