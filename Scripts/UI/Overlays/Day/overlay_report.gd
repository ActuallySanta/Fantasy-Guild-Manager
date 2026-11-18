## Day Report: the night's results as letters home. A torn strip of totals,
## a line for what happened at home (training, healing), a line for anyone
## released that day, then one letter per quest (result stamp, who went, who
## got hurt or died, the story, a closing line). Story quests' letters come
## first and stay open; everyday letters start folded (see report_entry.gd).
## Scene: Scenes/Overlays/Day/overlay_report.tscn
extends Control

const ReportEntryScene := preload("uid://di7qjsfr530p5")  # Scenes/Rows/Day End/report_entry.tscn

# ---- MOTION (only for the report that opens after End Day)
## Seconds after the report opens (under the dusk wash's peak) before the
## reveal starts. Short, so the night is already playing out as the dusk
## clears (HallMain.DUSK_OUT_SECONDS) instead of showing a blank page first.
const REVEAL_START := 0.1
## Seconds between the totals chips stamping in, and the gold total's count-up.
const REVEAL_CHIP_GAP := 0.1
const REVEAL_GOLD_SECONDS := 0.6
## Letters overlap: the next one starts after this share of the last one.
const REVEAL_LETTER_OVERLAP := 0.55
## The sign (the button and the strings it hangs from) swings in by this many
## seconds at the latest, however long the night was.
const REVEAL_BUTTON_LATEST := 1.6
## How far below the top of the strings (Sprites/UI Textures/connector.png) their
## nail sits, in pixels. The sign swings on it.
const SIGN_NAIL_Y := 9.0

## Chip text size on the totals strip.
const TOTALS_FONT_SIZE := 28

# ---- SCROLL ARROW (more letters below the fold)
## The arrow shows while more than this many px of the letters are still
## below the bottom of the scroll area, and hides once the player gets there.
const SCROLL_ARROW_HIDE_WITHIN := 40.0
## Gap (px) between the arrow and the bottom of the scroll area.
const SCROLL_ARROW_MARGIN := 12.0
## The bob: how far it moves (px) and how fast (radians per second).
const SCROLL_ARROW_BOB_HEIGHT := 8.0
const SCROLL_ARROW_BOB_SPEED := 5.0
## The flash: lowest opacity (0..1) it fades to, and how fast (radians per second).
const SCROLL_ARROW_MIN_ALPHA := 0.35
const SCROLL_ARROW_FLASH_SPEED := 6.0

# ---- SIMPLIFIED (Info-Chunking): set to true to restore
## "2 letters tonight" under the report's title.
const SHOW_LETTERS_NOTE := false
## "At home: Uncle John Sore → Healthy" (who trained or healed at home).
const SHOW_HOME_NOTE := false

# ---- TEXT
const TEXT_TITLE := "Day %d Report"
const TEXT_LETTERS := "%s tonight"
const TEXT_NO_LETTERS := "a quiet night"
const TEXT_SUCCEEDED := "%d / %d succeeded"
const TEXT_GOLD := "+%d gold"
## The gold chip when equipment was gained too: filled with the item count
## ("2 items"), leaving a %d for the gold (see _show_totals).
const TEXT_GOLD_AND_ITEMS := "+%%d gold · +%s"
const TEXT_NO_INJURIES := "nobody hurt"
const TEXT_NOBODY_WENT := "Nobody went out. Quests are the only way to earn gold."
const TEXT_HOME := "At home: %s"
const TEXT_TRAINED := "%s +%d %s"
const TEXT_HEALED := "%s %s → %s"
const TEXT_RELEASED := "Left the guild: %s"
const TEXT_RELEASED_COST := "%s (-%d standing)"
const TEXT_RELEASED_FALLEN := "%s (fallen)"
const BUTTON_START_DAY := "Open the doors · Day %d"
const BUTTON_CLOSE := "Close"

# ---- NODES
@onready var _title: Label = %Title
@onready var _letters_note: Label = %Sub
# Totals
@onready var _succeeded_chip = %WinsChip      # chip.gd
@onready var _gold_chip = %GoldChip           # chip.gd
@onready var _injured_chip = %HurtChip        # chip.gd
@onready var _dead_chip = %DeadChip           # chip.gd
@onready var _home_note: Label = %HomeNote
@onready var _released_note: Label = %ReleasedNote
# Letters
@onready var _scroll: ScrollContainer = %Scroll
@onready var _entry_list: VBoxContainer = %Entries
@onready var _empty_label: Label = %Empty
@onready var _action_button: Button = %ActionButton
## The strings and the button under them, hung (and swung) as one sign.
@onready var _hanging_sign: Control = %ActionButton.get_parent()
## Gold down-arrow over the bottom of the letters while more are out of
## sight below (see _update_scroll_arrow).
@onready var _scroll_arrow: TextureRect = %ScrollArrow

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The report currently built on screen (to skip rebuilding the same one).
var _built_report: Dictionary = {}
## The night's total gold (for the count-up on the totals strip).
var _total_gold := 0
## The gold chip's format tonight: TEXT_GOLD, or TEXT_GOLD_AND_ITEMS filled in.
var _gold_format := TEXT_GOLD
## Seconds the scroll arrow has been animating (drives its bob and flash).
var _arrow_time := 0.0


