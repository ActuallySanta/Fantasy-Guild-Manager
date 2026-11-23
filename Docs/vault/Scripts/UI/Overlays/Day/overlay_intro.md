---
source: Scripts/UI/Overlays/Day/overlay_intro.gd
class_name: ""
extends: Control
scene: "[[overlay_intro (scene)]]"
systems: ["[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# overlay_intro.gd

## Purpose
The intro story crawl: who the player is and how they inherited the guild, rolling up a black screen in the credits' gold ink. It shows once per save, at the start of a new run, before Pip's Day 1 tutorial (or the Welcome card when the tutorial is off); see [[hall_main#is_intro_open]]. Motion is done by [[crawl_roll]]. The Begin button ("Open the Doors") calls [[hall_main#close_intro]]. The story is edited in the `INTRO STORY TEXT` block of constants. Scene: [[overlay_intro (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `INTRO_TITLE`, `INTRO_SUB`, `INTRO_END_LINE`, `BUTTON_BEGIN` | const | Title ("The Inheritance"), subtitle ("How you aquired the guild"), closing line ("The guild is now yours, Guildmaster.") and Begin button text. |
| `INTRO_PARAGRAPHS` | const | `Array[String]`: one centred BBCode paragraph per entry (the "inheritance" story: a turnip farmer inherits the guild, and the Demon King is rising). |
| `SCROLL_SPEED` | const | Roll speed (px/s), slower than the credits. |
| `TOP_SPACE_SHARE` | const | Share of screen height blank above the title. |
| `BOTTOM_SPACE` | const | Blank px under the closing line. |
| `PARAGRAPH_FONT_SIZE` | const | Paragraph font size (design px; `HallFontScale` grows it). |
| `BUTTON_FONT_SIZE` | const | Begin button font size. |
| `hall` | var | The [[hall_main]] node. |
| `_roll` | var | The [[crawl_roll]] child. |
| `_was_shown` | var | True while the overlay is on screen; the roll restarts each time it opens. |
| `_bg`, `_scroll`, `_top_space`, `_title`, `_sub`, `_story`, `_end`, `_bottom_space`, `_footer`, `_begin_button` | onready | Scene nodes `%Bg`, `%Scroll`, `%TopSpace`, `%Title`, `%Sub`, `%Story`, `%End`, `%BottomSpace`, `%Footer`, `%BeginButton`. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Day/overlay_intro.gd:71`

Stores the hall, sets the background (`HallStyle.INTRO_BG`), the Begin button, creates the [[crawl_roll]], builds the text once, and watches visibility.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] (`hall_main.gd:427`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%BeginButton` to [[hall_main#close_intro]]; connects `visibility_changed` (on this node) to [[overlay_intro#_on_visibility_changed]]; adds a `CrawlRoll` child.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_style#style_button]], [[crawl_roll#setup]], [[overlay_intro#_show_text]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Day/overlay_intro.gd:86`

Nothing changes while it is open; on the first refresh after it opens it starts the roll (`_was_shown` guards repeats).

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1891`) while visible.

**Calls:** [[crawl_roll#start]].

### _on_visibility_changed
`func _on_visibility_changed() -> void` · `Scripts/UI/Overlays/Day/overlay_intro.gd:93`

When the overlay hides, resets `_was_shown` so the next opening (Debug tools' Replay intro) rolls from the start.

**Returns:** nothing.

**Called by:** signal `visibility_changed` on this overlay (connected in `setup`).

### _show_text
`func _show_text() -> void` · `Scripts/UI/Overlays/Day/overlay_intro.gd:100`

Fills the title, subtitle and closing line, inks them, and adds one `RichTextLabel` (BBCode, centred, font size `PARAGRAPH_FONT_SIZE`) per `INTRO_PARAGRAPHS` entry to `%Story`.

**Returns:** nothing.

**Called by:** [[overlay_intro#setup]].

**Calls:** [[hall_style#set_font_color]], [[hall_style#clear_children]], [[hall_font_scale#set_size]].

## Suspected issues
- `Scripts/UI/Overlays/Day/overlay_intro.gd:22` and `:24`: typos in player-facing text, "aquired" (acquired) and "recieved" (received).
