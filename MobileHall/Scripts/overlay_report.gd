## Day Report: the night's results as letters home. A torn strip of totals,
## a line for what happened at home (training, healing), then one letter per
## quest (result stamp, who went, who got hurt, the story, a closing line).
## Scene: MobileHall/Scenes/Overlays/overlay_report.tscn
extends Control

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const ReportEntryScene := preload("res://MobileHall/Scenes/Rows/report_entry.tscn")

## Chip text size on the totals strip.
const TOTALS_FONT_SIZE := 28

# ---- TEXT
const TEXT_TITLE := "Day %d Report"
const TEXT_LETTERS := "%s tonight"
const TEXT_NO_LETTERS := "a quiet night"
const TEXT_SUCCEEDED := "%d / %d succeeded"
const TEXT_GOLD := "+%d gold"
const TEXT_NO_INJURIES := "nobody hurt"
const TEXT_NOBODY_WENT := "Nobody went out. Quests are the only way to earn gold."
const TEXT_HOME := "At home: %s"
const TEXT_TRAINED := "%s +%d %s"
const TEXT_HEALED := "%s %s → %s"
const BUTTON_START_DAY := "Open the doors · Day %d"
const BUTTON_CLOSE := "Close"

# ---- NODES
@onready var _title: Label = %Title
@onready var _letters_note: Label = %Sub
# Totals
@onready var _succeeded_chip = %WinsChip      # chip.gd
@onready var _gold_chip = %GoldChip           # chip.gd
@onready var _injured_chip = %HurtChip        # chip.gd
@onready var _home_note: Label = %HomeNote
# Letters
@onready var _scroll: ScrollContainer = %Scroll
@onready var _entry_list: VBoxContainer = %Entries
@onready var _empty_label: Label = %Empty
@onready var _action_button: Button = %ActionButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The report currently built on screen (to skip rebuilding the same one).
var _built_report: Dictionary = {}


func setup(main: HallMain) -> void:
	hall = main
	_action_button.pressed.connect(hall.close_report)
	for chip in [_succeeded_chip, _gold_chip, _injured_chip]:
		var chip_text: Label = chip.get_node("Row/Text")
		chip_text.add_theme_font_size_override("font_size", TOTALS_FONT_SIZE)
		chip_text.theme_type_variation = &"TitleLabel"


func refresh() -> void:
	var report: Dictionary = hall.shown_report
	# only rebuild when a different report opens
	var is_same_report: bool = report.get("results") == _built_report.get("results") \
			and report.get("starts_next_day") == _built_report.get("starts_next_day") \
			and report.get("day") == _built_report.get("day") \
			and report.get("home") == _built_report.get("home")
	if is_same_report:
		return
	_built_report = report

	var results: Array = report.results
	_title.text = TEXT_TITLE % report.day
	_letters_note.text = TEXT_LETTERS % Style.count_text(results.size(), "letter", "letters") if not results.is_empty() else TEXT_NO_LETTERS
	_show_totals(results)
	_show_home(report.get("home", {}))
	_show_entries(results)

	# after End Day the button starts the next day; from the Menu it just closes
	var starts_next_day: bool = report.get("starts_next_day", false)
	_action_button.text = BUTTON_START_DAY % (GameState.day + 1) if starts_next_day else BUTTON_CLOSE


## Inked boxes on the torn strip: how many succeeded, total gold, how many got hurt.
func _show_totals(results: Array) -> void:
	var total_gold := 0
	var succeeded_count := 0
	var injured_count := 0
	for result in results:
		total_gold += int(result.gold)
		if result.succeeded:
			succeeded_count += 1
		injured_count += result.get("injured", []).size()

	_succeeded_chip.set_box(TEXT_SUCCEEDED % [succeeded_count, results.size()], Style.BLUE_TEXT)
	_succeeded_chip.visible = not results.is_empty()
	_gold_chip.set_box(TEXT_GOLD % total_gold, Style.GOLD_TEXT)
	if injured_count > 0:
		_injured_chip.set_box(Style.count_text(injured_count, "hurt", "hurt"), Style.RED)
	else:
		_injured_chip.set_box(TEXT_NO_INJURIES, Style.GREEN_TEXT)


## One line for the night at home: who trained, who healed (see GuildUpgrades.run_night).
func _show_home(home: Dictionary) -> void:
	var parts := PackedStringArray()
	for trained in home.get("trained", []):
		parts.append(TEXT_TRAINED % [trained.character.name, trained.gain, Style.STATS[trained.stat].short])
	for healed in home.get("healed", []):
		var from_label: String = Style.INJURY_LOOKS[healed.from].label
		var to_label: String = Style.INJURY_LOOKS[healed.to].label
		parts.append(TEXT_HEALED % [healed.character.name, from_label, to_label])
	_home_note.text = TEXT_HOME % " · ".join(parts)
	_home_note.visible = not parts.is_empty()


## One letter per quest, or a note when nobody went out.
func _show_entries(results: Array) -> void:
	Style.clear_children(_entry_list)
	for result in results:
		Style.add_row(_entry_list, ReportEntryScene).setup(result)
	_empty_label.text = TEXT_NOBODY_WENT
	_empty_label.visible = results.is_empty()
	_scroll.scroll_vertical = 0