func setup(main: HallMain) -> void:
	hall = main
	_action_button.pressed.connect(hall.close_report)
	HallStyle.tint_art(_scroll_arrow, HallStyle.POINTER_GOLD)


func _process(delta: float) -> void:
	_update_scroll_arrow(delta)


## Show the bobbing, flashing arrow while letters are hidden below the bottom
## of the scroll area, placed just above that bottom edge and centred on it.
## It holds still (no bob, no flash) with Reduce motion on.
## delta = seconds since the last frame.
func _update_scroll_arrow(delta: float) -> void:
	var scroll_bar := _scroll.get_v_scroll_bar()
	var hidden_below: float = scroll_bar.max_value - scroll_bar.page - _scroll.scroll_vertical
	var is_shown := is_visible_in_tree() and hidden_below > SCROLL_ARROW_HIDE_WITHIN
	_scroll_arrow.visible = is_shown
	if not is_shown:
		_arrow_time = 0.0
		return
	_arrow_time += delta
	var bob := 0.0
	var alpha := 1.0
	if not HallFx.reduce_motion:
		bob = SCROLL_ARROW_BOB_HEIGHT * sin(_arrow_time * SCROLL_ARROW_BOB_SPEED)
		var flash := 0.5 + 0.5 * cos(_arrow_time * SCROLL_ARROW_FLASH_SPEED)
		alpha = lerpf(SCROLL_ARROW_MIN_ALPHA, 1.0, flash)
	_scroll_arrow.modulate.a = alpha
	# the scroll's rect in this overlay's own coordinates
	var scroll_rect := Rect2(_scroll.global_position - global_position, _scroll.size)
	var arrow_size := _scroll_arrow.size
	_scroll_arrow.position = Vector2(
			scroll_rect.get_center().x - arrow_size.x * 0.5,
			scroll_rect.end.y - arrow_size.y - SCROLL_ARROW_MARGIN + bob)
	for chip in [_succeeded_chip, _gold_chip, _injured_chip, _dead_chip]:
		var chip_text: Label = chip.get_node("Row/Text")
		HallFontScale.set_size(chip_text, "font_size", TOTALS_FONT_SIZE)
		chip_text.theme_type_variation = &"TitleLabel"


func refresh() -> void:
	var report: Dictionary = hall.shown_report
	# only rebuild when a different report opens
	var is_same_report: bool = report.get("results") == _built_report.get("results") \
			and report.get("starts_next_day") == _built_report.get("starts_next_day") \
			and report.get("day") == _built_report.get("day") \
			and report.get("home") == _built_report.get("home") \
			and report.get("released") == _built_report.get("released")
	if is_same_report:
		return
	_built_report = report

	var results: Array = report.results
	_title.text = TEXT_TITLE % report.day
	_letters_note.text = TEXT_LETTERS % HallStyle.count_text(results.size(), "letter", "letters") if not results.is_empty() else TEXT_NO_LETTERS
	_letters_note.visible = SHOW_LETTERS_NOTE
	_show_totals(results)
	_show_home(report.get("home", {}))
	_show_released(report.get("released", []))
	_show_entries(results)

	# after End Day the button starts the next day; from the Menu it just closes
	var starts_next_day: bool = report.get("starts_next_day", false)
	_action_button.text = BUTTON_START_DAY % (GameState.day + 1) if starts_next_day else BUTTON_CLOSE
	# the night plays out on the page the first time it's read
	if starts_next_day:
		_play_reveal()


