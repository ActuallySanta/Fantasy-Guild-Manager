## Mobile Hall: a phone-first UI for the guild game, built from the
## playtest feedback on the Deck, Flow and Ledger prototypes.
## Scene: MobileHall/hall_main.tscn
##
## Shell, top to bottom:
##   header      - day, Bone Drake countdown, gold, standing, menu button
##   content     - one of four tabs (Board, Members, Guild, Shop), or a screen
##                 over them (Assign Party, Character)
##   action bar  - one big "what to do next" button (hidden on screens, which
##                 have their own buttons in that spot, and on the Shop tab,
##                 whose Buy bar sits there)
##   nav         - Board / Members / Guild / Shop with badges, always visible
##                 (ids: board / guild / upgrades / shop)
## Overlays over everything: End Day check, Day Report, Welcome, Menu.
## (The Training Yard and Hospital live on the Upgrades tab's Tonight half.)
## On top of all of it: the colorblind filter (set from the Menu, saved to disk).
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
## HOW THE PIECES TALK
## This script owns the day's state and every game action. Each tab, screen
## and overlay gets setup(self) once, keeps that reference as `hall`, reads the
## QUERIES and calls the ACTIONS below, and never changes game state itself.
## After any change this script calls refresh() on whatever is showing.
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Training and healing rules live in GuildUpgrades (run_night).
##
## Sections:
##   SETTINGS · TEXT · STATE · NODES · SETUP · QUERIES ·
##   ACTIONS (navigation, overlays, quests, guild, end of day) ·
##   REFRESH (header, content, action bar, nav, overlays) · TOAST
extends Control

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const DayBarLogic := preload("res://Scripts/UI/day_bar.gd")


# ============================================================ SETTINGS

## Same as QuestList.quests_per_day.
const QUESTS_PER_DAY := 5
## The day QuestList swaps the board for the milestone (Bone Drake) quest.
const MILESTONE_DAY := 10
## Bottom tabs, left to right (ids match the Nav_<id> buttons and Tab nodes in the scene).
const TAB_IDS := ["board", "guild", "upgrades", "shop"]
## The Shop tab (groundwork only: nothing can be bought yet).
const TAB_SHOP := "shop"
## Screen kinds that can cover the tabs (see `active_screen`).
const SCREEN_ASSIGN := "assign"
const SCREEN_CHARACTER := "character"
## Halves of the Guild tab.
const GUILD_SECTION_ROSTER := "roster"
const GUILD_SECTION_HIRE := "hire"
## Halves of the Upgrades tab.
const UPGRADES_SECTION_TONIGHT := "tonight"
const UPGRADES_SECTION_BUILD := "build"
## Seconds a toast stays fully visible, then how long it takes to fade.
const TOAST_SECONDS := 2.2
const TOAST_FADE_SECONDS := 0.4
## The Bone Drake countdown turns red when this many days (or fewer) are left.
const DRAKE_WARNING_DAYS := 2
## Colorblind filter choices, in Menu order. Index = the shader's `mode`.
const COLOR_FILTERS := ["Off", "Red-weak", "Green-weak", "Blue-yellow"]
## Where player settings are saved, and the section / key for the filter.
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "accessibility"
const SETTINGS_COLOR_FILTER := "color_filter"


# ============================================================ TEXT

# ---- header
## The day number on the DAY tile.
const HEADER_DAY := "%d"
## The countdown note (BBCode); the days left are in red ink, and the whole
## note turns red once DRAKE_WARNING_DAYS or fewer are left.
const HEADER_DRAKE := "The Bone Drake wakes in [color=#%s]%d %s[/color]"
const HEADER_DRAKE_TODAY := "The Bone Drake [color=#%s]attacks today![/color]"
const HEADER_DRAKE_GONE := "The Bone Drake has come and gone"

# ---- nav
## Nav tab heights: the open tab stands a little taller than the others.
const NAV_HEIGHT := 100
const NAV_HEIGHT_OPEN := 114

# ---- action bar
const ACTION_HIRE := "Hire your first adventurer"
const ACTION_HIRE_HINT := "You need someone to send on quests."
const ACTION_HIRE_BUTTON := "For Hire"
const ACTION_DECIDE := "%s to decide"
const ACTION_DECIDE_HINT := "Next: %s"
const ACTION_DECIDE_BUTTON := "Next Quest"
const ACTION_END := "Ready to end Day %d"
const ACTION_END_HINT := "%s going out tonight"
const ACTION_END_HINT_NONE := "No parties going out tonight"
const ACTION_END_BUTTON := "End Day"

