## The final battle's credits roll (HallMain.FINAL_DAY), in one of two moods:
##   - victory: a warm hall, the night's events rolling up the screen like a
##     film's end credits, then the "Begin Freeplay" button (HallMain.start_freeplay)
##   - defeat:  a cold, slower roll with an epitaph that ends the run, then the
##     "Found a New Guild" button (HallMain.start_new_run)
## Top to bottom: title, the quest's story one line at a time, the final
## battle's party, a parchment ledger (final stats, run records, roll call),
## the team credits (MobileHall/Data/credits.tres, see CreditsList), and a
## closing line.
##
## The roll scrolls itself after START_DELAY. Any touch, drag or wheel hands
## it to the player for good. The button waits until the bottom is first
## reached, then stays, so the player can scroll back up and still leave.
## Reduced Motion: no auto-scroll, and the roll starts at its title.
## Reads HallMain.shown_credits (see HallMain.build_credits).
## Scene: MobileHall/Scenes/Overlays/overlay_credits.tscn
extends Control

const RollCallRowScene := preload("uid://bqn0i28l67um7")  # MobileHall/Scenes/Rows/roll_call_row.tscn
## The team credits (edit them in the inspector; see credits_list.gd).
const TEAM_CREDITS: CreditsList = preload("uid://c72de0tnaska")  # MobileHall/Data/credits.tres

# ---- MOTION
## Seconds the roll holds still before it starts to move.
const START_DELAY := 1.2
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
## The bottom counts as reached within this many pixels of the end.
const BOTTOM_SLACK := 4.0

# ---- LOOK
## Font sizes: story lines, party names, team names, contributions.
const STORY_FONT_SIZE := 30
const PARTY_FONT_SIZE := 32
const TEAM_NAME_FONT_SIZE := 38
const TEAM_ROLE_FONT_SIZE := 26
## Section headings on the dark roll (party, team sections).
const HEADING_FONT_SIZE := 28
## Font size of the number on the big Days tile.
const DAYS_FONT_SIZE := 110
## The skull beside a fallen party member (pixels).
const PARTY_ICON_SIZE := 34.0

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
const TEXT_PARTY_LINE := "%s · %s"
const TEXT_FELL := "fell in the final battle"
const TEXT_SURVIVED := "survived"
const TEXT_NOBODY_WENT := "Nobody answered the call."
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
@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _story_heading: Label = %StoryHeading
@onready var _story: VBoxContainer = %Story
@onready var _party_heading: Label = %PartyHeading
@onready var _party: VBoxContainer = %Party
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
## True while the roll moves by itself (until the player touches it or it ends).
var _is_auto_scrolling := false
## Seconds left before the roll starts to move.
var _start_wait := 0.0
## Where the roll is, in fractional pixels (scroll_vertical is an int).
var _scroll_position := 0.0
## Ink for text on the dark roll: main and soft (set per mood).
var _ink := HallStyle.CREDITS_INK
var _ink_soft := HallStyle.CREDITS_INK_SOFT


func setup(main: HallMain) -> void:
	hall = main
	_action_button.pressed.connect(_on_action_pressed)
	HallStyle.style_button(_action_button, "gold", 46)
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scrolled)
	set_process(false)


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
	_show_story(credits.result.story)
	_show_party(credits.result)
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


## Back to the top with the button hidden, then (motion allowed) wait and roll.
func _start_roll() -> void:
	_footer.visible = false
	var screen_height: float = size.y if size.y > 0.0 else get_viewport_rect().size.y
	_top_space.custom_minimum_size.y = 0.0 if HallFx.reduce_motion else screen_height * TOP_SPACE_SHARE
	_bottom_space.custom_minimum_size.y = BOTTOM_SPACE
	_scroll_position = 0.0
	_scroll.scroll_vertical = 0
	_is_auto_scrolling = not HallFx.reduce_motion
	_start_wait = START_DELAY
	set_process(_is_auto_scrolling)


func _process(delta: float) -> void:
	if not _is_auto_scrolling or not visible:
		set_process(false)
		return
	if _start_wait > 0.0:
		_start_wait -= delta
		return
	var speed := SCROLL_SPEED if _built_credits.get("won", false) else DEFEAT_SCROLL_SPEED
	_scroll_position += speed * delta
	_scroll.scroll_vertical = int(_scroll_position)
	# the last line has passed: stop, the button takes over
	if _is_at_bottom():
		_stop_auto_scroll()


