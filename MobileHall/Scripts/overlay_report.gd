## Day Report: the night's results as letters home. A torn strip of totals,
## then one letter per quest (result stamp, who went, who got hurt, the story,
## and a closing line from the party).
## Scene: MobileHall/Scenes/Overlays/overlay_report.tscn
extends Control

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const ReportEntry := preload("res://MobileHall/Scenes/Rows/report_entry.tscn")

## Chip text size on the totals strip.
const TOTALS_SIZE := 28

# ---- TEXT
const TEXT_TITLE := "Day %d Report"
const TEXT_LETTERS := "%s tonight"
const TEXT_NO_LETTERS := "a quiet night"
const TEXT_WINS := "%d / %d succeeded"
const TEXT_GOLD := "+%d gold"
const TEXT_NO_HURT := "nobody hurt"
const TEXT_NOBODY := "Nobody went out. Quests are the only way to earn gold."
const BUTTON_START := "Open the doors · Day %d"
const BUTTON_CLOSE := "Close"

# ---- NODES
@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _wins = %WinsChip
@onready var _gold = %GoldChip
@onready var _hurt = %HurtChip
@onready var _scroll: ScrollContainer = %Scroll
@onready var _entries: VBoxContainer = %Entries
@onready var _empty: Label = %Empty
@onready var _action_button: Button = %ActionButton

var ui
var _shown: Dictionary = {}


func setup(main) -> void:
	ui = main
	_action_button.pressed.connect(func(): ui.close_report())
	for chip in [_wins, _gold, _hurt]:
		chip.get_node("Row/Text").add_theme_font_size_override("font_size", TOTALS_SIZE)
		chip.get_node("Row/Text").theme_type_variation = &"TitleLabel"


func refresh() -> void:
	var rep: Dictionary = ui.report
	# only rebuild when a different report opens
	if rep.get("results") == _shown.get("results") and rep.get("live") == _shown.get("live"):
		return
	_shown = rep
	var results: Array = rep.results
	var gold := 0
	var wins := 0
	var hurt := 0
	for r in results:
		gold += int(r.gold)
		wins += 1 if r.succeeded else 0
		hurt += r.get("hurt", []).size()
	_title.text = TEXT_TITLE % rep.day
	_sub.text = TEXT_LETTERS % S.count(results.size(), "letter", "letters") if not results.is_empty() else TEXT_NO_LETTERS
	_wins.set_chip(TEXT_WINS % [wins, results.size()], S.BLUE_TEXT, "", "box")
	_gold.set_chip(TEXT_GOLD % gold, S.GOLD_TEXT, "", "box")
	if hurt > 0:
		_hurt.set_chip(S.count(hurt, "hurt", "hurt"), S.WAX, "", "box")
	else:
		_hurt.set_chip(TEXT_NO_HURT, S.GREEN_TEXT, "", "box")
	_wins.visible = not results.is_empty()

	S.clear(_entries)
	for r in results:
		S.add_row(_entries, ReportEntry).setup(r)
	_empty.text = TEXT_NOBODY
	_empty.visible = results.is_empty()
	_scroll.scroll_vertical = 0

	var live: bool = rep.get("live", false)
	_action_button.text = BUTTON_START % (GameState.day + 1) if live else BUTTON_CLOSE