# ---- toasts
const TOAST_SENT := "Party sent: %s"
const TOAST_DENIED := "Denied: %s"
const TOAST_RECALLED := "Party recalled. Your picks are kept."
const TOAST_RECONSIDER := "Back on the board: %s"
const TOAST_MOVED := "%s moved from %s"
const TOAST_PARTY_FULL := "Party is full. Tap someone in it to swap them out."
const TOAST_DEAD := "%s can't go on quests anymore."
const TOAST_HIRED := "%s joined the guild!"
const TOAST_ROSTER_FULL := "No room. Upgrade the Barracks for more beds."
const TOAST_UPGRADED := "%s upgraded to level %d!"
const TOAST_RESET := "Upgrades reset"
const TOAST_NEW_DAY := "Day %d · %s · %s for hire"
const TOAST_MILESTONE_DAY := "Day %d. The Bone Drake is attacking!"
const TOAST_TRAINING := "%s is training %s"
const TOAST_STOPPED_TRAINING := "%s stopped training"
const TOAST_SLOTS_FULL := "Every slot is taken. Upgrade the Training Yard for more."
const TOAST_TOO_HURT := "%s is too hurt to train. Try the Hospital (Guild > Tonight)."
const TOAST_ADMITTED := "%s is in a Hospital bed"
const TOAST_DISCHARGED := "%s went home"
const TOAST_REVIVED := "%s is back from the dead!"
const TOAST_IN_HOSPITAL := "%s is in the Hospital. Discharge them first."
const TOAST_IN_TRAINING := "%s is training. Take them out of the Training Yard first."
const TOAST_LEFT_QUEST := "%s left %s"


# ============================================================ STATE

# ---- the day's quests

## Today's quests, in board order. Each entry is a Dictionary:
##   quest:     CreatedQuest
##   state:     Style.QUEST_STATE_OPEN | QUEST_STATE_SENT | QUEST_STATE_DENIED
##   party:     Array of GuildCharacter (a draft while the quest is open)
##   milestone: bool (true for the Bone Drake quest)
var quest_entries: Array = []

# ---- what's showing

## Which bottom tab is showing (one of TAB_IDS).
var active_tab := "board"
## Which half of the Guild tab is showing (GUILD_SECTION_ROSTER | GUILD_SECTION_HIRE).
var guild_section := GUILD_SECTION_ROSTER
## Which half of the Upgrades tab is showing (UPGRADES_SECTION_TONIGHT | _BUILD).
var upgrades_section := UPGRADES_SECTION_TONIGHT
## Upgrades > Tonight: the "+ Add a hero" list under the Training Yard is open.
var training_picker_open := false
## The screen covering the tabs, or {} for none:
##   {kind: SCREEN_ASSIGN, quest_index: int}
##   {kind: SCREEN_CHARACTER, character: GuildCharacter, return_to: Dictionary}
##   (return_to = the screen to go back to when the Character screen closes)
var active_screen := {}

# ---- overlays

## The Day Report being shown, or {} when hidden:
##   {day: int, results: Array (see _run_quest), starts_next_day: bool}
## starts_next_day is true right after End Day: closing it starts the next day.
var shown_report := {}
## Last night's report, kept so the Menu can show it again.
var previous_report := {}
var is_end_check_open := false
var is_welcome_open := true
var is_menu_open := false

# ---- player choices

## Assign Party: also list adventurers already in another quest's party
## (sent or picked). Off by default, so the list only shows who's free.
var show_busy_adventurers := false
## The day the player last opened For Hire (the Guild badge clears then).
var for_hire_last_seen_day := 0
## Colorblind filter: index into COLOR_FILTERS (0 = off). Saved in SETTINGS_PATH.
var color_filter := 0

# ---- internal

## True while a refresh is waiting for the end of the frame.
var _is_refresh_queued := false
## Which tab / screen was showing at the last refresh (to know when to scroll to top).
var _last_view_key := ""
var _toast_tween: Tween


# ============================================================ NODES

# ---- header
@onready var _day_value: Label = %DayValue
@onready var _drake_value: RichTextLabel = %DrakeValue
@onready var _gold_value: Label = %GoldValue
@onready var _standing_value: Label = %StandingValue
@onready var _menu_button: Button = %MenuButton

# ---- content
@onready var _tabs := {"board": %TabBoard, "guild": %TabGuild, "upgrades": %TabUpgrades, "shop": %TabShop}
@onready var _screens := {SCREEN_ASSIGN: %ScreenAssign, SCREEN_CHARACTER: %ScreenCharacter}

