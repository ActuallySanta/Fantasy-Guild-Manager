## The final battle's credits roll (HallMain.FINAL_DAY), in one of two moods:
##   - victory: a warm hall, the night's events rolling up the screen like a
##     film's end credits, then the "Begin Freeplay" button (HallMain.start_freeplay)
##   - defeat:  a cold, slower roll with an epitaph that ends the run, then the
##     "Found a New Guild" button (HallMain.start_new_run)
## Top to bottom: title, the quest's story one line at a time, the final
## battle's party (those three are a CrawlSections), a parchment ledger (final stats, run records, roll call),
## the team credits (Data/credits.tres, see CreditsList), and a
## closing line.
##
## The roll scrolls itself (CrawlRoll) after a short delay. Any touch, drag or wheel hands
## it to the player for good. The button waits until the bottom is first
## reached, then stays, so the player can scroll back up and still leave.
## Reduced Motion: no auto-scroll, and the roll starts at its title.
## Reads HallMain.shown_credits (see HallMain.build_credits).
## Scene: Scenes/Overlays/Run End/overlay_credits.tscn
extends Control

const RollCallRowScene := preload("uid://bqn0i28l67um7")  # Scenes/Rows/Day End/roll_call_row.tscn
## The team credits (edit them in the inspector; see credits_list.gd).
const TEAM_CREDITS: CreditsList = preload("uid://c72de0tnaska")  # Data/credits.tres

# ---- MOTION
## (The start delay and the bottom check live in CrawlRoll.)
## How fast the roll moves (pixels per second) on a victory, and on a defeat.
const SCROLL_SPEED := 70.0
const DEFEAT_SCROLL_SPEED := 50.0
## Share of the screen's height left blank above the title, so the roll
## starts from the bottom of the screen like film credits. (Reduced Motion
## uses none: the title shows straight away.)
const TOP_SPACE_SHARE := 0.85
## Blank space under the closing line (pixels), so it can scroll up past the
## pinned button instead of ending under it.
const BOTTOM_SPACE := 520.0

# ---- LOOK
## Font sizes: team names, contributions. (The story and party lines are sized by CrawlSections.)
const TEAM_NAME_FONT_SIZE := 38
const TEAM_ROLE_FONT_SIZE := 26
## Section headings on the dark roll (party, team sections).
const HEADING_FONT_SIZE := 28
## Font size of the number on the big Days tile.
const DAYS_FONT_SIZE := 110

# ---- TEXT
const TEXT_TITLE := "The Final Battle"
const TEXT_SUB := "Day %d · Victory"
const TEXT_END := "The End"
const TEXT_END_SUB := "...though the guild's doors stay open."
# ==== FINAL QUEST DEFEAT TEXT ===============================================
# PLACEHOLDER lines for losing the final battle. Swap in the real final
# quest's epitaph and closing words once it's written.
const TEXT_DEFEAT_TITLE := "The Last Stand Has Fallen"
const TEXT_DEFEAT_SUB := "Day %d. The final battle was lost, and with it the guild's tale."
const TEXT_DEFEAT_END := "Here Ends the Tale"
const TEXT_DEFEAT_END_SUB := "May the songs remember them."
# ==== END FINAL QUEST DEFEAT TEXT ===========================================
const TEXT_STORY_HEADING := "The Battle"
const TEXT_PARTY_HEADING := "Who Stood at the End"
const TEXT_DEFEAT_PARTY_HEADING := "The Fallen and the Few"
const TEXT_FELL := "fell in the final battle"
const TEXT_TEAM_HEADING := "Made By"
const TEXT_DAYS_CAPTION := "days of the guild"
const TEXT_GOLD_CAPTION := "gold earned"
const TEXT_QUESTS := "%d/%d"
const TEXT_QUESTS_CAPTION := "quests won"
const TEXT_HIRED_CAPTION := "heroes hired"
const TEXT_FALLEN_CAPTION := "heroes fallen"
const TEXT_STANDING_CAPTION := "final standing"
const TEXT_SPENT_CAPTION := "gold spent"
const TEXT_ITEMS_CAPTION := "items found"
const TEXT_SERVICE_CAPTION := "days served by %s"
const TEXT_SERVICE_NOBODY := "no one served"
const TEXT_BUILDING := "%s · level %d"
const TEXT_NOBODY := "No hero ever joined this guild."
const BUTTON_FREEPLAY := "Begin Freeplay"
const BUTTON_NEW_RUN := "Found a New Guild"

