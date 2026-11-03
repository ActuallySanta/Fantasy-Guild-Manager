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
## Overlays over everything: End Day check, Day Report, Welcome, Menu,
## the Game Over ledger (when the guild is stuck with nobody left; see is_run_over),
## and the final battle's credits roll (FINAL_DAY; a victory or a defeat).
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
## This script owns the day's state and every game action. Each tab, screen,
## overlay and shell piece gets setup(self) once, keeps that reference as `hall`,
## reads the QUERIES and calls the ACTIONS below, and never changes game state
## itself. After any change this script calls refresh() on whatever is showing.
##
## WHERE THINGS LIVE (keep this script to state, actions and refresh; see CLAUDE.md)
##   hall_rules.gd     HallRules       building the day's quests, playing one out
##   hall_ledger.gd    HallLedger      is the run over, the Game Over numbers
##   hall_settings.gd  HallSettings    accessibility settings on disk
##   hall_header.gd    HallHeader      day, countdown, counters (and their motion), danger strip
##   hall_action_bar.gd HallActionBar  the "what to do next" banner
##   hall_nav.gd       HallNav         bottom tabs and their badges
##   hall_toast.gd     HallToast       the fading message
##   hall_style.gd / hall_fx.gd         colors and tables / animations
##
## UI only: every rule comes from the existing systems (CharacterContainer,
## GuildCharacter, CreatedQuest, GameState, GuildUpgrades, DayBar's scoring
## helpers). Training and healing rules live in GuildUpgrades (run_night).
##
## Sections:
##   SETTINGS · TEXT · STATE · NODES · SETUP · QUERIES ·
##   ACTIONS (navigation, overlays, quests, guild, end of day) ·
##   REFRESH (content, overlays) · TOAST
class_name HallMain
extends Control

## Fired at the end of each player action, for the tutorial coach
## (overlay_tutorial.gd). event: tab, hire, character, close, assign, pick,
## send, deny, end_check, end_day, new_day, upgrade, training_picker, train,
## admit, buy, equip, game_over, freeplay.
signal tutorial_event(event: String, data: Variant)



# ============================================================ SETTINGS

## The day QuestList swaps the board for the milestone (Bone Drake) quest.
const MILESTONE_DAY := 10
## The day of the main story's final battle: the board holds only that quest,
## a win rolls the credits and offers freeplay, a loss ends the run.
## (The final quest and freeplay's scaling are built in HallRules.)
const FINAL_DAY := 50
## Standing lost for releasing a living hero, plus one more per level of their
## Pluck (letting a veteran go hurts more). Releasing the fallen is free.
const RELEASE_BASE_STANDING_COST := 1
## Bottom tabs, left to right (ids match the Nav_<id> buttons and Tab nodes in the scene).
const TAB_IDS := ["board", "guild", "upgrades", "shop"]
## The Shop tab (goods come from the ItemShop autoload).
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
## The scene a new run starts in (not a playtest scenario, so its preset isn't re-applied).
const MAIN_SCENE_PATH := "uid://dtw7iu2s1gibm"  # MobileHall/hall_main.tscn
## run_stats.drake_result values (the Bone Drake milestone quest).
const DRAKE_RESULT_NONE := ""
const DRAKE_RESULT_SLAIN := "Slain"
const DRAKE_RESULT_LOST := "Lost"
## run_stats.final_result values (the FINAL_DAY battle).
const FINAL_RESULT_NONE := ""
const FINAL_RESULT_WON := "Won"
const FINAL_RESULT_LOST := "Lost"
# ---- motion (see hall_fx.gd; the counters' motion is in hall_header.gd)
## Seconds a SENT / DENIED stamp stays on the quest before the next one shows
## (taps are blocked meanwhile).
const STAMP_HOLD_SECONDS := 0.5
## Seconds the hired letter takes to fly to the roster, and how long it sits
## with its HIRED stamp before it goes.
const HIRE_FLY_SECONDS := 0.45
const HIRE_STAMP_HOLD_SECONDS := 0.5
## The HIRED stamp on the letter: where its centre sits (fraction of the
## letter's size), its text size, and its tilt (radians).
const HIRE_STAMP_AT := Vector2(0.68, 0.32)
const HIRE_STAMP_FONT_SIZE := 64
const HIRE_STAMP_TILT := -0.2
## End Day / new day: the dusk wash over the screen while the night plays out.
const DUSK_INK := Color("#26304A")
const DUSK_IN_SECONDS := 0.35
const DUSK_OUT_SECONDS := 0.45
## After a lost final battle the dusk lingers this long (seconds) before the
## defeat screen shows, and clears this slowly.
const DEFEAT_DUSK_IN_SECONDS := 1.2
const DEFEAT_DUSK_OUT_SECONDS := 1.4
## Draw order of the FX layer: above the overlays (z 10 in hall_main.tscn), so
## the dusk wash covers the End Day sheet and the Day Report too, and below
## Pip (OverlayTutorial.TUTORIAL_Z_INDEX).
const FX_LAYER_Z_INDEX := 15
## Each new tab or screen fades in this fast (seconds).
const VIEW_FADE_SECONDS := 0.14