# ---- action bar
@onready var _action_bar: Control = %ActionBar
@onready var _action_title: Label = %ActionTitle
@onready var _action_hint: Label = %ActionHint
@onready var _action_button: Button = %ActionButton

# ---- overlays
@onready var _end_check_overlay: Control = %OverlayEndDay
@onready var _report_overlay: Control = %OverlayReport
@onready var _welcome_overlay: Control = %OverlayWelcome
@onready var _menu_overlay: Control = %OverlayMenu

# ---- toast
@onready var _toast: PanelContainer = %Toast
@onready var _toast_label: Label = %ToastLabel

# ---- colorblind filter
@onready var _color_filter: ColorRect = %ColorFilter


# ============================================================ SETUP

func _ready() -> void:
	# buttons owned by the shell
	for tab_id in TAB_IDS:
		_nav_button(tab_id).pressed.connect(open_tab.bind(tab_id))
	_menu_button.pressed.connect(open_menu)
	_action_button.pressed.connect(do_next_step)

	# every tab, screen and overlay gets a reference back to this script
	var views: Array = _tabs.values() + _screens.values() + _all_overlays()
	for view in views:
		view.setup(self)
	_toast.visible = false

	# game systems -> redraw
	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	GuildUpgrades.home_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)

	_load_settings()
	_generate_quests()
	refresh()


func _on_day_started(_day: int) -> void:
	_generate_quests()
	queue_refresh()


## Fill quest_entries for today. Mirrors QuestList.populate / _generate_quests:
## the milestone day has only the Bone Drake, every other day has QUESTS_PER_DAY.
func _generate_quests() -> void:
	quest_entries.clear()
	if GameState.day == MILESTONE_DAY:
		quest_entries.append(_new_entry(CreatedQuest.new(MILESTONE_DAY), true))
		return
	var entries = quest_entries
	var standingNum = 0
	if(GuildUpgrades.standing <= 10):
		standingNum = 0
	elif(GuildUpgrades.standing <= 20):
		standingNum = 1
	elif(GuildUpgrades.standing <= 30):
		standingNum = 2
	elif(GuildUpgrades.standing <= 40):
		standingNum = 3
	elif(GuildUpgrades.standing <= 50):
		standingNum = 4
	else:
		standingNum = 5

	for quest_number in QUESTS_PER_DAY:
		var currentNum = 0
		currentNum += standingNum
		currentNum += int(rand_bell_curve())
		if(currentNum < 0):
			currentNum = 0
		elif(currentNum > 5):
			currentNum = 5

		if(currentNum - standingNum == 2):
			currentNum -= 1
		elif(currentNum - standingNum == -2):
			currentNum += 1

		if(GuildUpgrades.standing <= 5):
			currentNum = 0

		entries.append(_new_entry(CreatedQuest.new(currentNum, 0), false))

func rand_bell_curve(mean: float = 0.0, standard_deviation: float = 1.0) -> float:
	var u1: float = randf()
	var u2: float = randf()
	
	# Avoid log(0) which is undefined
	if u1 == 0.0: u1 = 0.0001 
	
	# Box-Muller transform formula
	var standard_normal: float = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	
	# Scale by standard deviation and shift by the mean
	return (standard_normal * standard_deviation) + mean

func _new_entry(quest: CreatedQuest, is_milestone: bool) -> Dictionary:
	return {"quest": quest, "state": Style.QUEST_STATE_OPEN, "party": [], "milestone": is_milestone}


# ============================================================ QUERIES
# Read-only questions the screens ask. None of these change anything.

# ---- roster

## Everyone in the guild.
func roster() -> Array:
	return CharacterContainer.active_characters


## True when every bed is taken (no more hiring).
func is_roster_full() -> bool:
	return roster().size() >= CharacterContainer.max_characters


## True when there's at least one recruit and a free bed.
func can_hire_anyone() -> bool:
	return not CharacterContainer.hireable_characters.is_empty() and not is_roster_full()


## Recruits the player hasn't looked at yet today (drives the Guild badge).
func unseen_recruit_count() -> int:
	if for_hire_last_seen_day == GameState.day or is_roster_full():
		return 0
	return CharacterContainer.hireable_characters.size()

# ---- quests


## Quests still needing Send or Deny. Same rule as QuestCard.is_outstanding.
func undecided_count() -> int:
	return quest_entries.filter(func(entry): return entry.state == Style.QUEST_STATE_OPEN).size()