# ---- NODES
@onready var _bg: ColorRect = %Bg
@onready var _scroll: ScrollContainer = %Scroll
@onready var _top_space: Control = %TopSpace
@onready var _sections: CrawlSections = %Sections
# the parchment ledger (dark ink, so it keeps the scene's colours)
@onready var _days_tile = %DaysTile          # stat_tile.gd
@onready var _gold_tile = %GoldTile          # stat_tile.gd
@onready var _quests_tile = %QuestsTile      # stat_tile.gd
@onready var _hired_tile = %HiredTile        # stat_tile.gd
@onready var _fallen_tile = %FallenTile      # stat_tile.gd
@onready var _standing_tile = %StandingTile  # stat_tile.gd
@onready var _spent_tile = %SpentTile        # stat_tile.gd
@onready var _items_tile = %ItemsTile        # stat_tile.gd
@onready var _service_tile = %ServiceTile    # stat_tile.gd
@onready var _buildings: VBoxContainer = %Buildings
@onready var _roll_call: VBoxContainer = %RollCall
@onready var _empty_label: Label = %Empty
# after the ledger
@onready var _team_heading: Label = %TeamHeading
@onready var _team: VBoxContainer = %Team
@onready var _end: Label = %End
@onready var _end_sub: Label = %EndSub
@onready var _bottom_space: Control = %BottomSpace
@onready var _footer: Control = %Footer
@onready var _action_button: Button = %ActionButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The credits currently built on screen (frozen once the final battle is over).
var _built_credits: Dictionary = {}
## The roll's motion: auto-scroll, hand-over to the player, the button at the bottom.
var _roll: CrawlRoll
## Ink for text on the dark roll: main and soft (set per mood).
var _ink := HallStyle.CREDITS_INK
var _ink_soft := HallStyle.CREDITS_INK_SOFT


func setup(main: HallMain) -> void:
	hall = main
	_action_button.pressed.connect(_on_action_pressed)
	HallStyle.style_button(_action_button, "gold", 46)
	_roll = CrawlRoll.new()
	add_child(_roll)
	_roll.setup(_scroll, _top_space, _bottom_space, _footer)


func refresh() -> void:
	var credits: Dictionary = hall.shown_credits
	if credits.is_empty() or credits == _built_credits:
		return
	_built_credits = credits
	var is_won: bool = credits.won
	_ink = HallStyle.CREDITS_INK if is_won else HallStyle.DEFEAT_INK
	_ink_soft = HallStyle.CREDITS_INK_SOFT if is_won else HallStyle.DEFEAT_INK_SOFT
	_bg.color = HallStyle.CREDITS_BG if is_won else HallStyle.DEFEAT_BG

	_show_titles(credits)
	_show_fight(credits)
	_show_stats(credits.stats)
	_show_records(credits.records)
	_show_roll_call(credits.stats.roll_call, credits.stats.released)
	_show_team()
	_action_button.text = BUTTON_FREEPLAY if is_won else BUTTON_NEW_RUN
	_start_roll()


## The victory button starts freeplay; the defeat button starts a new run.
func _on_action_pressed() -> void:
	if _built_credits.get("won", false):
		hall.start_freeplay()
	else:
		hall.start_new_run()

# ---- the roll


## Back to the top with the button hidden, then (motion allowed) wait and roll
## (see CrawlRoll). A defeat rolls slower.
func _start_roll() -> void:
	var speed := SCROLL_SPEED if _built_credits.get("won", false) else DEFEAT_SCROLL_SPEED
	_roll.start(speed, TOP_SPACE_SHARE, BOTTOM_SPACE)


# ---- sections


## Title, subtitle and the closing words, in the mood's wording and ink.
func _show_titles(credits: Dictionary) -> void:
	var is_won: bool = credits.won
	_sections.show_title(TEXT_TITLE if is_won else TEXT_DEFEAT_TITLE,
			(TEXT_SUB if is_won else TEXT_DEFEAT_SUB) % credits.day, _ink, _ink_soft)
	_end.text = TEXT_END if is_won else TEXT_DEFEAT_END
	_end_sub.text = TEXT_END_SUB if is_won else TEXT_DEFEAT_END_SUB
	_team_heading.text = TEXT_TEAM_HEADING
	HallStyle.set_font_color(_end, _ink)
	for label in [_end_sub, _team_heading]:
		HallStyle.set_font_color(label, _ink_soft)


