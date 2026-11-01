## Game Over: the guild ledger, shown when nobody is left alive and no recruit
## can ever be afforded (HallMain.is_run_over). A big Days tile, a 2 x 3 grid of
## the run's numbers, a roll call of every hero and what became of them, and
## the "Found a New Guild" button (HallMain.start_new_run).
## Reads HallMain.run_over_stats (see HallMain.build_run_over_stats).
## Scene: MobileHall/Scenes/Overlays/overlay_game_over.tscn
extends Control

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const RollCallRowScene := preload("res://MobileHall/Scenes/Rows/roll_call_row.tscn")

## Font size of the number on the big Days tile (the grid tiles keep the scene's).
const DAYS_FONT_SIZE := 110

# ---- TEXT
const TEXT_DAYS_CAPTION_ONE := "day survived"
const TEXT_DAYS_CAPTION := "days survived"
const TEXT_GOLD_CAPTION := "gold earned"
const TEXT_QUESTS := "%d/%d"
const TEXT_QUESTS_CAPTION := "quests won"
const TEXT_HIRED_CAPTION := "heroes hired"
const TEXT_FALLEN_CAPTION := "heroes fallen"
const TEXT_STANDING_CAPTION := "final standing"
const TEXT_DRAKE_CAPTION := "Bone Drake"
## Shown in the Drake tile when the run ended before the milestone quest went out.
const TEXT_DRAKE_UNMET := "Unmet"
const TEXT_NOBODY := "No hero ever joined this guild."

# ---- NODES
@onready var _days_tile = %DaysTile          # stat_tile.gd
@onready var _gold_tile = %GoldTile          # stat_tile.gd
@onready var _quests_tile = %QuestsTile      # stat_tile.gd
@onready var _hired_tile = %HiredTile        # stat_tile.gd
@onready var _fallen_tile = %FallenTile      # stat_tile.gd
@onready var _standing_tile = %StandingTile  # stat_tile.gd
@onready var _drake_tile = %DrakeTile        # stat_tile.gd
@onready var _roll_call: VBoxContainer = %RollCall
@onready var _empty_label: Label = %Empty
@onready var _scroll: ScrollContainer = %Scroll
@onready var _new_run_button: Button = %NewRunButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The stats currently built on screen (they're frozen once the run ends,
## so the ledger is only built once).
var _built_stats: Dictionary = {}


func setup(main: HallMain) -> void:
	hall = main
	_new_run_button.pressed.connect(hall.start_new_run)
	Style.style_button(_new_run_button, "gold", 46)


func refresh() -> void:
	var stats: Dictionary = hall.run_over_stats
	if stats.is_empty() or stats == _built_stats:
		return
	_built_stats = stats
	_show_tiles(stats)
	_show_roll_call(stats.roll_call, stats.released)
	_scroll.scroll_vertical = 0


## The Days tile and the 2 x 3 grid of the run's numbers.
func _show_tiles(stats: Dictionary) -> void:
	var days: int = stats.days
	var days_caption := TEXT_DAYS_CAPTION_ONE if days == 1 else TEXT_DAYS_CAPTION
	_days_tile.setup(str(days), days_caption, Style.TEXT_MAIN, DAYS_FONT_SIZE)

	_gold_tile.setup(str(stats.gold_earned), TEXT_GOLD_CAPTION, Style.GOLD_TEXT)
	_quests_tile.setup(TEXT_QUESTS % [stats.quests_won, stats.quests_sent], TEXT_QUESTS_CAPTION, Style.BLUE_TEXT)
	_hired_tile.setup(str(stats.heroes_hired), TEXT_HIRED_CAPTION, Style.GREEN_TEXT)
	var dead_ink: Color = Style.INJURY_LOOKS[GuildCharacter.InjuryLevel.DEAD].text
	_fallen_tile.setup(str(stats.fallen), TEXT_FALLEN_CAPTION, dead_ink)
	var standing: int = stats.standing
	_standing_tile.setup(str(standing), TEXT_STANDING_CAPTION, Style.RED if standing < 0 else Style.TEXT_MAIN)

	# the Drake tile: slain in green, lost in red, never fought in soft ink
	var drake_result: String = stats.drake_result
	if drake_result == HallMain.DRAKE_RESULT_SLAIN:
		_drake_tile.setup(drake_result, TEXT_DRAKE_CAPTION, Style.GREEN_TEXT)
	elif drake_result == HallMain.DRAKE_RESULT_LOST:
		_drake_tile.setup(drake_result, TEXT_DRAKE_CAPTION, Style.RED)
	else:
		_drake_tile.setup(TEXT_DRAKE_UNMET, TEXT_DRAKE_CAPTION, Style.TEXT_SOFT)


## One row per hero who was ever in the guild (already in roll-call order).
func _show_roll_call(heroes: Array, released: Array) -> void:
	Style.clear_children(_roll_call)
	for character in heroes:
		Style.add_row(_roll_call, RollCallRowScene).setup(character, released.has(character))
	_empty_label.text = TEXT_NOBODY
	_empty_label.visible = heroes.is_empty()