## Quests that have been sent or denied.
func decided_count() -> int:
	return quest_entries.size() - undecided_count()


## Entries whose party goes out tonight.
func sent_entries() -> Array:
	return quest_entries.filter(func(entry): return entry.state == Style.QUEST_STATE_SENT)


func denied_entries() -> Array:
	return quest_entries.filter(func(entry): return entry.state == Style.QUEST_STATE_DENIED)


## Index of the quest whose party (sent or draft) has this character, or -1.
func quest_index_of(character: GuildCharacter) -> int:
	for quest_index in quest_entries.size():
		if quest_entries[quest_index].party.has(character):
			return quest_index
	return -1


## False for anyone who can't be put in a party (dead, training, or in a Hospital bed).
func can_go_on_quests(character: GuildCharacter) -> bool:
	return not Style.is_dead(character) and not GuildUpgrades.is_patient(character) \
			and not GuildUpgrades.is_training(character)


## Hurt heroes who aren't in a Hospital bed (the Upgrades > Tonight badge).
func hurt_waiting_count() -> int:
	return roster().filter(func(character):
		return GuildUpgrades.needs_care(character) and not GuildUpgrades.is_patient(character)).size()


## How many adventurers a quest takes at most.
func party_size_limit(entry: Dictionary) -> int:
	return QuestCard.get_slot_count(entry.quest)


## Success chance (0-100+) as the quest computes it, or -1 for an empty party.
func success_chance(entry: Dictionary, party: Array) -> int:
	if party.is_empty():
		return -1
	return int(entry.quest.calcSuccessChance(party))


## How many points of success chance this character gives a quest on their own.
func chance_added_by(entry: Dictionary, character: GuildCharacter) -> int:
	return int(entry.quest.calcSuccessChance([character]))


## The quest shown on Assign Party, or {} when that screen isn't open.
func current_quest_entry() -> Dictionary:
	if active_screen.get("kind", "") != SCREEN_ASSIGN or quest_entries.is_empty():
		return {}
	return quest_entries[clampi(active_screen.quest_index, 0, quest_entries.size() - 1)]


## First undecided quest at or after `start_index` (wrapping around), or -1.
func next_undecided_index(start_index: int = 0) -> int:
	for offset in quest_entries.size():
		var quest_index := (start_index + offset) % quest_entries.size()
		if quest_entries[quest_index].state == Style.QUEST_STATE_OPEN:
			return quest_index
	return -1

# ---- upgrades and countdown


## Buildings that can be upgraded right now (enough gold and standing).
func affordable_buildings() -> Array:
	return Style.buildings_in_order().filter(func(building):
		return GuildUpgrades.get_upgrade_status(building) == GuildUpgrades.UpgradeStatus.READY)


## Days left before the Bone Drake (0 = today, negative = already happened).
func days_until_drake() -> int:
	return MILESTONE_DAY - GameState.day


# ============================================================ ACTIONS
# Everything the player can do. Screens call these; each one ends by
# queueing a refresh so the whole UI catches up.

# ---- navigation

## Switch bottom tab. Closes any screen; party drafts stay on their quests.
## `section` optionally picks the tab's half (GUILD_SECTION_* or UPGRADES_SECTION_*).
func open_tab(tab_id: String, section: String = "") -> void:
	active_tab = tab_id
	if section != "" and tab_id == "guild":
		guild_section = section
	elif section != "" and tab_id == "upgrades":
		upgrades_section = section
	if active_tab == "guild" and guild_section == GUILD_SECTION_HIRE:
		for_hire_last_seen_day = GameState.day
	active_screen = {}
	queue_refresh()


## The Guild tab's Your Guild / For Hire buttons.
func show_guild_section(section: String) -> void:
	open_tab("guild", section)


## The Upgrades tab's Tonight / Build buttons.
func show_upgrades_section(section: String) -> void:
	open_tab("upgrades", section)


## Open Assign Party on one quest.
func open_assign(quest_index: int) -> void:
	if quest_entries.is_empty():
		return
	active_screen = {"kind": SCREEN_ASSIGN, "quest_index": clampi(quest_index, 0, quest_entries.size() - 1)}
	active_tab = "board"
	queue_refresh()


## Open a character's details over whatever is showing.
func open_character(character: GuildCharacter) -> void:
	active_screen = {"kind": SCREEN_CHARACTER, "character": character, "return_to": active_screen.duplicate()}
	queue_refresh()