# ============================================================ TEXT

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
const TOAST_RELEASED := "%s left the guild"
const TOAST_RELEASED_COST := "%s left the guild (-%d standing)"
const TOAST_UPGRADED := "%s upgraded to level %d!"
const TOAST_RESET := "Upgrades reset"
const TOAST_NEW_DAY := "Day %d · %s · %s for hire"
const TOAST_MILESTONE_DAY := "Day %d. The Bone Drake is attacking!"
const TOAST_FINAL_DAY := "Day %d. The final battle is here!"
const TOAST_TRAINING := "%s is training %s"
const TOAST_STOPPED_TRAINING := "%s stopped training"
const TOAST_SLOTS_FULL := "Every slot is taken. Upgrade the Training Yard for more."
const TOAST_TOO_HURT := "%s is too hurt to train. Try the Hospital (Guild > Tonight)."
const TOAST_ADMITTED := "%s is in a Hospital bed"
const TOAST_DISCHARGED := "%s went home"
const TOAST_REVIVED := "%s is back from the dead!"
const TOAST_REVIVE_NO_BED := "No free bed for %s. Upgrade the Barracks first."
const TOAST_IN_HOSPITAL := "%s is in the Hospital. Discharge them first."
const TOAST_IN_TRAINING := "%s is training. Take them out of the Training Yard first."
const TOAST_LEFT_QUEST := "%s left %s"
const TOAST_BOUGHT := "Bought the %s! Equip it from a hero's page."
const TOAST_CANT_BUY := "Not enough gold for that."
const TOAST_EQUIPPED := "%s equipped the %s"
const TOAST_UNEQUIPPED := "%s took off the %s"
const TOAST_WRONG_ROLE := "Only %ss can use the %s."
const TOAST_HANDS_FULL := "%s's hands are full. Take something off first."
const TOAST_GEAR_DEAD := "%s can't use gear anymore."
const TOAST_TAB_LOCKED := "Pip will open this on Day %d."

# ---- stamps (SENT is inked on the quest itself, see screen_assign / quest_row)
const STAMP_DENIED := "DENIED"
const STAMP_HIRED := "HIRED"


# ============================================================ STATE

# ---- the day's quests

## Today's quests, in board order. Each entry is a Dictionary:
##   quest:     CreatedQuest
##   state:     HallStyle.QUEST_STATE_OPEN | QUEST_STATE_SENT | QUEST_STATE_DENIED
##   party:     Array of GuildCharacter (a draft while the quest is open)
##   milestone: bool (true for the Bone Drake quest)
##   final:     bool (true for the FINAL_DAY battle)
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
##   {day: int, results: Array (see _run_quest), starts_next_day: bool,
##    home: Dictionary (see GuildUpgrades.run_night), released: Array (see released_today)}
## starts_next_day is true right after End Day: closing it starts the next day.
var shown_report := {}
## Heroes released today, for the Day Report. Each entry is a Dictionary:
##   {character: GuildCharacter, standing: int (standing it cost), fallen: bool}
## Cleared when the next day starts.
var released_today := []
## Last night's report, kept so the Menu can show it again.
var previous_report := {}
var is_end_check_open := false
## True from End Day until the night's report (or the credits) shows. The
## quests have already played out by then (gold, odds and injuries changed),
## so the End Day sheet stays as the player left it while the dusk falls.
var is_night_falling := false
var is_welcome_open := true
var is_menu_open := false
## The Game Over ledger's numbers, or {} while the run is still going.
## Filled once by _check_run_over (see build_run_over_stats for the keys).
var run_over_stats := {}
## The final battle's credits roll (overlay_credits.gd), or {} when hidden.
## Filled by end_day on FINAL_DAY (see HallLedger.build_credits for the keys).
## It covers every other overlay: a win leaves through start_freeplay, a loss
## through start_new_run.
var shown_credits := {}
## True once the final battle is lost: the run is over (is_run_over), and the
## defeat credits stand in for the Game Over ledger.
var final_battle_lost := false

# ---- the run so far

## Tallies for the Game Over ledger. This script is reloaded for every new run,
## so they start from zero each time:
##   gold_earned:  gold paid out by quests (int)
##   quests_sent:  parties that went out (int)
##   quests_won:   of those, how many succeeded (int)
##   heroes_hired: recruits hired from For Hire (int)
##   drake_result: DRAKE_RESULT_NONE | _SLAIN | _LOST
##   released:     every GuildCharacter let go this run (Array)
##   gold_spent:   gold paid for recruits, buildings, goods and revivals (int)
##   items_found:  equipment brought back from quests (int)
##   final_result: FINAL_RESULT_NONE | _WON | _LOST
##   final_party:  the GuildCharacters sent to the final battle (Array)
var run_stats := {
	"gold_earned": 0,
	"quests_sent": 0,
	"quests_won": 0,
	"heroes_hired": 0,
	"drake_result": DRAKE_RESULT_NONE,
	"released": [],
	"gold_spent": 0,
	"items_found": 0,
	"final_result": FINAL_RESULT_NONE,
	"final_party": [],
}

# ---- player choices

## Assign Party: also list adventurers already in another quest's party
## (sent or picked). Off by default, so the list only shows who's free.
var show_busy_adventurers := false
## The day the player last opened For Hire (the Guild badge clears then).
var for_hire_last_seen_day := 0
## Colorblind filter: index into HallSettings.COLOR_FILTERS (0 = off). Saved by HallSettings.
var color_filter := 0
## Reduced Motion: animations off (HallFx.reduce_motion mirrors it). Saved by HallSettings.
var reduce_motion := false

