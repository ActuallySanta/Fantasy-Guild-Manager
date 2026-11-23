---
source: Scripts/UI/Components/crawl_sections.gd
class_name: CrawlSections
extends: VBoxContainer
scene: "[[crawl_sections (scene)]]"
systems: ["[[UI Motion and Feedback]]", "[[Run End]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# crawl_sections.gd

## Purpose
The text sections of a film-style crawl, shared by the final credits ([[overlay_credits]]) and the boss fights' crawl ([[overlay_boss_crawl]]): a title with a subtitle, then one block per fight. A block is a heading, the quest's story one centred line at a time, the party (skull or "survived" under each hero), and an optional won / lost line. It only builds the text; the overlay owns the ScrollContainer, the blank space, the button and the motion ([[crawl_roll]]). Usage: `show_title()` once, then `add_fight()` per fight (`clear()` empties the fights first when the overlay is reused). Scene: [[crawl_sections (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `STORY_FONT_SIZE`, `PARTY_FONT_SIZE`, `NOTE_FONT_SIZE`, `HEADING_FONT_SIZE`, `OUTCOME_FONT_SIZE` | const | Font sizes in design px (grown by `HallFontScale`): story lines (30), party names (32), the "fell / survived" line (26), section headings (28), the won / lost line (48). |
| `GAP_SIZE` | const | Blank space above each fight's heading and above its party (60 px). |
| `STORY_SEPARATION`, `PARTY_SEPARATION` | const | Space between a fight's story lines (26) and between its party lines (6), in px. |
| `PARTY_ICON_SIZE` | const | The skull beside a fallen party member (34 px). |
| `TEXT_PARTY_LINE` | const | "%s · %s" (name, role). |
| `TEXT_FELL` | const | "fell in battle": under a fallen hero when the caller doesn't word it (the final says its own). |
| `TEXT_SURVIVED`, `TEXT_NOBODY_WENT` | const | "survived", "Nobody answered the call." |
| `_title`, `_sub`, `_fights` | onready | `%Title`, `%Sub` (Labels), `%Fights` (VBoxContainer). |

## Functions

### show_title
`func show_title(title: String, subtitle: String, ink: Color, ink_soft: Color) -> void` · `Scripts/UI/Components/crawl_sections.gd:48`

Sets the title and subtitle in `ink` / `ink_soft`. An empty subtitle hides that line.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `title` | `String` | Title text | `TEXT_TITLE` / `TEXT_DEFEAT_TITLE` in [[overlay_credits#_show_titles]]; `TEXT_TITLE % crawl.day` in [[overlay_boss_crawl#refresh]] |
| `subtitle` | `String` | Subtitle, or `""` | `(TEXT_SUB or TEXT_DEFEAT_SUB) % credits.day`; `""` in the boss crawl |
| `ink` | `Color` | Title colour | `_ink` (credits); `HallStyle.CREDITS_INK` or `DEFEAT_INK` (boss crawl) |
| `ink_soft` | `Color` | Subtitle colour | `_ink_soft`; `CREDITS_INK_SOFT` or `DEFEAT_INK_SOFT` |

**Returns:** nothing.

**Called by:** [[overlay_credits#_show_titles]] (`overlay_credits.gd:169`), [[overlay_boss_crawl#refresh]] (`overlay_boss_crawl.gd:82`).

**Calls:** [[hall_style#set_font_color]].

### clear
`func clear() -> void` · `Scripts/UI/Components/crawl_sections.gd:57`

Empties every fight (the title stays).

**Called by:** [[overlay_credits#_show_fight]] (`overlay_credits.gd:182`), [[overlay_boss_crawl#refresh]] (`overlay_boss_crawl.gd:83`).

**Calls:** [[hall_style#clear_children]].

### add_fight
`func add_fight(heading: String, story: String, result: Dictionary, won: bool, ink: Color, ink_soft: Color, party_heading: String = "", fell_text: String = TEXT_FELL, won_line: String = "", lost_line: String = "") -> void` · `Scripts/UI/Components/crawl_sections.gd:70`

Appends one fight: a gap, an optional heading, the story, a gap, an optional party heading, the party, then the won or lost line when it is non-empty.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `heading` | `String` | Small caps heading above the story, `""` for none | `result.quest.questTitle` (boss crawl); `TEXT_STORY_HEADING` (credits) |
| `story` | `String` | The quest's BBCode story, one beat per line | `result.story` / `credits.result.story` |
| `result` | `Dictionary` | The quest's result (see `HallRules.play_quest`): its `party` and `died` | the boss crawl's `results`; `credits.result` |
| `won` | `bool` | Picks `won_line` or `lost_line` | `result.succeeded`; `credits.won` |
| `ink`, `ink_soft` | `Color` | The fight's text colours (a won and a lost fight differ) | `HallStyle.CREDITS_INK*` or `DEFEAT_INK*`; `_ink`, `_ink_soft` |
| `party_heading` | `String` | Heading above the party, `""` for none | `""` (boss crawl); `TEXT_PARTY_HEADING` or `TEXT_DEFEAT_PARTY_HEADING` (credits) |
| `fell_text` | `String` | The line under a fallen hero | `CrawlSections.TEXT_FELL` (boss crawl); `TEXT_FELL` of the credits |
| `won_line`, `lost_line` | `String` | Closing line for a win / loss, `""` for none | `TEXT_WON`, `TEXT_LOST` (boss crawl); not passed by the credits (default `""`) |

**Returns:** nothing.

**Called by:** [[overlay_boss_crawl#refresh]] (`overlay_boss_crawl.gd:88`), [[overlay_credits#_show_fight]] (`overlay_credits.gd:183`).

**Calls:** [[crawl_sections#_make_gap]], [[crawl_sections#_make_heading]], [[crawl_sections#_make_story]], [[crawl_sections#_make_party]], [[crawl_sections#make_line]].

### make_line
`static func make_line(text: String, ink: Color, font_size: int, look: StringName = &"LabelLight") -> Label` · `Scripts/UI/Components/crawl_sections.gd:88`

A centred, wrapping label in `ink`. `look` is a `hall_theme.tres` label variation; the font size is grown by `HallFontScale`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | Label text | callers |
| `ink` | `Color` | Text colour | callers |
| `font_size` | `int` | Design px | the `*_FONT_SIZE` constants |
| `look` | `StringName` | Theme variation | `&"HeadingLight"`, `&"CapsLight"`, `&"ItalicLight"`, default `&"LabelLight"` |

**Returns:** the new `Label`, added to a container by the caller.

**Called by:** [[crawl_sections#add_fight]] (`crawl_sections.gd:84`), [[crawl_sections#_make_heading]] (`crawl_sections.gd:108`), [[crawl_sections#_make_party]] (`crawl_sections.gd:142`, `157`, `162`), [[overlay_credits#_make_line]] (`overlay_credits.gd:248`).

**Calls:** [[hall_font_scale#set_size]], [[hall_style#set_font_color]].

### _make_gap
`func _make_gap() -> Control` · `Scripts/UI/Components/crawl_sections.gd:100`

A blank `GAP_SIZE`-tall Control that ignores the mouse.

**Called by:** [[crawl_sections#add_fight]] (`crawl_sections.gd:73`, `77`, `83`).

### _make_heading
`func _make_heading(text: String, ink_soft: Color) -> Label` · `Scripts/UI/Components/crawl_sections.gd:107`

An uppercase caps heading label.

**Returns:** the `Label`, added by [[crawl_sections#add_fight]] (`crawl_sections.gd:75`, `79`).

**Called by:** [[crawl_sections#add_fight]].

**Calls:** [[crawl_sections#make_line]].

### _make_story
`func _make_story(story: String, ink: Color) -> VBoxContainer` · `Scripts/UI/Components/crawl_sections.gd:115`

The story, one centred line (a BBCode `RichTextLabel`) per non-empty beat. The story's colours are the bright ones meant for dark backgrounds, used as they are (no `STORY_RECOLORS` here).

**Parameters:** `story` (BBCode text) and `ink` from [[crawl_sections#add_fight]].

**Returns:** the `VBoxContainer` of lines, added by [[crawl_sections#add_fight]] (`crawl_sections.gd:76`).

**Called by:** [[crawl_sections#add_fight]].

**Calls:** [[hall_font_scale#set_size]], [[hall_style#set_font_color]].

### _make_party
`func _make_party(result: Dictionary, ink: Color, ink_soft: Color, fell_text: String) -> VBoxContainer` · `Scripts/UI/Components/crawl_sections.gd:137`

Everyone who went: name and role, then whether they fell (with a skull) or survived. A hero counts as fallen if they are in `result.died` or `HallStyle.is_dead`. An empty party shows "Nobody answered the call."

**Parameters:** `result` (party and died), `ink`, `ink_soft`, `fell_text` from [[crawl_sections#add_fight]].

**Returns:** the `VBoxContainer`, added by [[crawl_sections#add_fight]] (`crawl_sections.gd:80`).

**Called by:** [[crawl_sections#add_fight]].

**Calls:** [[crawl_sections#make_line]], [[hall_style#is_dead]], [[hall_style#icon_texture]], [[hall_style#tint_art]], [[hall_style#role_name]].

## Suspected issues
- None found.