## Character goes back to wherever it was opened from; Assign Party goes to the Board.
func close_screen() -> void:
	if active_screen.get("kind", "") == SCREEN_CHARACTER:
		active_screen = active_screen.get("return_to", {})
	else:
		active_screen = {}
	queue_refresh()


## The action bar's button: always the next thing to do
## (hire someone -> decide the next quest -> end the day).
func do_next_step() -> void:
	if roster().is_empty() and can_hire_anyone():
		open_tab("guild", GUILD_SECTION_HIRE)
	elif undecided_count() > 0:
		open_assign(next_undecided_index(0))
	else:
		open_end_check()

# ---- overlays


func open_menu() -> void:
	is_menu_open = true
	queue_refresh()


func close_menu() -> void:
	is_menu_open = false
	queue_refresh()


func open_welcome() -> void:
	is_menu_open = false
	is_welcome_open = true
	queue_refresh()


## The welcome card leads to the Board; the action bar then says what's next.
func close_welcome() -> void:
	is_welcome_open = false
	open_tab("board")

# ---- quests


## Assign Party: tap an adventurer to add or remove them. Someone already in
## another quest's party (sent or draft) moves over, so nobody is in two.
func toggle_in_party(character: GuildCharacter) -> void:
	var entry := current_quest_entry()
	if entry.is_empty() or entry.state == Style.QUEST_STATE_DENIED:
		return

	# already in this party: take them out
	if entry.party.has(character):
		_remove_from_party(entry, character)
		queue_refresh()
		return

	# can't be added
	if Style.is_dead(character):
		show_toast(TOAST_DEAD % character.name)
		return
	if GuildUpgrades.is_patient(character):
		show_toast(TOAST_IN_HOSPITAL % character.name)
		return
	if GuildUpgrades.is_training(character):
		show_toast(TOAST_IN_TRAINING % character.name)
		return
	var size_limit := party_size_limit(entry)
	if entry.party.size() >= size_limit and size_limit > 1:
		show_toast(TOAST_PARTY_FULL)
		return

	# solo quests just swap the one adventurer
	if size_limit == 1:
		entry.party.clear()

	# pull them out of any other quest's party first
	var previous_index := quest_index_of(character)
	if previous_index >= 0:
		var previous_entry: Dictionary = quest_entries[previous_index]
		_remove_from_party(previous_entry, character)
		show_toast(TOAST_MOVED % [character.name, previous_entry.quest.questTitle])

	entry.party.append(character)
	queue_refresh()


## Take someone out of a party. A sent quest left with nobody goes back to open.
func _remove_from_party(entry: Dictionary, character: GuildCharacter) -> void:
	entry.party.erase(character)
	if entry.party.is_empty() and entry.state == Style.QUEST_STATE_SENT:
		entry.state = Style.QUEST_STATE_OPEN


## Assign Party's "Show busy" toggle.
func set_show_busy_adventurers(is_on: bool) -> void:
	show_busy_adventurers = is_on
	queue_refresh()


## Send the party, then jump to the next undecided quest (or back to the Board).
func send_party() -> void:
	var entry := current_quest_entry()
	if entry.is_empty() or entry.party.is_empty():
		return
	entry.state = Style.QUEST_STATE_SENT
	show_toast(TOAST_SENT % entry.quest.questTitle)
	_go_to_next_undecided()


## Turn the quest down (costs standing), then jump to the next undecided quest.
func deny_quest() -> void:
	var entry := current_quest_entry()
	if entry.is_empty():
		return
	entry.party.clear()
	entry.state = Style.QUEST_STATE_DENIED
	GameState.reduce_standing(entry.quest.difficulty)
	show_toast(TOAST_DENIED % entry.quest.questTitle)
	_go_to_next_undecided()


## Undo Send: the party goes back to being a draft.
func recall_party() -> void:
	var entry := current_quest_entry()
	if entry.is_empty():
		return
	entry.state = Style.QUEST_STATE_OPEN
	show_toast(TOAST_RECALLED)
	queue_refresh()


## Undo Deny: the quest is open again (the standing lost isn't given back).
func reconsider_quest() -> void:
	var entry := current_quest_entry()
	if entry.is_empty():
		return
	entry.state = Style.QUEST_STATE_OPEN
	show_toast(TOAST_RECONSIDER % entry.quest.questTitle)
	queue_refresh()


## After Send / Deny: show the next undecided quest, or close to the Board.
func _go_to_next_undecided() -> void:
	var next_index := next_undecided_index(active_screen.quest_index + 1)
	if next_index < 0:
		active_screen = {}
	else:
		active_screen.quest_index = next_index
	queue_refresh()