## The final battle's story and party, as the one fight of the roll's sections.
func _show_fight(credits: Dictionary) -> void:
	var is_won: bool = credits.won
	_sections.clear()
	_sections.add_fight(TEXT_STORY_HEADING, credits.result.story, credits.result, is_won, _ink, _ink_soft,
			TEXT_PARTY_HEADING if is_won else TEXT_DEFEAT_PARTY_HEADING, TEXT_FELL)


## The Days tile and the grid of the run's numbers (the Game Over ledger's,
## without the Bone Drake).
func _show_stats(stats: Dictionary) -> void:
	_days_tile.setup(str(stats.days), TEXT_DAYS_CAPTION, HallStyle.TEXT_MAIN, DAYS_FONT_SIZE)
	_gold_tile.setup(str(stats.gold_earned), TEXT_GOLD_CAPTION, HallStyle.GOLD_TEXT)
	_quests_tile.setup(TEXT_QUESTS % [stats.quests_won, stats.quests_sent], TEXT_QUESTS_CAPTION, HallStyle.BLUE_TEXT)
	_hired_tile.setup(str(stats.heroes_hired), TEXT_HIRED_CAPTION, HallStyle.GREEN_TEXT)
	var dead_ink: Color = HallStyle.INJURY_LOOKS[GuildCharacter.InjuryLevel.DEAD].text
	_fallen_tile.setup(str(stats.fallen), TEXT_FALLEN_CAPTION, dead_ink)
	var standing: int = stats.standing
	_standing_tile.setup(str(standing), TEXT_STANDING_CAPTION, HallStyle.RED if standing < 0 else HallStyle.TEXT_MAIN)


## Gold spent, items found, the longest-serving hero, and each building's level.
func _show_records(records: Dictionary) -> void:
	_spent_tile.setup(str(records.gold_spent), TEXT_SPENT_CAPTION, HallStyle.GOLD_TEXT)
	_items_tile.setup(str(records.items_found), TEXT_ITEMS_CAPTION, HallStyle.BLUE_TEXT)
	var veteran: GuildCharacter = records.longest_serving
	if veteran:
		_service_tile.setup(str(records.longest_days), TEXT_SERVICE_CAPTION % veteran.name, HallStyle.GREEN_TEXT)
	else:
		_service_tile.setup("-", TEXT_SERVICE_NOBODY, HallStyle.TEXT_SOFT)

	HallStyle.clear_children(_buildings)
	for building in records.buildings:
		var label := _make_line(TEXT_BUILDING % [building.name, building.level], HallStyle.TEXT_MAIN, TEAM_ROLE_FONT_SIZE, &"Label")
		_buildings.add_child(label)


## One row per hero who was ever in the guild (already in roll-call order).
func _show_roll_call(heroes: Array, released: Array) -> void:
	HallStyle.clear_children(_roll_call)
	for character in heroes:
		HallStyle.add_row(_roll_call, RollCallRowScene).setup(character, released.has(character))
	_empty_label.text = TEXT_NOBODY
	_empty_label.visible = heroes.is_empty()


## The team credits from credits.tres: a heading per section, then each
## person's name with their contribution under it.
func _show_team() -> void:
	HallStyle.clear_children(_team)
	var sections: Array = TEAM_CREDITS.sections() if TEAM_CREDITS else []
	_team_heading.visible = not sections.is_empty()
	for group in sections:
		if not group.section.is_empty():
			var heading := _make_line(group.section, _ink_soft, HEADING_FONT_SIZE, &"CapsLight")
			heading.uppercase = true
			_team.add_child(heading)
		for entry in group.entries:
			_team.add_child(_make_line(entry.name, _ink, TEAM_NAME_FONT_SIZE, &"TitleLight"))
			if not entry.contribution.strip_edges().is_empty():
				_team.add_child(_make_line(entry.contribution, _ink_soft, TEAM_ROLE_FONT_SIZE, &"ItalicLight"))
		# a gap before the next section
		var gap := Control.new()
		gap.custom_minimum_size.y = HEADING_FONT_SIZE
		_team.add_child(gap)


## A centred, wrapping label in `ink` (see CrawlSections.make_line).
func _make_line(text: String, ink: Color, font_size: int, look: StringName = &"LabelLight") -> Label:
	return CrawlSections.make_line(text, ink, font_size, look)
