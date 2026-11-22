## The boss fights' text crawl: after End Day on a boss day (10, 20, 30, 40;
## the final battle has its own credits), the night's boss fights roll up the
## screen like the final's credits, before the Day Report. Top to bottom: the
## day, then each boss fight in board order (its name, the quest's story one
## line at a time, the party with a skull or "survived", and "Victory!" or
## "Defeated..."). There is no ledger, record or team credits.
##
## Each fight takes its own mood: a win the credits' warm ink, a loss the
## defeat ink. The background and the roll's speed follow the whole night: the
## victory look and speed when every fight was won, the cold, slower one when
## any was lost.
##
## It moves like the credits (CrawlRoll): it scrolls itself after a short
## delay, any touch, drag or wheel hands it to the player, and Continue waits
## until the bottom is first reached, then stays. Reduced Motion: no
## auto-scroll, and the roll starts at its title.
## Continue calls HallMain.close_boss_crawl, which opens the Day Report.
## Reads HallMain.shown_boss_crawl: {day: int, results: Array (see HallRules.play_quest)}.
## Scene: Scenes/Overlays/Day/overlay_boss_crawl.tscn
extends Control

# ---- MOTION
## (The start delay and the bottom check live in CrawlRoll.)
## How fast the roll moves (pixels per second) when every fight was won, and otherwise.
const SCROLL_SPEED := 70.0
const DEFEAT_SCROLL_SPEED := 50.0
## Share of the screen's height left blank above the title, so the roll
## starts from the bottom of the screen. (Reduced Motion uses none.)
const TOP_SPACE_SHARE := 0.85
## Blank space under the last line (pixels), so it can scroll up past the
## pinned button instead of ending under it.
const BOTTOM_SPACE := 520.0

# ---- LOOK
## Font size of the Continue button.
const BUTTON_FONT_SIZE := 46

# ---- TEXT
const TEXT_TITLE := "Day %d"
const TEXT_WON := "Victory!"
const TEXT_LOST := "Defeated..."
const TEXT_CONTINUE := "Continue"

# ---- NODES
@onready var _bg: ColorRect = %Bg
@onready var _scroll: ScrollContainer = %Scroll
@onready var _top_space: Control = %TopSpace
@onready var _sections: CrawlSections = %Sections
@onready var _bottom_space: Control = %BottomSpace
@onready var _footer: Control = %Footer
@onready var _continue_button: Button = %ContinueButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The crawl currently built on screen (it restarts only when a new one comes).
var _built_crawl: Dictionary = {}
## The roll's motion: auto-scroll, hand-over to the player, Continue at the bottom.
var _roll: CrawlRoll


func setup(main: HallMain) -> void:
	hall = main
	_continue_button.text = TEXT_CONTINUE
	_continue_button.pressed.connect(hall.close_boss_crawl)
	HallStyle.style_button(_continue_button, "gold", BUTTON_FONT_SIZE)
	_roll = CrawlRoll.new()
	add_child(_roll)
	_roll.setup(_scroll, _top_space, _bottom_space, _footer)


func refresh() -> void:
	var crawl: Dictionary = hall.shown_boss_crawl
	if crawl.is_empty() or crawl == _built_crawl:
		return
	_built_crawl = crawl
	var results: Array = crawl.results
	var is_all_won := results.all(func(result): return result.succeeded)
	_bg.color = HallStyle.CREDITS_BG if is_all_won else HallStyle.DEFEAT_BG

	var title_ink := HallStyle.CREDITS_INK if is_all_won else HallStyle.DEFEAT_INK
	var title_soft := HallStyle.CREDITS_INK_SOFT if is_all_won else HallStyle.DEFEAT_INK_SOFT
	_sections.show_title(TEXT_TITLE % crawl.day, "", title_ink, title_soft)
	_sections.clear()
	for result in results:
		var is_won: bool = result.succeeded
		var ink := HallStyle.CREDITS_INK if is_won else HallStyle.DEFEAT_INK
		var ink_soft := HallStyle.CREDITS_INK_SOFT if is_won else HallStyle.DEFEAT_INK_SOFT
		_sections.add_fight(result.quest.questTitle, result.story, result, is_won, ink, ink_soft,
				"", CrawlSections.TEXT_FELL, TEXT_WON, TEXT_LOST)
	_roll.start(SCROLL_SPEED if is_all_won else DEFEAT_SCROLL_SPEED, TOP_SPACE_SHARE, BOTTOM_SPACE)