# ---- guild


func hire(character: GuildCharacter) -> void:
	if is_roster_full():
		show_toast(TOAST_ROSTER_FULL)
	elif CharacterContainer.add_character_to_guild(character):
		show_toast(TOAST_HIRED % character.name)
	queue_refresh()


func upgrade_building(building: int) -> void:
	if GuildUpgrades.try_upgrade(building):
		show_toast(TOAST_UPGRADED % [GuildUpgrades.get_building_name(building), GuildUpgrades.get_level(building)])
	queue_refresh()


# ---- Upgrades > Tonight: Training Yard and Hospital


## "+ Add a hero" under the Training Yard: show / hide who can train.
func toggle_training_picker() -> void:
	training_picker_open = not training_picker_open
	queue_refresh()


## Put a hero in a training slot drilling `stat`, or change their stat.
## Someone in a quest's party leaves it first.
func train(character: GuildCharacter, stat: int) -> void:
	if not GuildUpgrades.can_train(character):
		show_toast(TOAST_TOO_HURT % character.name)
		return
	var is_new := not GuildUpgrades.is_training(character)
	if is_new and not GuildUpgrades.has_free_training_slot():
		show_toast(TOAST_SLOTS_FULL)
		return
	_leave_quest(character)
	GuildUpgrades.set_training(character, stat)
	if is_new:
		show_toast(TOAST_TRAINING % [character.name, Style.STATS[stat].name])
	# the pick list closes itself once every slot is taken
	if not GuildUpgrades.has_free_training_slot():
		training_picker_open = false
	queue_refresh()


func stop_training(character: GuildCharacter) -> void:
	GuildUpgrades.stop_training(character)
	show_toast(TOAST_STOPPED_TRAINING % character.name)
	queue_refresh()


## Put a hurt hero in a Hospital bed (they leave any party or training slot).
func admit(character: GuildCharacter) -> void:
	_leave_quest(character)
	if GuildUpgrades.admit(character):
		show_toast(TOAST_ADMITTED % character.name)
	queue_refresh()


func discharge(character: GuildCharacter) -> void:
	GuildUpgrades.discharge(character)
	show_toast(TOAST_DISCHARGED % character.name)
	queue_refresh()


func revive(character: GuildCharacter) -> void:
	if GuildUpgrades.revive(character):
		show_toast(TOAST_REVIVED % character.name)
	queue_refresh()


## Take a hero out of whatever quest party they're in (sent or draft).
func _leave_quest(character: GuildCharacter) -> void:
	var quest_index := quest_index_of(character)
	if quest_index < 0:
		return
	var entry: Dictionary = quest_entries[quest_index]
	_remove_from_party(entry, character)
	show_toast(TOAST_LEFT_QUEST % [character.name, entry.quest.questTitle])


# ---- settings


## Menu's colorblind button: Off -> Red-weak -> Green-weak -> Blue-yellow -> Off.
func cycle_color_filter() -> void:
	set_color_filter((color_filter + 1) % COLOR_FILTERS.size())


func set_color_filter(filter_index: int) -> void:
	color_filter = clampi(filter_index, 0, COLOR_FILTERS.size() - 1)
	_apply_color_filter()
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_COLOR_FILTER, color_filter)
	config.save(SETTINGS_PATH)
	queue_refresh()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		color_filter = clampi(int(config.get_value(SETTINGS_SECTION, SETTINGS_COLOR_FILTER, 0)), 0, COLOR_FILTERS.size() - 1)
	_apply_color_filter()


## Off = the filter rect is hidden, so it costs nothing.
func _apply_color_filter() -> void:
	_color_filter.visible = color_filter > 0
	(_color_filter.material as ShaderMaterial).set_shader_parameter("mode", color_filter)


## Menu's debug button.
func reset_upgrades() -> void:
	GuildUpgrades.reset()
	is_menu_open = false
	show_toast(TOAST_RESET)

# ---- end of day


## The End Day check: tonight's plan and anything worth buying first.
## If a quest is still undecided, go decide it instead.
func open_end_check() -> void:
	if undecided_count() > 0:
		open_assign(next_undecided_index(0))
		return
	is_end_check_open = true
	queue_refresh()


func close_end_check() -> void:
	is_end_check_open = false
	queue_refresh()


## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the report.
func end_day() -> void:
	if undecided_count() > 0:
		return
	# training and healing happen first, so nobody heals the night they're hurt
	var home := GuildUpgrades.run_night()
	var results := []
	for entry in sent_entries():
		results.append(_run_quest(entry))
	is_end_check_open = false
	training_picker_open = false
	active_screen = {}
	shown_report = {"starts_next_day": true, "day": GameState.day, "results": results, "home": home}
	queue_refresh()


## Play out one quest with DayBar's helpers and pay its gold and standing.
## Returns one result for the Day Report:
##   {quest, party, story, succeeded, chance, gold, standing, injured, milestone}
## (injured = the party members whose injury level went up on this quest)
func _run_quest(entry: Dictionary) -> Dictionary:
	var party: Array[GuildCharacter] = []
	party.assign(entry.party)

	# remember health before, to see who got hurt
	var injury_before := {}
	for character in party:
		injury_before[character] = character.injury_level

	# play it out
	var chance: float = DayBarLogic._get_success_chance(entry.quest, party)
	var story: String = entry.quest.generateResults(party, chance)
	var succeeded: bool = DayBarLogic._did_succeed(story)
	var gold_earned: int = DayBarLogic._get_gold_earned(entry.quest, succeeded)
	var standing_earned: int = entry.quest.difficulty + 1 if succeeded else 0
	GameState.add_gold(gold_earned)
	GameState.add_standing(standing_earned)

	# Increase character pluck by one if the quest succeeded.
	if succeeded:
		for character in party:
			character.pluck += 1

	var injured := []
	for character in party:
		if character.injury_level > injury_before[character]:
			injured.append(character)

	return {
		"quest": entry.quest,
		"party": entry.party.duplicate(),
		"story": story,
		"succeeded": succeeded,
		"chance": chance,
		"gold": gold_earned,
		"standing": standing_earned,
		"injured": injured,
		"milestone": entry.milestone,
	}


## DaySummary's "New Day" button. Keeps tonight's report for the Menu and opens on the Board.
func start_new_day() -> void:
	previous_report = shown_report.duplicate()
	previous_report.starts_next_day = false
	shown_report = {}
	active_tab = "board"
	active_screen = {}
	GameState.start_new_day()
	if GameState.day == MILESTONE_DAY:
		show_toast(TOAST_MILESTONE_DAY % GameState.day)
	else:
		var quests_text := Style.count_text(quest_entries.size(), "new quest", "new quests")
		show_toast(TOAST_NEW_DAY % [GameState.day, quests_text, CharacterContainer.hireable_characters.size()])
	queue_refresh()


## The report's button: starts the next day after End Day, otherwise just closes.
func close_report() -> void:
	if shown_report.get("starts_next_day", false):
		start_new_day()
	else:
		shown_report = {}
		queue_refresh()


## Menu's "Last night's report" button.
func open_previous_report() -> void:
	is_menu_open = false
	if previous_report.is_empty():
		queue_refresh()
		return
	shown_report = previous_report.duplicate()
	shown_report.starts_next_day = false
	queue_refresh()


# ============================================================ REFRESH

## Ask for a refresh at the end of this frame (many changes = one refresh).
func queue_refresh() -> void:
	if _is_refresh_queued:
		return
	_is_refresh_queued = true
	refresh.call_deferred()


## Redraw the whole shell and whatever tab / screen / overlay is showing.
func refresh() -> void:
	_is_refresh_queued = false
	_refresh_header()
	_refresh_content()
	_refresh_action_bar()
	_refresh_nav()
	_refresh_overlays()

# ---- header



func _refresh_header() -> void:
	_day_value.text = HEADER_DAY % GameState.day

	# the days left are always in red ink; in the last days the whole note is
	var days_left := days_until_drake()
	var red_ink := Style.RED.to_html(false)
	if days_left > 0:
		_drake_value.text = HEADER_DRAKE % [red_ink, days_left, Style.pick_plural(days_left, "day", "days")]
	elif days_left == 0:
		_drake_value.text = HEADER_DRAKE_TODAY % red_ink
	else:
		_drake_value.text = HEADER_DRAKE_GONE
	var is_drake_close := days_left >= 0 and days_left <= DRAKE_WARNING_DAYS
	Style.set_font_color(_drake_value, Style.RED if is_drake_close else Style.TEXT_MAIN)

	_gold_value.text = str(GameState.gold)
	_standing_value.text = str(GameState.standing)

# ---- content (tabs and screens)