## The report as the night unfolds: the totals stamp in and the gold counts
## up, the home / released notes fade in, then each letter plays in turn
## (report_entry.reveal), and the sign at the bottom swings in on its nail.
## The button is always there to skip ahead.
func _play_reveal() -> void:
	if HallFx.reduce_motion:
		return
	var at := REVEAL_START
	for chip in [_succeeded_chip, _gold_chip, _injured_chip, _dead_chip]:
		if chip.visible:
			HallFx.stamp_in(chip, 1.6, at)
			at += REVEAL_CHIP_GAP
	HallFx.count(_gold_chip.get_node("Row/Text"), 0, _total_gold, REVEAL_GOLD_SECONDS, _gold_format, REVEAL_START)
	for note in [_home_note, _released_note]:
		if note.visible:
			HallFx.fade_in(note, at)
			at += REVEAL_CHIP_GAP
	for entry in _entry_list.get_children():
		at += entry.reveal(at) * REVEAL_LETTER_OVERLAP
	HallFx.swing_in(_hanging_sign, SIGN_NAIL_Y, minf(at, REVEAL_BUTTON_LATEST))


## Inked boxes on the torn strip: how many succeeded, total gold, how many
## got hurt, how many died.
func _show_totals(results: Array) -> void:
	var total_gold := 0
	var succeeded_count := 0
	var injured_count := 0
	var dead_count := 0
	# equipment gained tonight: found while searching plus item-quest rewards
	var item_count := 0
	for result in results:
		total_gold += int(result.gold)
		item_count += result.get("items", []).size() + result.get("reward_items", []).size()
		if result.succeeded:
			succeeded_count += 1
		injured_count += result.get("injured", []).size()
		dead_count += result.get("died", []).size()

	_succeeded_chip.set_box(TEXT_SUCCEEDED % [succeeded_count, results.size()], HallStyle.BLUE_TEXT)
	_succeeded_chip.visible = not results.is_empty()
	# with equipment gained, the item count rides along after the gold
	# (the format keeps a %d for the gold, so the reveal can count it up)
	_gold_format = TEXT_GOLD
	if item_count > 0:
		_gold_format = TEXT_GOLD_AND_ITEMS % HallStyle.count_text(item_count, "item", "items")
	_gold_chip.set_box(_gold_format % total_gold, HallStyle.GOLD_TEXT)
	_total_gold = total_gold
	if injured_count > 0:
		_injured_chip.set_box(HallStyle.count_text(injured_count, "hurt", "hurt"), HallStyle.RED)
	else:
		_injured_chip.set_box(TEXT_NO_INJURIES, HallStyle.GREEN_TEXT)
	# "nobody hurt" next to a death would read wrong, so it hides when someone died
	_injured_chip.visible = injured_count > 0 or dead_count == 0

	var dead_look: Dictionary = HallStyle.INJURY_LOOKS[GuildCharacter.InjuryLevel.DEAD]
	_dead_chip.set_box(HallStyle.count_text(dead_count, "death", "deaths"), dead_look.text, "skull")
	_dead_chip.visible = dead_count > 0


## One line for the night at home: who trained, who healed (see GuildUpgrades.run_night).
func _show_home(home: Dictionary) -> void:
	var parts := PackedStringArray()
	for trained in home.get("trained", []):
		parts.append(TEXT_TRAINED % [trained.character.name, trained.gain, HallStyle.STATS[trained.stat].short])
	for healed in home.get("healed", []):
		var from_label: String = HallStyle.INJURY_LOOKS[healed.from].label
		var to_label: String = HallStyle.INJURY_LOOKS[healed.to].label
		parts.append(TEXT_HEALED % [healed.character.name, from_label, to_label])
	_home_note.text = TEXT_HOME % " · ".join(parts)
	_home_note.visible = SHOW_HOME_NOTE and not parts.is_empty()


## One line for heroes released today (see HallMain.released_today), with the
## standing each one cost. Fallen heroes are marked instead, since they were free.
func _show_released(released: Array) -> void:
	var parts := PackedStringArray()
	for release in released:
		var hero_name: String = release.character.name
		if release.fallen:
			parts.append(TEXT_RELEASED_FALLEN % hero_name)
		else:
			parts.append(TEXT_RELEASED_COST % [hero_name, release.standing])
	_released_note.text = TEXT_RELEASED % " · ".join(parts)
	_released_note.visible = not parts.is_empty()


## One letter per quest, or a note when nobody went out. Story quests'
## letters go first (in their own order), then everyday ones, folded.
func _show_entries(results: Array) -> void:
	HallStyle.clear_children(_entry_list)
	var story_results := results.filter(HallStyle.is_story_quest)
	var other_results := results.filter(func(result): return not HallStyle.is_story_quest(result))
	for result in story_results + other_results:
		var entry: Control = HallStyle.add_row(_entry_list, ReportEntryScene)
		entry.setup(result, true)
		# Pip's Day 1 walkthrough waits for a letter to be opened
		entry.opened.connect(hall.report_letter_opened)
	_empty_label.text = TEXT_NOBODY_WENT
	_empty_label.visible = results.is_empty()
	_scroll.scroll_vertical = 0
