---
source: Scripts/UI/Overlays/Day/overlay_quest_travel.gd
class_name: ""
extends: Control
scene: "[[overlay_quest_travel (scene)]]"
systems: ["[[Day Cycle]]", "[[UI Motion and Feedback]]", "[[Run End]]"]
last_verified: 42bbb8f33545f8af5fb02766713031b11eecd919
tags: [script]
---

# overlay_quest_travel.gd

## Purpose
The "Going on a quest" screen shown after End Day while the party is out. A dark screen (`HallStyle.INTRO_BG`) with a walker sprite, a title whose dots cycle, and the `quest_travel` ambience. After a random 2 to 4 seconds a "View quest report" button fades in; nothing before it can be tapped, so the wait can't be skipped. Pressing it stops the sound and calls [[hall_main#close_quest_travel]], which runs the dusk curtain into the Day Report, boss crawl or final credits. Shown while `HallMain.is_quest_travel_open` is true; the night is rolled and saved before it shows, so a reload during it opens straight on the result. Scene: [[overlay_quest_travel (scene)]]. The art slots (`%Backdrop` texture, `%Walker` SpriteFrames) are empty until art is added.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TRAVEL_MIN_SECONDS`, `TRAVEL_MAX_SECONDS` | const | 2.0 and 4.0 s. Shortest and longest wait before the button appears; each trip rolls a length in between. |
| `BOB_PIXELS` | const | 10 px. How far the walker bobs from its rest spot. |
| `BOB_HZ` | const | 1.6 Hz. Bobs per second. |
| `DOT_SECONDS` | const | 0.4 s per step of the title's dot cycle. |
| `MAX_DOTS` | const | 3. Most dots after the title. |
| `BUTTON_FADE_SECONDS` | const | 0.25 s. Button fade-in. |
| `BUTTON_FONT_SIZE` | const | 46. Font size of the button (passed to [[hall_style#style_button]]). |
| `WALKER_REST` | const | `Vector2(130, 130)` px. The walker's rest spot inside `%WalkerHolder`. |
| `TEXT_TITLE`, `TEXT_CONTINUE`, `TEXT_DOT` | const | "Going on a quest", "View quest report", ".". |
| `_bg`, `_walker`, `_title`, `_continue_button` | var (`@onready`) | `%Bg`, `%Walker`, `%Title`, `%ContinueButton`. |
| `hall` | var (HallMain) | Set in [[overlay_quest_travel#setup]]. |
| `trip_seconds` | var (float) | This trip's rolled wait (s). Read by tests. |
| `_is_trip_running` | var (bool) | True from trip start until the button is pressed or the screen hides. |
| `_has_trip_started` | var (bool) | True once a trip started on this showing; stops a refresh during the curtain starting a second trip. Reset when hidden. |
| `_trip_number` | var (int) | Bumped each trip so an older trip's timer can't show a later trip's button. |
| `_elapsed` | var (float) | Seconds since the trip started (drives bob and dots). |
| `_fade_tween` | var (Tween) | The button's fade-in; killed when a trip restarts. |

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:70`

Stores the hall, sets the background colour and the button's text and look, connects the button and the visibility signal, and turns `_process` off.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in the overlay loop of [[hall_main#_ready]] (`hall_main.gd:437`) |

**Returns:** nothing.

**Side effects:** connects `pressed` on `%ContinueButton` to `_on_continue_pressed` and `visibility_changed` to `_on_visibility_changed`.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:437`, via [[hall_main#_all_overlays]]).

**Calls:** [[hall_style#style_button]].

### refresh
`func refresh() -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:81`

Starts a trip when the screen shows (once per showing; later refreshes do nothing).

**Called by:** [[hall_main#_refresh_overlays]] (`hall_main.gd:1929`) while the overlay is visible.

**Calls:** [[overlay_quest_travel#_start_trip]].

### is_button_shown
`func is_button_shown() -> bool` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:88`

True once the trip's wait is over and the button can be pressed (visible and not disabled).

**Returns:** `bool`. No caller in `Globals/`, `Scripts/` or `Scenes/` (probably tests; not traced).

**Called by:** not found in the game folders.

### _start_trip
`func _start_trip() -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:93`

Rolls the wait (`randf_range(TRAVEL_MIN_SECONDS, TRAVEL_MAX_SECONDS)` into `trip_seconds`), hides and disables the button, resets the walker and title, plays `quest_travel`, plays the walker's `default` animation if it has frames, turns `_process` on and starts a timer that shows the button when it ends (only if it is still the same trip).

**Side effects:** `Sfx.play(&"quest_travel")`; kills `_fade_tween`; a `SceneTreeTimer` calling [[overlay_quest_travel#_show_button]].

**Called by:** [[overlay_quest_travel#refresh]].

**Calls:** [[overlay_quest_travel#_update_title]], [[sound_effects#play]], [[overlay_quest_travel#_show_button]] (timer callback).

### _show_button
`func _show_button() -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:117`

The wait is over: shows and enables the button, fading its alpha in over `BUTTON_FADE_SECONDS` unless `HallFx.reduce_motion` (then it is opaque at once).

**Side effects:** creates `_fade_tween`.

**Called by:** the timer created in [[overlay_quest_travel#_start_trip]] (`overlay_quest_travel.gd:111`).

### _process
`func _process(delta: float) -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:129`

Engine callback while a trip runs: adds `delta` to `_elapsed`, bobs the walker (`WALKER_REST.y + sin(_elapsed * TAU * BOB_HZ) * BOB_PIXELS`; held still under Reduced Motion) and updates the title dots. Skips frames when no trip runs or the node isn't visible in the tree.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `delta` | `float` | Seconds since last frame | the engine |

**Returns:** nothing.

**Called by:** the engine (turned on in [[overlay_quest_travel#_start_trip]], off in [[overlay_quest_travel#setup]] and [[overlay_quest_travel#_end_trip]]).

**Calls:** [[overlay_quest_travel#_update_title]].

### _update_title
`func _update_title() -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:141`

Sets the title to `TEXT_TITLE` plus 0 to `MAX_DOTS` dots by elapsed time (`int(_elapsed / DOT_SECONDS) % (MAX_DOTS + 1)`); fixed at `MAX_DOTS` with Reduced Motion.

**Called by:** [[overlay_quest_travel#_start_trip]], [[overlay_quest_travel#_process]].

### _on_continue_pressed
`func _on_continue_pressed() -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:151`

The button: ends the trip once (a second press in the same frame does nothing) and hands back to the hall for the curtain. It plays no sound of its own, so the usual `ui_tap` plays.

**Called by:** `pressed` on `%ContinueButton` (connected in [[overlay_quest_travel#setup]]).

**Calls:** [[overlay_quest_travel#_end_trip]], [[hall_main#close_quest_travel]] (`overlay_quest_travel.gd:155`).

### _end_trip
`func _end_trip() -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:159`

Stops the trip: `_is_trip_running = false`, disables the button, stops the walker, stops the `quest_travel` sound and turns `_process` off.

**Called by:** [[overlay_quest_travel#_on_continue_pressed]], [[overlay_quest_travel#_on_visibility_changed]].

**Calls:** [[sound_effects#stop]].

### _on_visibility_changed
`func _on_visibility_changed() -> void` · `Scripts/UI/Overlays/Day/overlay_quest_travel.gd:169`

When hidden (after the curtain, or mid-trip on a new run): ends a running trip and resets `_has_trip_started` so the next night starts a fresh trip. Does nothing when shown.

**Called by:** `visibility_changed` on the overlay itself (connected in [[overlay_quest_travel#setup]]); [[hall_main#_refresh_overlays]] flips `visible`.

**Calls:** [[overlay_quest_travel#_end_trip]].

## Suspected issues
- The header comment (`overlay_quest_travel.gd:1-3`) has placeholder wording about art ("for now", "Santi's boots or swords art"); not a bug.
- `TRAVEL_MAX_SECONDS` has no `##` comment of its own (it shares the MIN comment).