# ---- motion

## One-shot hints from an action to the rows the next refresh rebuilds, so the
## right row can animate ("this is the quest you just sent"). Cleared at the
## end of every refresh. Keys:
##   quest_stamp: int (quest index just sent / denied; its Board row and strip tab stamp in)
##   writ_stamp: bool (the quest on Assign Party was just sent: SENT is pressed onto it)
##   seat_in: GuildCharacter (just pinned to the party)
##   seat_out: bool (someone was just unpinned; the emptied seat fades in)
##   hire_next: bool (a letter was just hired; the next one slides up)
##   upgraded: int (GuildUpgrades.Building just built)
##   home_row: GuildCharacter (just moved in the Training Yard / Hospital)
##   gear_in: StandardItem (just equipped) / gear_out: bool (just taken off)
##   bought: int (ItemShop stock index just bought)
var pending_fx := {}
## Full-screen layer for motion that outlives a refresh (flying coins, floating
## numbers, stamps, the dusk wash). Above the overlays, below Pip.
var fx_layer: Control

# ---- internal

## True while a refresh is waiting for the end of the frame.
var _is_refresh_queued := false
## Which tab / screen was showing at the last refresh (to know when to scroll to top).
var _last_view_key := ""
## Pip, the tutorial coach (built in _ready, sits on top of every overlay).
var tutorial: Control


# ============================================================ NODES

# ---- shell (each is its own scene in MobileHall/Scenes/Shell/)
@onready var _header: HallHeader = %Header
@onready var _action_bar: HallActionBar = %ActionBar
@onready var _nav: HallNav = %Nav
@onready var _toast: HallToast = %Toast

# ---- content
@onready var _tabs := {"board": %TabBoard, "guild": %TabGuild, "upgrades": %TabUpgrades, "shop": %TabShop}
@onready var _screens := {SCREEN_ASSIGN: %ScreenAssign, SCREEN_CHARACTER: %ScreenCharacter}

# ---- overlays
@onready var _end_check_overlay: Control = %OverlayEndDay
@onready var _report_overlay: Control = %OverlayReport
@onready var _welcome_overlay: Control = %OverlayWelcome
@onready var _menu_overlay: Control = %OverlayMenu
@onready var _game_over_overlay: Control = %OverlayGameOver
@onready var _credits_overlay: Control = %OverlayCredits

# ---- colorblind filter
@onready var _color_filter: ColorRect = %ColorFilter


# ============================================================ SETUP

func _ready() -> void:
	# every shell piece, tab, screen and overlay gets a reference back to this script
	var views: Array = [_header, _action_bar, _nav] + _tabs.values() + _screens.values() + _all_overlays()
	for view in views:
		view.setup(self)

	# game systems -> redraw
	GameState.day_started.connect(_on_day_started)
	GameState.resources_changed.connect(queue_refresh)
	GuildUpgrades.upgrades_changed.connect(queue_refresh)
	GuildUpgrades.home_changed.connect(queue_refresh)
	CharacterContainer.on_character_added.connect(queue_refresh)
	CharacterContainer.on_character_removed.connect(queue_refresh)
	CharacterContainer.on_hireables_refreshed.connect(queue_refresh)
	ItemShop.stock_changed.connect(queue_refresh)
	ItemShop.gear_changed.connect(queue_refresh)

	# motion that outlives a refresh lives here, over the overlays and under Pip
	fx_layer = Control.new()
	fx_layer.name = "FxLayer"
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.z_index = FX_LAYER_Z_INDEX
	add_child(fx_layer)
	fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# the tutorial coach goes on top of everything; on Day 1 it replaces the Welcome card
	tutorial = OverlayTutorial.new()
	tutorial.name = "OverlayTutorial"
	add_child(tutorial)
	tutorial.setup(self)

	_load_settings()
	_generate_quests()
	refresh()
	# a playtest scenario can start already stuck. Deferred: the scenario
	# builds its roster in its own _ready, which runs after this one
	_check_run_over.call_deferred()


func _on_day_started(_day: int) -> void:
	_generate_quests()
	queue_refresh()


## Fill quest_entries for today (see HallRules.build_day_quests).
func _generate_quests() -> void:
	quest_entries = HallRules.build_day_quests(GameState.day, GuildUpgrades.standing, GameState.is_freeplay)


## Freeplay's multiplier on today's quest requirements and rewards (see HallRules.freeplay_scale).
func freeplay_scale() -> float:
	return HallRules.freeplay_scale(GameState.day)


# ============================================================ QUERIES
# Read-only questions the screens ask. None of these change anything.

# ---- roster

## Everyone in the guild.
func roster() -> Array:
	return CharacterContainer.active_characters


## True when every bed is taken by a living hero (no more hiring or reviving).
func is_roster_full() -> bool:
	return not CharacterContainer.has_free_bed()


## Standing it costs to release this hero: nothing for the fallen, otherwise
## RELEASE_BASE_STANDING_COST plus their Pluck.
func release_standing_cost(character: GuildCharacter) -> int:
	if HallStyle.is_dead(character):
		return 0
	return RELEASE_BASE_STANDING_COST + character.pluck


## True when there's at least one recruit and a free bed.
func can_hire_anyone() -> bool:
	return not CharacterContainer.hireable_characters.is_empty() and not is_roster_full()


