---
source: Scripts/UI/Overlays/Day/overlay_welcome.gd
class_name: ""
extends: Control
scene: "[[overlay_welcome (scene)]]"
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_welcome.gd

## Purpose
"How to Play": a topic menu. The first topic, Basics, is the scene's own rows (the text lives in [[overlay_welcome (scene)]]); the other topics are built here from `TOPICS`. Tapping a topic opens its page; Back returns to the list. On a fresh run with the tutorial off it opens straight on Basics as the "Welcome, Guildmaster" card (Start button). Opened from the Menu it starts on the topic list (Close button).

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TITLE_MENU`, `TITLE_BASICS`, `BUTTON_BACK`, `BUTTON_CLOSE` | const | UI strings. |
| `MAX_PAGE_HEIGHT` | const | Share of screen height a page may fill before it scrolls (0.62). |
| `TOPIC_TITLE_FONT_SIZE`, `TOPIC_BODY_FONT_SIZE` | const | Row heading and body font sizes (design px). |
| `ICONS` | const | Format path `res://Sprites/Hall Icons/%s.tres` for row icons. |
| `TOPICS` | const | Topics after Basics: `{title, icon, rows: [[icon, heading, body], ...]}`. |
| `hall` | var | The [[hall_main]] node. |
| `_start_button`, `_col`, `_title` | onready | `%StartButton`, `$Center/Sheet/Col`, `$Center/Sheet/Col/Title`. |
| `_scroll`, `_body`, `_menu_list` | var | Built in `setup`: scroll container, its page holder, the topic button list. |
| `_basics` | var | The scene's own rows (intro + steps), reparented into one page. |
| `_pages` | var | Built pages, one per `TOPICS` entry. |
| `_back_button` | var | Back button beside Start/Close. |
| `_open` | var | -1 = topic list, 0 = Basics, 1+ = `TOPICS[n - 1]`. |
| `_is_welcome` | var | Opened with no menu behind it (fresh-run welcome): Start, no Back. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:83`

Builds the whole UI in code: wraps the scene's rows into a Basics page inside a `ScrollContainer`, adds the topic buttons and one page per topic, adds the Back button beside Start, and restyles Start green.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] (`hall_main.gd:424`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%StartButton` to [[overlay_welcome#_on_close]]; Back `pressed` to `_show(-1)`; `visibility_changed` to [[overlay_welcome#_on_shown]]; reparents the scene's rows.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:424`).

**Calls:** [[overlay_welcome#_new_page]], [[overlay_welcome#_add_topic_button]], [[overlay_welcome#_build_row]], [[overlay_welcome#_on_shown]], [[hall_style#style_button]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:132`

Does nothing; nothing changes while it is open (hall_main calls it on every visible overlay).

**Returns:** nothing.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1866`).

### _on_shown
`func _on_shown() -> void` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:138`

Each time it opens: `_is_welcome = not hall.is_welcome_from_menu`, then shows Basics (welcome) or the topic list (from the Menu). Ignored when hidden or before `setup`.

**Returns:** nothing.

**Called by:** signal `visibility_changed` on this overlay; [[overlay_welcome#setup]] (once at the end).

**Calls:** [[overlay_welcome#_show]].

### _show
`func _show(index: int) -> void` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:145`

Shows one page: sets `_open`, toggles list/Basics/topic pages, sets the title, Back visibility and Start/Close text, resets scroll, and defers `_fit_scroll`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `index` | `int` | -1 list, 0 Basics, 1+ a `TOPICS` entry | `_on_shown`; the Back button (-1); topic buttons via `_show.bind(index)` from [[overlay_welcome#_add_topic_button]] |

**Returns:** nothing.

**Called by:** [[overlay_welcome#_on_shown]], Back `pressed`, topic button `pressed`.

**Calls:** [[overlay_welcome#_fit_scroll]] (deferred).

### _fit_scroll
`func _fit_scroll() -> void` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:164`

Sets the scroll area's minimum height to the page height, capped at `MAX_PAGE_HEIGHT` of the viewport.

**Returns:** nothing.

**Called by:** [[overlay_welcome#_show]] (`call_deferred`).

### _on_close
`func _on_close() -> void` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:169`

Calls [[hall_main#close_welcome]].

**Returns:** nothing.

**Called by:** signal `pressed` on `%StartButton`.

### _new_page
`func _new_page() -> VBoxContainer` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:173`

Creates an empty page `VBoxContainer` added to `_body`.

**Returns:** `VBoxContainer`, the new page. Used by [[overlay_welcome#setup]] for the Basics page and each topic page.

**Called by:** [[overlay_welcome#setup]].

### _add_topic_button
`func _add_topic_button(text: String, index: int) -> void` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:181`

Adds a "paper" topic button to `_menu_list` whose `pressed` calls `_show(index)`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `text` | `String` | Button label | `TITLE_BASICS` or `TOPICS[i].title` in [[overlay_welcome#setup]] |
| `index` | `int` | Page index to open | 0 for Basics, `i + 1` for topics |

**Returns:** nothing.

**Called by:** [[overlay_welcome#setup]].

**Calls:** [[hall_style#style_button]].

### _build_row
`func _build_row(icon: String, heading: String, body: String) -> HBoxContainer` · `Scripts/UI/Overlays/Day/overlay_welcome.gd:192`

Builds a row like the scene's Basics rows: icon (from `ICONS`), title label, italic body label.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `icon` | `String` | Icon file stem | `row[0]` of a `TOPICS` row |
| `heading` | `String` | Row title | `row[1]` |
| `body` | `String` | Row text | `row[2]` |

**Returns:** `HBoxContainer`, added to a page by [[overlay_welcome#setup]].

**Called by:** [[overlay_welcome#setup]].

**Calls:** [[hall_font_scale#set_size]].

## Suspected issues
- `_show` hardcodes "Start" and "Welcome, Guildmaster" (`overlay_welcome.gd:154,158`) instead of using TEXT constants like the rest of the file.
- The "Story" topic hardcodes "Attacks on Day 10" and "Waits on Day 50" (`overlay_welcome.gd:55,56`), duplicating `HallMain.FINAL_DAY` and boss days.