## Any touch, drag or wheel while the roll moves gives it to the player.
func _input(event: InputEvent) -> void:
	if not _is_auto_scrolling or not visible:
		return
	var is_touch: bool = event is InputEventScreenTouch or event is InputEventScreenDrag
	var is_click: bool = event is InputEventMouseButton and event.pressed
	if is_touch or is_click:
		_stop_auto_scroll()


func _stop_auto_scroll() -> void:
	_is_auto_scrolling = false
	set_process(false)


## The roll moved (by itself or by the player): the first time it reaches the
## bottom the button appears, and it stays from then on.
func _on_scrolled(_value: float) -> void:
	if not _footer.visible and _is_at_bottom():
		_footer.visible = true
		HallFx.appear(_footer, 0.85)


func _is_at_bottom() -> bool:
	var bar := _scroll.get_v_scroll_bar()
	return bar.value + bar.page >= bar.max_value - BOTTOM_SLACK

# ---- sections


## Title, subtitle and the closing words, in the mood's wording and ink.
func _show_titles(credits: Dictionary) -> void:
	var is_won: bool = credits.won
	_title.text = TEXT_TITLE if is_won else TEXT_DEFEAT_TITLE
	_sub.text = (TEXT_SUB if is_won else TEXT_DEFEAT_SUB) % credits.day
	_end.text = TEXT_END if is_won else TEXT_DEFEAT_END
	_end_sub.text = TEXT_END_SUB if is_won else TEXT_DEFEAT_END_SUB
	_story_heading.text = TEXT_STORY_HEADING
	_party_heading.text = TEXT_PARTY_HEADING if is_won else TEXT_DEFEAT_PARTY_HEADING
	_team_heading.text = TEXT_TEAM_HEADING
	for label in [_title, _end]:
		HallStyle.set_font_color(label, _ink)
	for label in [_sub, _end_sub, _story_heading, _party_heading, _team_heading]:
		HallStyle.set_font_color(label, _ink_soft)


## The night's story, one centred line per beat. Its colours are the bright
## ones meant for dark backgrounds, so they're used as they are.
func _show_story(story: String) -> void:
	HallStyle.clear_children(_story)
	for line in story.split("\n"):
		var beat := line.strip_edges()
		if beat.is_empty():
			continue
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		HallFontScale.set_size(label, "normal_font_size", STORY_FONT_SIZE)
		HallFontScale.set_size(label, "bold_font_size", STORY_FONT_SIZE)
		HallStyle.set_font_color(label, _ink)
		label.text = "[center]%s[/center]" % beat
		_story.add_child(label)


## Everyone who went to the final battle: name and role, then whether they
## fell (with a skull) or survived.
func _show_party(result: Dictionary) -> void:
	HallStyle.clear_children(_party)
	var died: Array = result.get("died", [])
	if result.party.is_empty():
		_party.add_child(_make_line(TEXT_NOBODY_WENT, _ink_soft, PARTY_FONT_SIZE))
	for character in result.party:
		var has_fallen := died.has(character) or HallStyle.is_dead(character)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		if has_fallen:
			var skull := TextureRect.new()
			skull.texture = HallStyle.icon_texture("skull")
			skull.custom_minimum_size = Vector2(PARTY_ICON_SIZE, PARTY_ICON_SIZE)
			skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			HallStyle.tint_art(skull, _ink_soft)
			row.add_child(skull)
		var name_text := TEXT_PARTY_LINE % [character.name, HallStyle.role_name(character)]
		var name_label := _make_line(name_text, _ink, PARTY_FONT_SIZE)
		# beside the skull the name sizes itself (a wrapping label would shrink to nothing)
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(name_label)
		_party.add_child(row)
		_party.add_child(_make_line(TEXT_FELL if has_fallen else TEXT_SURVIVED, _ink_soft, TEAM_ROLE_FONT_SIZE, &"ItalicLight"))


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


## A centred, wrapping label in `ink`. look = a hall_theme.tres label variation.
func _make_line(text: String, ink: Color, font_size: int, look: StringName = &"LabelLight") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = look
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 40
	HallFontScale.set_size(label, "font_size", font_size)
	HallStyle.set_font_color(label, ink)
	return label