## Recruits the player hasn't looked at yet today (drives the Guild badge).
func unseen_recruit_count() -> int:
	if for_hire_last_seen_day == GameState.day or is_roster_full():
		return 0
	return CharacterContainer.hireable_characters.size()

# ---- the run


## True when the guild can never send anyone out again (see HallLedger.is_run_over),
## or the final battle was lost (that ends the story, whoever is left).
func is_run_over() -> bool:
	return final_battle_lost or HallLedger.is_run_over()


## True when one hero is left alive and losing them would (or nearly would)
## end the run (see HallLedger). Drives the header's warning strip.
func is_one_death_from_falling() -> bool:
	return HallLedger.is_one_death_from_falling()


## The one living member of the guild, or null if there isn't exactly one.
func last_living_hero() -> GuildCharacter:
	return HallLedger.last_living_hero(roster())


## Everything the Game Over ledger shows (see HallLedger.build_run_over_stats for the keys).
func build_run_over_stats() -> Dictionary:
	return HallLedger.build_run_over_stats(run_stats, roster())


## The run's extra records for the credits roll (see HallLedger.build_run_records for the keys).
func build_run_records() -> Dictionary:
	return HallLedger.build_run_records(run_stats, roster())


## Everything the final battle's credits roll shows (see HallLedger.build_credits).
## result: the final quest's _run_quest result.
func build_credits(result: Dictionary) -> Dictionary:
	return HallLedger.build_credits(result, run_stats, roster())

# ---- quests


## Quests still needing Send or Deny. Same rule as QuestCard.is_outstanding.
func undecided_count() -> int:
	return quest_entries.filter(func(entry): return entry.state == HallStyle.QUEST_STATE_OPEN).size()


## Quests that have been sent or denied.
func decided_count() -> int:
	return quest_entries.size() - undecided_count()


## Entries whose party goes out tonight.
func sent_entries() -> Array:
	return quest_entries.filter(func(entry): return entry.state == HallStyle.QUEST_STATE_SENT)


func denied_entries() -> Array:
	return quest_entries.filter(func(entry): return entry.state == HallStyle.QUEST_STATE_DENIED)


## Index of the quest whose party (sent or draft) has this character, or -1.
func quest_index_of(character: GuildCharacter) -> int:
	for quest_index in quest_entries.size():
		if quest_entries[quest_index].party.has(character):
			return quest_index
	return -1


## False for anyone who can't be put in a party (dead, training, or in a Hospital bed).
func can_go_on_quests(character: GuildCharacter) -> bool:
	return not HallStyle.is_dead(character) and not GuildUpgrades.is_patient(character) \
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


## Pluck each party member gains for winning a quest sent at `chance` percent
## (see HallRules.pluck_gain_for).
func pluck_gain_for(chance: float) -> int:
	return HallRules.pluck_gain_for(chance)


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
		if quest_entries[quest_index].state == HallStyle.QUEST_STATE_OPEN:
			return quest_index
	return -1

# ---- upgrades and countdown


## True while Pip holds a bottom tab back (see OverlayTutorial.UNLOCK_DAY).
func is_tab_locked(tab_id: String) -> bool:
	return tutorial != null and tutorial.is_tab_locked(tab_id)


## The day a locked tab opens (see is_tab_locked).
func tab_unlock_day(tab_id: String) -> int:
	return tutorial.unlock_day(tab_id) if tutorial != null else 0


