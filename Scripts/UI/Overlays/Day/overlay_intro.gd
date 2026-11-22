## The intro story crawl: who the player is and how they came to inherit the
## guild, rolling up a black screen in the credits' gold ink. It shows once
## per save, at the very start of a new run, before Pip's Day 1 tutorial (or
## the Welcome card when the tutorial is off). See HallMain.is_intro_open.
##
## It moves like the final credits (CrawlRoll): it scrolls itself after a
## short delay, any touch, drag or wheel hands it to the player, and the
## Begin button waits until the bottom is first reached, then stays.
## Reduced Motion: no auto-scroll, and the roll starts at its title.
## Begin calls HallMain.close_intro.
##
## To change the story, edit the INTRO STORY TEXT block below.
## Scene: Scenes/Overlays/Day/overlay_intro.tscn
extends Control


# ==== INTRO STORY TEXT =====================================================
# PLACEHOLDER story. Edit freely: each INTRO_PARAGRAPHS entry is one centred
# paragraph on the roll (BBCode such as [b], [i] and [color] works). Add or
# remove entries as you like; the roll grows to fit.
const INTRO_TITLE := "The Inheritance"
const INTRO_SUB := "How you aquired the guild"
const INTRO_PARAGRAPHS: Array[String] = [
	"You were a simple turnip farmer. Then one day, you recieved a letter from your Uncle John. \"Your grandfather had died and left you his guild.\"",
	"This guild was once the pride of the world. Now many of its heroes are gone and its facilities run dry. Only Uncle John, a priest of stubborn faith, and Pip, the goblin clerk, stayed.",
	"However, the guild was not left to you by chance. The [b]Demon King[/b] is rising. He grows stronger with every passing day, and one day he will march on the world.",
	"[i]\"Make the guild strong again,\"[/i] the letter said. [i]\"Strong enough to stand against him.\"[/i]",
	"So you hung up your hoe and came, to a dusty hall, a single hero, and a quest board with one notice pinned to it.",
]
const INTRO_END_LINE := "The guild is now yours, Guildmaster."
const BUTTON_BEGIN := "Open the Doors"
# ==== END INTRO STORY TEXT =================================================

# ---- MOTION
## How fast the roll moves (pixels per second). A little slower than the
## credits, since it's all reading.
const SCROLL_SPEED := 60.0
## Share of the screen's height left blank above the title, so the roll
## starts from the bottom of the screen. (Reduced Motion uses none.)
const TOP_SPACE_SHARE := 0.85
## Blank space under the closing line (pixels), so it can scroll up past the
## pinned button instead of ending under it.
const BOTTOM_SPACE := 520.0

# ---- LOOK
## Font size of each story paragraph (design px; HallFontScale grows it).
const PARAGRAPH_FONT_SIZE := 32
## Font size of the Begin button.
const BUTTON_FONT_SIZE := 46

# ---- NODES
@onready var _bg: ColorRect = %Bg
@onready var _scroll: ScrollContainer = %Scroll
@onready var _top_space: Control = %TopSpace
@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _story: VBoxContainer = %Story
@onready var _end: Label = %End
@onready var _bottom_space: Control = %BottomSpace
@onready var _footer: Control = %Footer
@onready var _begin_button: Button = %BeginButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The roll's motion: auto-scroll, hand-over to the player, Begin at the bottom.
var _roll: CrawlRoll
## True while the overlay is on screen: the roll restarts each time it opens.
var _was_shown := false


func setup(main: HallMain) -> void:
	hall = main
	_bg.color = HallStyle.INTRO_BG
	_begin_button.text = BUTTON_BEGIN
	_begin_button.pressed.connect(hall.close_intro)
	HallStyle.style_button(_begin_button, "gold", BUTTON_FONT_SIZE)
	_roll = CrawlRoll.new()
	add_child(_roll)
	_roll.setup(_scroll, _top_space, _bottom_space, _footer)
	_show_text()
	visibility_changed.connect(_on_visibility_changed)


## Nothing changes while it's open (the text is built once in setup); the
## roll starts over each time the overlay opens.
func refresh() -> void:
	if not _was_shown:
		_was_shown = true
		_roll.start(SCROLL_SPEED, TOP_SPACE_SHARE, BOTTOM_SPACE)


## Closing it lets the next opening (Debug tools' Replay intro) roll from the start.
func _on_visibility_changed() -> void:
	if not visible:
		_was_shown = false


## The title, one label per INTRO_PARAGRAPHS entry, and the closing line, in
## the credits' gold ink.
func _show_text() -> void:
	_title.text = INTRO_TITLE
	_sub.text = INTRO_SUB
	_end.text = INTRO_END_LINE
	HallStyle.set_font_color(_title, HallStyle.CREDITS_INK)
	HallStyle.set_font_color(_end, HallStyle.CREDITS_INK)
	HallStyle.set_font_color(_sub, HallStyle.CREDITS_INK_SOFT)
	HallStyle.clear_children(_story)
	for paragraph in INTRO_PARAGRAPHS:
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for font_key in ["normal_font_size", "bold_font_size", "italics_font_size"]:
			HallFontScale.set_size(label, font_key, PARAGRAPH_FONT_SIZE)
		HallStyle.set_font_color(label, HallStyle.CREDITS_INK)
		label.text = "[center]%s[/center]" % paragraph
		_story.add_child(label)