func _refresh_content() -> void:
	# an Assign Party screen whose quest vanished (new day) closes itself
	if active_screen.get("kind", "") == SCREEN_ASSIGN and active_screen.quest_index >= quest_entries.size():
		active_screen = {}

	# show exactly one tab or one screen
	var screen_kind: String = active_screen.get("kind", "")
	for tab_id in _tabs:
		_tabs[tab_id].visible = screen_kind == "" and tab_id == active_tab
	for kind in _screens:
		_screens[kind].visible = kind == screen_kind

	var shown_view: Control
	var view_key: String
	if screen_kind == "":
		shown_view = _tabs[active_tab]
		view_key = "tab:%s:%s:%s" % [active_tab, guild_section, upgrades_section]
	else:
		shown_view = _screens[screen_kind]
		view_key = "screen:%s:%d" % [screen_kind, active_screen.get("quest_index", 0)]
	shown_view.refresh()

	# back to the top only when the view changes, not on every tap
	if view_key != _last_view_key:
		_last_view_key = view_key
		shown_view.scroll_to_top()

# ---- action bar


func _refresh_action_bar() -> void:
	# screens put their own buttons in this spot (Deny / Send, Back / Hire),
	# and so does the Shop tab (its Buy bar)
	_action_bar.visible = active_screen.is_empty() and active_tab != TAB_SHOP

	if roster().is_empty() and can_hire_anyone():
		_set_action(ACTION_HIRE, ACTION_HIRE_HINT, ACTION_HIRE_BUTTON)
	elif undecided_count() > 0:
		var next_entry: Dictionary = quest_entries[next_undecided_index(0)]
		var title := ACTION_DECIDE % Style.count_text(undecided_count(), "quest", "quests")
		_set_action(title, ACTION_DECIDE_HINT % next_entry.quest.questTitle, ACTION_DECIDE_BUTTON)
	else:
		var parties_going := sent_entries().size()
		var hint := ACTION_END_HINT % Style.count_text(parties_going, "party", "parties") if parties_going > 0 else ACTION_END_HINT_NONE
		_set_action(ACTION_END % GameState.day, hint, ACTION_END_BUTTON)


## The torn banner's title, hint and gold button (its look is set in the scene).
func _set_action(title: String, hint: String, button_text: String) -> void:
	_action_title.text = title
	_action_hint.text = hint
	_action_button.text = button_text

# ---- nav


## Bottom tabs: the open one is parchment (NavTabActive in hall_theme) and
## stands taller, the rest dark wood (NavTab); each has a badge when it needs a visit.
func _refresh_nav() -> void:
	# Assign Party counts as part of the Board
	var highlighted_tab := "board" if active_screen.get("kind", "") == SCREEN_ASSIGN else active_tab
	for tab_id in TAB_IDS:
		var nav_button := _nav_button(tab_id)
		var is_active: bool = tab_id == highlighted_tab
		nav_button.theme_type_variation = &"NavTabActive" if is_active else &"NavTab"
		nav_button.custom_minimum_size.y = NAV_HEIGHT_OPEN if is_active else NAV_HEIGHT

		var badge_text := _badge_text_for(tab_id)
		var badge: Control = nav_button.get_node("Badge")
		badge.visible = badge_text != ""
		badge.get_node("Text").text = badge_text


## What a nav tab's badge says ("" = no badge).
func _badge_text_for(tab_id: String) -> String:
	match tab_id:
		"board":
			return str(undecided_count()) if undecided_count() > 0 else ""
		"guild":
			if roster().is_empty() and can_hire_anyone():
				return "!"
			return "%d new" % unseen_recruit_count() if unseen_recruit_count() > 0 else ""
		"upgrades":
			var affordable_count := affordable_buildings().size()
			return str(affordable_count) if affordable_count > 0 else ""
	return ""


func _nav_button(tab_id: String) -> Button:
	return get_node("%%Nav_%s" % tab_id)

# ---- overlays


## The Day Report hides every other overlay while it's open.
func _refresh_overlays() -> void:
	var is_report_open := not shown_report.is_empty()
	_report_overlay.visible = is_report_open
	_end_check_overlay.visible = not is_report_open and is_end_check_open
	_menu_overlay.visible = not is_report_open and is_menu_open
	_welcome_overlay.visible = not is_report_open and is_welcome_open
	for overlay in _all_overlays():
		if overlay.visible:
			overlay.refresh()


func _all_overlays() -> Array:
	return [_report_overlay, _end_check_overlay, _menu_overlay, _welcome_overlay]


# ============================================================ TOAST

## Short message just above the action bar that fades out.
func show_toast(message: String) -> void:
	_toast_label.text = message
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, TOAST_FADE_SECONDS)
	_toast_tween.tween_callback(_toast.hide)
