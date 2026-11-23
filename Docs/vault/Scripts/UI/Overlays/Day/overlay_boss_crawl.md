---
source: Scripts/UI/Overlays/Day/overlay_boss_crawl.gd
class_name: ""
extends: Control
scene: "[[overlay_boss_crawl (scene)]]"
systems: ["[[Run End]]", "[[UI Motion and Feedback]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# overlay_boss_crawl.gd

## Purpose
The boss fights' text crawl. After End Day on a boss day (10, 20, 30, 40; the final battle has its own credits) the night's boss fights roll up the screen like credits, before the Day Report. Each fight shows its name, the quest story, the party and "Victory!" or "Defeated...". Motion (auto-scroll, hand-over to the player, Continue at the bottom) is done by [[crawl_roll]]; the fight blocks are built by [[crawl_sections]]. Reads `HallMain.shown_boss_crawl` = `{day: int, results: Array}` (results as in [[hall_rules#play_quest]]). Scene: [[overlay_boss_crawl (scene)]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `SCROLL_SPEED` | const | Roll speed (px/s) when every fight was won. |
| `DEFEAT_SCROLL_SPEED` | const | Slower roll speed (px/s) when any fight was lost. |
| `TOP_SPACE_SHARE` | const | Share of the screen height left blank above the title (Reduced Motion uses none). |
| `BOTTOM_SPACE` | const | Blank px under the last line so it can scroll past the pinned button. |
| `BUTTON_FONT_SIZE` | const | Font size of the Continue button. |
| `TEXT_TITLE`, `TEXT_WON`, `TEXT_LOST`, `TEXT_CONTINUE` | const | Strings: "Day %d", "Victory!", "Defeated...", "Continue". |
| `hall` | var | The [[hall_main]] node, set in `setup`. |
| `_built_crawl` | var | The crawl dictionary currently built, so `refresh` rebuilds only for a new one. |
| `_roll` | var | The [[crawl_roll]] child added in `setup`. |
| `_bg`, `_scroll`, `_top_space`, `_sections`, `_bottom_space`, `_footer`, `_continue_button` | onready | Scene nodes `%Bg`, `%Scroll`, `%TopSpace`, `%Sections`, `%BottomSpace`, `%Footer`, `%ContinueButton`. |

No signals declared.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Day/overlay_boss_crawl.gd:61`

Stores the hall, labels and styles Continue (gold), connects it, and creates the [[crawl_roll]] child.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] (`hall_main.gd:427`, loop over `_all_overlays()`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%ContinueButton` to [[hall_main#close_boss_crawl]]; adds a `CrawlRoll` child.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:427`).

**Calls:** [[hall_style#style_button]], [[crawl_roll#setup]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Day/overlay_boss_crawl.gd:71`

Builds the crawl once per new `hall.shown_boss_crawl`. Returns early if it is empty or equal to `_built_crawl`. Otherwise sets the background and title ink by whether every result `succeeded`, adds one fight section per result, and starts the roll (speed by win or loss).

**Returns:** nothing.

**Side effects:** sets `_bg.color` (`HallStyle.CREDITS_BG` or `DEFEAT_BG`), rebuilds `%Sections`, restarts the roll.

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1891`) while the overlay is visible.

**Calls:** [[crawl_sections#show_title]], [[crawl_sections#clear]], [[crawl_sections#add_fight]], [[crawl_roll#start]].

## Suspected issues
- None found.
