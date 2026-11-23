---
source: Scripts/UI/Components/crawl_roll.gd
class_name: CrawlRoll
extends: Node
scene: ""
systems: ["[[UI Motion and Feedback]]", "[[Run End]]", "[[UI Architecture and Refresh]]"]
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# crawl_roll.gd

## Purpose
The motion behind a film-style text crawl: the final credits ([[overlay_credits]]), the boss fights' crawl ([[overlay_boss_crawl]]) and the intro story ([[overlay_intro]]). The roll waits `START_DELAY`, then scrolls itself at a steady speed. Any touch, drag, click or wheel hands it to the player for good. The footer (the overlay's leave button) stays hidden until the bottom is first reached, then stays. Under Reduced Motion (`HallFx.reduce_motion`): no auto-scroll and no blank space above the title. No scene: each overlay makes one with `CrawlRoll.new()`, adds it as a child, calls `setup()` with its own nodes, then `start()` each time it opens.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `START_DELAY` | const | Seconds the roll holds still before it starts to move (1.2). |
| `BOTTOM_SLACK` | const | The bottom counts as reached within this many pixels of the end (4). |
| `LAYOUT_FRAMES` | const | Frames to wait after `start()` before checking whether the roll fits on one screen (2). |
| `_scroll`, `_top_space`, `_bottom_space`, `_footer` | var | The overlay's nodes, set in [[crawl_roll#setup]]. |
| `_is_auto_scrolling` | var | True while the roll moves by itself (until the player touches it or it ends). |
| `_start_wait` | var | Seconds left before the roll starts to move. |
| `_scroll_position` | var | Where the roll is, in fractional pixels (`scroll_vertical` is an int). |
| `_speed` | var | Pixels per second, set by [[crawl_roll#start]]. |

## Functions

### setup
`func setup(scroll: ScrollContainer, top_space: Control, bottom_space: Control, footer: Control) -> void` · `Scripts/UI/Components/crawl_roll.gd:44`

Hooks up the overlay's nodes, connects the vertical scrollbar's `value_changed` to [[crawl_roll#_on_scrolled]], and turns processing off.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `scroll` | `ScrollContainer` | Holds the roll | `_scroll` of the overlay |
| `top_space` | `Control` | Blank Control at the top | `_top_space` of the overlay |
| `bottom_space` | `Control` | Blank Control at the bottom | `_bottom_space` of the overlay |
| `footer` | `Control` | Shown once the bottom is first reached (the leave button) | `_footer` of the overlay |

**Returns:** nothing.

**Called by:** [[overlay_boss_crawl#setup]] (`overlay_boss_crawl.gd:68`), [[overlay_intro#setup]] (`overlay_intro.gd:79`), [[overlay_credits#setup]] (`overlay_credits.gd:123`).

### start
`func start(speed: float, top_space_share: float, bottom_space: float) -> void` · `Scripts/UI/Components/crawl_roll.gd:59`

Back to the top with the footer hidden, then (motion allowed) wait and roll. Sets the blank space above (`top_space_share` of the overlay's height, 0 under Reduced Motion) and below, and checks once whether the roll fits on one screen ([[crawl_roll#_check_fits]]).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `speed` | `float` | Pixels per second | `SCROLL_SPEED` / `DEFEAT_SCROLL_SPEED` constants of the overlay |
| `top_space_share` | `float` | Share of the screen height left blank above the title | `TOP_SPACE_SHARE` |
| `bottom_space` | `float` | Blank pixels under the last line, so it can scroll up past the pinned footer | `BOTTOM_SPACE` |

**Returns:** nothing.

**Side effects:** hides the footer, resets scroll, enables `_process` when auto-scrolling.

**Called by:** [[overlay_boss_crawl#refresh]] (`overlay_boss_crawl.gd:90`), [[overlay_intro#refresh]] (`overlay_intro.gd:89`), [[overlay_credits#_start_roll]] (`overlay_credits.gd:160`).

**Calls:** [[crawl_roll#_check_fits]].

### _process
`func _process(delta: float) -> void` · `Scripts/UI/Components/crawl_roll.gd:76`

Each frame while auto-scrolling: waits out `START_DELAY`, advances `_scroll_position` by `_speed * delta`, and stops at the bottom. Switches itself off if not scrolling or the overlay isn't shown. Called by the engine.

**Called by:** the engine.

**Calls:** [[crawl_roll#_is_shown]], [[crawl_roll#_is_at_bottom]], [[crawl_roll#_stop_auto_scroll]].

### _input
`func _input(event: InputEvent) -> void` · `Scripts/UI/Components/crawl_roll.gd:91`

Any screen touch, screen drag or mouse press while the roll moves gives it to the player. Called by the engine.

**Called by:** the engine.

**Calls:** [[crawl_roll#_stop_auto_scroll]], [[crawl_roll#_is_shown]].

### _stop_auto_scroll
`func _stop_auto_scroll() -> void` · `Scripts/UI/Components/crawl_roll.gd:100`

Ends auto-scroll and turns processing off.

**Called by:** [[crawl_roll#_process]] (`crawl_roll.gd:87`), [[crawl_roll#_input]] (`crawl_roll.gd:97`).

### _on_scrolled
`func _on_scrolled(_value: float) -> void` · `Scripts/UI/Components/crawl_roll.gd:107`

The first time the roll reaches the bottom the footer appears (with [[hall_fx#appear]]) and stays from then on.

**Called by:** signal `value_changed` on the scroll container's vertical scrollbar (connected in [[crawl_roll#setup]], `crawl_roll.gd:49`), and [[crawl_roll#_check_fits]] (`crawl_roll.gd:120`).

**Calls:** [[crawl_roll#_is_at_bottom]], [[hall_fx#appear]].

### _check_fits
`func _check_fits() -> void` · `Scripts/UI/Components/crawl_roll.gd:115`

After `start()`: waits `LAYOUT_FRAMES` frames for the layout (`await`), then shows the footer if the whole roll already fits (only possible under Reduced Motion, with no top space). An unlaid-out bar reads 0 / 0, which would count as the bottom, so it requires `max_value > 0`.

**Called by:** [[crawl_roll#start]] (`crawl_roll.gd:73`).

**Calls:** [[crawl_roll#_on_scrolled]].

### _is_at_bottom
`func _is_at_bottom() -> bool` · `Scripts/UI/Components/crawl_roll.gd:124`

True when the roll is scrolled to (or within `BOTTOM_SLACK` of) its end.

**Returns:** `bool`, used by [[crawl_roll#_process]] to stop and by [[crawl_roll#_on_scrolled]] to reveal the footer.

**Called by:** [[crawl_roll#_process]] (`crawl_roll.gd:86`), [[crawl_roll#_on_scrolled]] (`crawl_roll.gd:108`).

### _is_shown
`func _is_shown() -> bool` · `Scripts/UI/Components/crawl_roll.gd:130`

True while the overlay this roll belongs to (its parent) is visible in the tree.

**Returns:** `bool`, used by [[crawl_roll#_process]] and [[crawl_roll#_input]] (`crawl_roll.gd:77`, `92`).

**Called by:** [[crawl_roll#_process]], [[crawl_roll#_input]].

## Suspected issues
- None found.