## Buildings that can be upgraded right now (enough gold and standing).
## None while the Guild tab (id "upgrades") is still locked, so nothing
## (the End Day sheet, the Board note, the badge) offers them early.
func affordable_buildings() -> Array:
	if is_tab_locked("upgrades"):
		return []
	return HallStyle.buildings_in_order().filter(func(building):
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
	if is_tab_locked(tab_id):
		show_toast(TOAST_TAB_LOCKED % tab_unlock_day(tab_id))
		return
	active_tab = tab_id
	if section != "" and tab_id == "guild":
		guild_section = section
	elif section != "" and tab_id == "upgrades":
		upgrades_section = section
	if active_tab == "guild" and guild_section == GUILD_SECTION_HIRE:
		for_hire_last_seen_day = GameState.day
	active_screen = {}
	queue_refresh()
	tutorial_event.emit("tab", {"tab": active_tab, "guild": guild_section, "upgrades": upgrades_section})


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
	tutorial_event.emit("assign", quest_index)


## Open a character's details over whatever is showing.
func open_character(character: GuildCharacter) -> void:
	active_screen = {"kind": SCREEN_CHARACTER, "character": character, "return_to": active_screen.duplicate()}
	queue_refresh()
	tutorial_event.emit("character", character)


## Character goes back to wherever it was opened from; Assign Party goes to the Board.
func close_screen() -> void:
	if active_screen.get("kind", "") == SCREEN_CHARACTER:
		active_screen = active_screen.get("return_to", {})
	else:
		active_screen = {}
	queue_refresh()
	tutorial_event.emit("close", null)


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
	if entry.is_empty() or entry.state == HallStyle.QUEST_STATE_DENIED:
		return

	# already in this party: take them out
	if entry.party.has(character):
		_remove_from_party(entry, character)
		pending_fx.seat_out = true
		queue_refresh()
		return

	# can't be added
	if HallStyle.is_dead(character):
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
	pending_fx.seat_in = character
	queue_refresh()
	tutorial_event.emit("pick", entry)


## Take someone out of a party. A sent quest left with nobody goes back to open.
func _remove_from_party(entry: Dictionary, character: GuildCharacter) -> void:
	entry.party.erase(character)
	if entry.party.is_empty() and entry.state == HallStyle.QUEST_STATE_SENT:
		entry.state = HallStyle.QUEST_STATE_OPEN


## Assign Party's "Show busy" toggle.
func set_show_busy_adventurers(is_on: bool) -> void:
	show_busy_adventurers = is_on
	queue_refresh()


## Send the party, then jump to the next undecided quest (or back to the Board).
func send_party() -> void:
	var entry := current_quest_entry()
	if entry.is_empty() or entry.party.is_empty():
		return
	entry.state = HallStyle.QUEST_STATE_SENT
	show_toast(TOAST_SENT % entry.quest.questTitle)
	pending_fx.writ_stamp = true
	_hold_then_move_on()
	tutorial_event.emit("send", entry)


## Turn the quest down (costs standing), then jump to the next undecided quest.
func deny_quest() -> void:
	var entry := current_quest_entry()
	if entry.is_empty():
		return
	entry.party.clear()
	entry.state = HallStyle.QUEST_STATE_DENIED
	if entry.quest.difficulty > 0:
		_header.pay_fx("standing")
	GameState.reduce_standing(entry.quest.difficulty)
	show_toast(TOAST_DENIED % entry.quest.questTitle)
	_screens[SCREEN_ASSIGN].shake_writ()
	HallFx.stamp_mark(fx_layer, _screens[SCREEN_ASSIGN].stamp_point(), STAMP_DENIED, HallStyle.RED, STAMP_HOLD_SECONDS)
	_hold_then_move_on()
	tutorial_event.emit("deny", entry)


## Undo Send: the party goes back to being a draft.
func recall_party() -> void:
	var entry := current_quest_entry()
	if entry.is_empty():
		return
	entry.state = HallStyle.QUEST_STATE_OPEN
	show_toast(TOAST_RECALLED)
	queue_refresh()


## Undo Deny: the quest is open again (the standing lost isn't given back).
func reconsider_quest() -> void:
	var entry := current_quest_entry()
	if entry.is_empty():
		return
	entry.state = HallStyle.QUEST_STATE_OPEN
	show_toast(TOAST_RECONSIDER % entry.quest.questTitle)
	queue_refresh()


## After Send / Deny: the quest shows its new state (Send presses SENT onto it,
## Deny slams DENIED over it), taps wait STAMP_HOLD_SECONDS, then the next
## undecided quest shows (or the Board) and that quest's row / strip tab stamps in.
func _hold_then_move_on() -> void:
	var decided_index: int = active_screen.quest_index
	queue_refresh()
	if HallFx.reduce_motion:
		_after_stamp(decided_index)
		return
	HallFx.block_input(fx_layer, STAMP_HOLD_SECONDS)
	get_tree().create_timer(STAMP_HOLD_SECONDS).timeout.connect(_after_stamp.bind(decided_index))


func _after_stamp(decided_index: int) -> void:
	pending_fx.quest_stamp = decided_index
	# something else (Pip, End Day) may have closed Assign Party meanwhile
	if active_screen.get("kind", "") != SCREEN_ASSIGN:
		queue_refresh()
		return
	_go_to_next_undecided()


## Show the next undecided quest, or close to the Board.
func _go_to_next_undecided() -> void:
	var next_index := next_undecided_index(active_screen.quest_index + 1)
	if next_index < 0:
		active_screen = {}
	else:
		active_screen.quest_index = next_index
	queue_refresh()

# ---- guild


## Returns true when they joined (hire_card.gd then flies its letter to the roster).
func hire(character: GuildCharacter) -> bool:
	if is_roster_full():
		show_toast(TOAST_ROSTER_FULL)
		queue_refresh()
		return false
	var gold_before: int = GameState.gold
	var is_hired: bool = CharacterContainer.add_character_to_guild(character)
	if is_hired:
		run_stats.heroes_hired += 1
		_count_spent(gold_before)
		if GameState.gold < gold_before:
			_header.pay_fx("gold")
		pending_fx.hire_next = true
		show_toast(TOAST_HIRED % character.name)
		tutorial_event.emit("hire", character)
	queue_refresh()
	return is_hired


## The hired letter lifts off its stack, gets HIRED pressed onto it, sits a
## moment, then flies into the "Your Guild" tab, which pops as it lands.
## (The next letter slides up underneath meanwhile.)
func send_hired_letter(card: Control) -> void:
	if HallFx.reduce_motion:
		return
	# off the stack first, so the refresh that's coming can't free it
	HallFx.detach(card, fx_layer)
	HallFx.stamp_onto(card, STAMP_HIRED, HallStyle.GREEN_TEXT, HIRE_STAMP_AT, HIRE_STAMP_FONT_SIZE, HIRE_STAMP_TILT)
	get_tree().create_timer(HIRE_STAMP_HOLD_SECONDS).timeout.connect(_fly_hired_letter.bind(card))


func _fly_hired_letter(card: Control) -> void:
	if not is_instance_valid(card):
		return
	var roster_button: Control = _tabs.guild.roster_button()
	HallFx.fly_away(card, fx_layer, roster_button.get_global_rect().get_center(), HIRE_FLY_SECONDS)
	HallFx.pop(roster_button, HallNav.BADGE_POP, HIRE_FLY_SECONDS)


## Let a hero go for good (the Character screen's Release button, after its
## confirm sheet). They leave any quest party first (a sent quest left empty
## goes back to open), then CharacterContainer takes their gear off and frees
## their training slot and Hospital bed. Living heroes cost standing.
func release(character: GuildCharacter) -> void:
	# read these before they leave: the cost depends on who they are right now
	var standing_cost := release_standing_cost(character)
	var is_fallen := HallStyle.is_dead(character)
	_leave_quest(character)
	if not CharacterContainer.remove_character_from_guild(character):
		return
	if standing_cost > 0:
		_header.pay_fx("standing")
		GameState.reduce_standing(standing_cost)
		show_toast(TOAST_RELEASED_COST % [character.name, standing_cost])
	else:
		show_toast(TOAST_RELEASED % character.name)
	released_today.append({"character": character, "standing": standing_cost, "fallen": is_fallen})
	run_stats.released.append(character)
	queue_refresh()
	# releasing the last living hero can leave the guild stuck
	_check_run_over()


func upgrade_building(building: int) -> void:
	# buildings open with the Guild tab
	if is_tab_locked("upgrades"):
		show_toast(TOAST_TAB_LOCKED % tab_unlock_day("upgrades"))
		return
	var gold_before: int = GameState.gold
	if GuildUpgrades.try_upgrade(building):
		_count_spent(gold_before)
		_header.pay_fx("gold")
		pending_fx.upgraded = building
		show_toast(TOAST_UPGRADED % [GuildUpgrades.get_building_name(building), GuildUpgrades.get_level(building)])
		tutorial_event.emit("upgrade", building)
	queue_refresh()


# ---- Shop and gear (ItemShop autoload)


## Buy one of today's goods (index into ItemShop.stock).
func buy_item(index: int) -> void:
	var item := ItemShop.get_item(index)
	if item == null or ItemShop.is_sold(index):
		return
	var gold_before: int = GameState.gold
	if ItemShop.buy(index):
		_count_spent(gold_before)
		if item.cost > 0:
			_header.pay_fx("gold")
		pending_fx.bought = index
		show_toast(TOAST_BOUGHT % HallStyle.item_look(item).name)
		tutorial_event.emit("buy", item)
	else:
		show_toast(TOAST_CANT_BUY)
	queue_refresh()


## Put an owned item on a hero (moves it off whoever had it).
func equip_item(item: StandardItem, character: GuildCharacter) -> void:
	var item_name: String = HallStyle.item_look(item).name
	var result: int = ItemShop.equip(item, character)
	if result == ItemShop.EquipResult.OK:
		pending_fx.gear_in = item
		show_toast(TOAST_EQUIPPED % [character.name, item_name])
		tutorial_event.emit("equip", item)
	elif result == ItemShop.EquipResult.WRONG_ROLE:
		show_toast(TOAST_WRONG_ROLE % [HallStyle.item_role_name(item), item_name])
	elif result == ItemShop.EquipResult.SLOTS_FULL:
		show_toast(TOAST_HANDS_FULL % character.name)
	elif result == ItemShop.EquipResult.DEAD:
		show_toast(TOAST_GEAR_DEAD % character.name)
	queue_refresh()


## Take an item off whoever is wearing it (it goes back in the pack).
func unequip_item(item: StandardItem) -> void:
	var user: GuildCharacter = item.curr_user
	if user == null:
		return
	ItemShop.unequip(item)
	pending_fx.gear_out = true
	show_toast(TOAST_UNEQUIPPED % [user.name, HallStyle.item_look(item).name])
	queue_refresh()


# ---- Upgrades > Tonight: Training Yard and Hospital


## "+ Add a hero" under the Training Yard: show / hide who can train.
func toggle_training_picker() -> void:
	training_picker_open = not training_picker_open
	queue_refresh()
	tutorial_event.emit("training_picker", training_picker_open)


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
	pending_fx.home_row = character
	if is_new:
		show_toast(TOAST_TRAINING % [character.name, HallStyle.STATS[stat].name])
	# the pick list closes itself once every slot is taken
	if not GuildUpgrades.has_free_training_slot():
		training_picker_open = false
	queue_refresh()
	tutorial_event.emit("train", character)


func stop_training(character: GuildCharacter) -> void:
	GuildUpgrades.stop_training(character)
	show_toast(TOAST_STOPPED_TRAINING % character.name)
	queue_refresh()


## Put a hurt hero in a Hospital bed (they leave any party or training slot).
func admit(character: GuildCharacter) -> void:
	_leave_quest(character)
	if GuildUpgrades.admit(character):
		pending_fx.home_row = character
		show_toast(TOAST_ADMITTED % character.name)
		tutorial_event.emit("admit", character)
	queue_refresh()


func discharge(character: GuildCharacter) -> void:
	GuildUpgrades.discharge(character)
	pending_fx.home_row = character
	show_toast(TOAST_DISCHARGED % character.name)
	queue_refresh()


func revive(character: GuildCharacter) -> void:
	var gold_before: int = GameState.gold
	if GuildUpgrades.revive(character):
		_count_spent(gold_before)
		pending_fx.home_row = character
		show_toast(TOAST_REVIVED % character.name)
	elif is_roster_full():
		show_toast(TOAST_REVIVE_NO_BED % character.name)
	queue_refresh()


## Add whatever gold left the wallet since `gold_before` to run_stats.gold_spent
## (for the credits' records). Call it right after a purchase went through.
func _count_spent(gold_before: int) -> void:
	run_stats.gold_spent += maxi(gold_before - GameState.gold, 0)


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
	set_color_filter((color_filter + 1) % HallSettings.COLOR_FILTERS.size())


func set_color_filter(filter_index: int) -> void:
	color_filter = HallSettings.clamp_color_filter(filter_index)
	_apply_color_filter()
	HallSettings.save_value(HallSettings.KEY_COLOR_FILTER, color_filter)
	queue_refresh()


## Menu's Reduced Motion button: on <-> off.
func toggle_reduce_motion() -> void:
	set_reduce_motion(not reduce_motion)


## Reduced Motion: hall_fx.gd skips every animation and lands things in place.
func set_reduce_motion(is_on: bool) -> void:
	reduce_motion = is_on
	HallFx.reduce_motion = is_on
	HallSettings.save_value(HallSettings.KEY_REDUCE_MOTION, reduce_motion)
	queue_refresh()


func _load_settings() -> void:
	var settings := HallSettings.load_settings()
	color_filter = settings.color_filter
	reduce_motion = settings.reduce_motion
	HallFx.reduce_motion = reduce_motion
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
	tutorial_event.emit("end_check", null)


func close_end_check() -> void:
	is_end_check_open = false
	queue_refresh()


## Mirrors DayBar.end_day: run every quest that has a party, pay out, show the report.
## Dusk washes over the screen while the night plays out; the report shows
## under it. The gold / standing counters hold still until dawn (start_new_day),
## so the night's earnings land when the doors open.
func end_day() -> void:
	# (a second tap while the dusk falls would play the night out twice)
	if undecided_count() > 0 or is_night_falling:
		return
	is_night_falling = true
	_header.hold_counters()
	# training and healing happen first, so nobody heals the night they're hurt
	var home := GuildUpgrades.run_night()
	var results := []
	for entry in sent_entries():
		results.append(_run_quest(entry))
	var report := {"starts_next_day": true, "day": GameState.day, "results": results, "home": home,
			"released": released_today.duplicate()}

	# the final battle's night rolls the credits (victory or defeat) instead of the Day Report
	var final_results := results.filter(func(result): return result.final)
	if not final_results.is_empty():
		_show_final_credits(final_results[0], report)
		return

	var show_report := func() -> void:
		is_night_falling = false
		is_end_check_open = false
		training_picker_open = false
		active_screen = {}
		shown_report = report
		queue_refresh()
		tutorial_event.emit("end_day", results)
	HallFx.curtain(fx_layer, DUSK_INK, show_report, 0.92, DUSK_IN_SECONDS, DUSK_OUT_SECONDS)


## End Day on FINAL_DAY: freeze the run's numbers into shown_credits and open
## the credits roll under the dusk wash (a slower, darker one for a defeat).
## result = the final quest's _run_quest result, report = the night's Day
## Report, kept for the Menu's "Last night's report".
func _show_final_credits(result: Dictionary, report: Dictionary) -> void:
	var credits := build_credits(result)
	final_battle_lost = not credits.won
	var show_credits := func() -> void:
		is_night_falling = false
		is_end_check_open = false
		is_menu_open = false
		training_picker_open = false
		active_screen = {}
		previous_report = report.duplicate()
		previous_report.starts_next_day = false
		shown_credits = credits
		if tutorial and tutorial.is_running():
			tutorial.skip_tutorial()
		queue_refresh()
		tutorial_event.emit("end_day", report.results)
	if credits.won:
		HallFx.curtain(fx_layer, DUSK_INK, show_credits, 0.92, DUSK_IN_SECONDS, DUSK_OUT_SECONDS)
	else:
		HallFx.curtain(fx_layer, DUSK_INK, show_credits, 1.0, DEFEAT_DUSK_IN_SECONDS, DEFEAT_DUSK_OUT_SECONDS)


## Play out one quest (HallRules.play_quest pays its gold and standing) and
## add it to the run's tallies. Returns the Day Report result (see HallRules.play_quest).
func _run_quest(entry: Dictionary) -> Dictionary:
	var result := HallRules.play_quest(entry, GameState.day)
	# tallies for the Game Over ledger
	run_stats.quests_sent += 1
	run_stats.gold_earned += result.gold
	if result.succeeded:
		run_stats.quests_won += 1
	if entry.milestone:
		run_stats.drake_result = DRAKE_RESULT_SLAIN if result.succeeded else DRAKE_RESULT_LOST
	if entry.final:
		run_stats.final_result = FINAL_RESULT_WON if result.succeeded else FINAL_RESULT_LOST
		run_stats.final_party = entry.party.duplicate()
	run_stats.items_found += result.items.size()
	return result


## DaySummary's "New Day" button. Keeps tonight's report for the Menu and opens on the Board.
func start_new_day() -> void:
	previous_report = shown_report.duplicate()
	previous_report.starts_next_day = false
	shown_report = {}
	# today's releases are in the kept report now; tomorrow starts a fresh list
	released_today.clear()
	active_tab = "board"
	active_screen = {}
	GameState.start_new_day()
	if GameState.day == MILESTONE_DAY:
		show_toast(TOAST_MILESTONE_DAY % GameState.day)
	elif GameState.day == FINAL_DAY and not GameState.is_freeplay:
		show_toast(TOAST_FINAL_DAY % GameState.day)
	else:
		var quests_text := HallStyle.count_text(quest_entries.size(), "new quest", "new quests")
		show_toast(TOAST_NEW_DAY % [GameState.day, quests_text, CharacterContainer.hireable_characters.size()])
	queue_refresh()
	_header.land_earnings()
	tutorial_event.emit("new_day", GameState.day)
	# checked after the Day Report closes, so the player reads how the heroes fell first
	_check_run_over()


## If the guild is stuck (is_run_over), freeze the ledger's numbers and open
## the Game Over overlay. Pip stops coaching: there's nothing left to teach.
func _check_run_over() -> void:
	# a lost final battle already has its own ending (the defeat credits)
	if not run_over_stats.is_empty() or not shown_credits.is_empty() or not is_run_over():
		return
	run_over_stats = build_run_over_stats()
	is_end_check_open = false
	is_menu_open = false
	is_welcome_open = false
	active_screen = {}
	if tutorial and tutorial.is_running():
		tutorial.skip_tutorial()
	queue_refresh()
	tutorial_event.emit("game_over", run_over_stats)


## The Game Over ledger's "Found a New Guild" button: every autoload goes back
## to a fresh Day 1, then the hall scene is loaded again (which resets this
## script's state, the Welcome card and Pip).
func start_new_run() -> void:
	GameState.reset()
	GuildUpgrades.reset()
	ItemContainer.owned_items.clear()
	ItemShop.restock()
	# after GameState.reset, so For Hire is sized for Day 1
	CharacterContainer.reset()
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


## The victory credits' "Begin Freeplay" button: the story is over, so the
## days go on without end (GameState.is_freeplay) and quests keep scaling up
## (HallRules.freeplay_scale, the S++ rank). Dawn breaks on the next day under
## the usual dusk wash, then Pip explains freeplay (the "freeplay" tutorial event).
func start_freeplay() -> void:
	if shown_credits.is_empty() or not shown_credits.won:
		return
	var begin := func() -> void:
		GameState.is_freeplay = true
		shown_credits = {}
		# the night's report was already kept for the Menu by _show_final_credits
		shown_report = {}
		start_new_day()
		tutorial_event.emit("freeplay", GameState.day)
	HallFx.curtain(fx_layer, DUSK_INK, begin, 0.92, DUSK_IN_SECONDS, DUSK_OUT_SECONDS)


## The report's button: starts the next day after End Day (under a dusk wash,
## so the report, the new Board and the day flip don't all snap at once),
## otherwise just closes.
func close_report() -> void:
	if shown_report.get("starts_next_day", false):
		HallFx.curtain(fx_layer, DUSK_INK, start_new_day, 0.92, DUSK_IN_SECONDS, DUSK_OUT_SECONDS)
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
	# start_new_run swaps this scene out; a refresh queued by its resets lands
	# after that, on a hall that's no longer in the tree
	if not is_inside_tree():
		return
	_header.refresh()
	_refresh_content()
	_action_bar.refresh()
	_nav.refresh()
	_refresh_overlays()
	# every rebuilt row has read its hint by now
	pending_fx.clear()

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
	# (a new view fades in, so switching tabs reads as switching)
	if view_key != _last_view_key:
		if _last_view_key != "":
			HallFx.fade_in(shown_view, 0.0, VIEW_FADE_SECONDS)
		_last_view_key = view_key
		shown_view.scroll_to_top()

# ---- shell pieces Pip points at (overlay_tutorial.gd)


## The nav button for a tab id (one of TAB_IDS).
func nav_button(tab_id: String) -> Button:
	return _nav.button(tab_id)


## The action bar's big button.
func action_button() -> Button:
	return _action_bar.button()

# ---- overlays


## The credits roll hides every other overlay, then the Game Over ledger;
## the Day Report hides the rest.
func _refresh_overlays() -> void:
	var is_credits_open := not shown_credits.is_empty()
	_credits_overlay.visible = is_credits_open
	var is_game_over := not run_over_stats.is_empty() and not is_credits_open
	_game_over_overlay.visible = is_game_over
	var is_report_open := not shown_report.is_empty() or is_game_over or is_credits_open
	_report_overlay.visible = not shown_report.is_empty() and not is_game_over and not is_credits_open
	_end_check_overlay.visible = not is_report_open and is_end_check_open
	_menu_overlay.visible = not is_report_open and is_menu_open
	_welcome_overlay.visible = not is_report_open and is_welcome_open
	for overlay in _all_overlays():
		if overlay.visible:
			overlay.refresh()


func _all_overlays() -> Array:
	return [_report_overlay, _end_check_overlay, _menu_overlay, _welcome_overlay, _game_over_overlay, _credits_overlay]


# ============================================================ TOAST

## Short message just above the action bar that fades out (see hall_toast.gd).
func show_toast(message: String) -> void:
	_toast.show_message(message)


# ============================================================ MOTION
# The counters' motion lives in hall_header.gd; rows animate from pending_fx;
# everything else is hall_fx.gd.

## Where the player last pressed (global), for things that fly to / from their tap.
func tap_point() -> Vector2:
	return get_global_mouse_position()
