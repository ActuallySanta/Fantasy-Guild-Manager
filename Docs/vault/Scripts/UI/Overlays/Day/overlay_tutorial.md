---
source: Scripts/UI/Overlays/Day/overlay_tutorial.gd
class_name: OverlayTutorial
extends: Control
scene: ""
systems: ["[[UI Architecture and Refresh]]"]
last_verified: 2fae2e0b444f59e9c76be8bda1b39c0f01fc4ea2
tags: [script]
---

# overlay_tutorial.gd

## Purpose
The tutorial coach: Pip the guild clerk walks a new player through the real hall UI on Days 1, 2, 5 and `GuildUpgrades.UNLOCK_DAY` (10), plus a one-card freeplay script. Each step spotlights one control (gold ring, bouncing arrow, everything else dimmed and its buttons disabled) and waits for the player to use it, or for Next on explain-only steps. It is **built entirely in code** (no scene): [[hall_main#_ready]] creates it with `OverlayTutorial.new()` and adds it on top of every overlay. UI only: it calls just hall_main's own actions and queries.

**Steps** are dictionaries: `text` (String or Callable, BBCode), `do` (instruction line), `target` (Callable returning the Control to spotlight), `on` (the `tutorial_event` name that finishes the step; absent = Next button), `when` (Callable(data) -> bool that must hold), `reject` (toast when `on` fires but `when` is false; the opened screen is closed again), `skip` (Callable -> bool checked when the step comes up), `tap` (spotlit control usable on a Next step), `deny` (node names inside the spotlight kept disabled), `bare` (no bubble, only ring and arrow), `free` (hall fully usable, no dim, no Pip). If a target can't be found for `MISSING_GRACE` seconds, Next appears so the player can't get stuck.

**Events** come from `hall_main.tutorial_event(event, data)`: tab, hire, character, close, assign, pick, send, deny, end_check, end_day, read_letter, new_day, upgrade, training_picker, train, admit, buy, equip, freeplay (also game_over). Listeners of that signal: this script (`overlay_tutorial.gd:248`) and `run_logger.gd:89`.

**Tab and feature pacing:** Guild and Items tabs are locked by day in every run ([[hall_main#is_tab_locked]]); while the tutorial is on, Applicants, hero pages and Deny stay locked until `UNLOCK_DAY` (day 2). Skip tutorial lifts the feature locks but not the tab locks.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `ENABLED` | const | Off = no coach, no locks, old Welcome card. |
| `TUTORIAL_DAYS` | const | Days with a fixed script: 1, 2, 5. Day `GuildUpgrades.UNLOCK_DAY` also runs `GUILD_SCRIPT`. |
| `GUILD_SCRIPT` | const | Script key (3) for the Guild tab walkthrough. |
| `FREEPLAY_SCRIPT` | const | Script key (-1) for the freeplay card; starts on the `freeplay` event. |
| `FEATURE_HIRE`, `FEATURE_HERO_PAGE`, `FEATURE_DENY` | const | Feature ids held back while the tutorial is on. |
| `UNLOCK_DAY` | const | First day (2) each feature opens while the tutorial is on. |
| `PIP_CAN_MOVE`, `SHOW_BACK_BUTTON` | const | SIMPLIFIED switches (both false): tap Pip to swap docks; Back button in the bubble. |
| `TUTORIAL_Z_INDEX` | const | Draw order (20), above overlays and raised tab art. |
| `RING_COLOR` | const | Gold of the ring and arrow. |
| `HOLE_PAD`, `BUBBLE_MARGIN`, `BUBBLE_CLEARANCE` | const | Spotlight padding, bubble screen margin, and gap kept between bubble and spotlight (px). |
| `DOCK_HYSTERESIS` | const | 20.0 design px. How far the spotlight must move past a dock cut-off before Pip changes side or shape mid-step. Without it, a spotlight the player scrolled to sit right on a cut-off flipped Pip top <-> bottom every frame. Used in [[overlay_tutorial#_layout]]; guarded by `tools/tests/tutorial_dock_test.gd`. |
| `MISSING_GRACE` | const | Seconds a target may be missing before Next shows. |
| `LOCK_INTERVAL` | const | Seconds between re-disabling outside buttons (the hall rebuilds rows on refresh). |
| `DIM_COLOR` | const | Translucent black wash (alpha 0.55). |
| `HINT_FONT_SIZE`, `NAME_FONT_SIZE`, `COUNTER_FONT_SIZE`, `BODY_FONT_SIZE`, `INSTRUCTION_FONT_SIZE` | const | Bubble text sizes (design px). |
| `POW`, `DEF`, `WIS`, `SLZ`, `PLK`, `GOLD` | const | Coloured BBCode words for stats and gold. |
| `PORTRAIT_MASK`, `PORTRAIT_FRAME`, `ARROW_ICON`, `PIP_GROUND`, `PIP_ART`, `PIP_ART_ANCHORS` | const | Pip's portrait art, arrow icon, ground tint and art box (anchors). |
| `hall` | var | The hall (untyped `Control`), set in `setup`. |
| `is_skipped` | var | True once Skip tutorial was tapped; saved by [[hall_save]] (`hall_save.gd:127`, restored at `:341`). |
| `done` | var | Scripts finished or skipped (day or `FREEPLAY_SCRIPT`); saved and restored the same way. |
| `_day`, `_script`, `_steps`, `_index` | var | Day shown on the counter, running script key, its steps, current step (-1 = idle). |
| `_seen` | var | Events seen during this script (for `skip` checks). |
| `_bought_item` | var | Item bought on Day 5, to point at a hero who can use it. |
| `_missing_for`, `_last_target`, `_time`, `_shake_until`, `_shown_text`, `_lock_timer` | var | Per-frame step state. |
| `_locked` | var | Buttons this coach disabled, mapped to their own `disabled` value. |
| `_dock_bottom`, `_dock_forced`, `_expanded`, `_bubble_goal` | var | Bubble docking state. |
| `_shown_full` | var (bool) | Pip's full bubble (not the chip) was docked clear of a spotlight last frame. Set at the end of [[overlay_tutorial#_layout]], cleared in [[overlay_tutorial#_reset_step]]. |
| `_dock_settled` | var (bool) | Pip has picked a side for this step's spotlight; from then on the dock cut-offs are sticky (`DOCK_HYSTERESIS`). Set in `_layout` once a spotlight has area, cleared in `_reset_step`. |
| `_history`, `_forward`, `_reached` | var | Back/Next retracing and the furthest step reached (earlier steps are read-only). |
| `_blockers`, `_cover`, `_ring`, `_pointer`, `_bubble`, `_face`, `_counter`, `_text`, `_do_label`, `_hint`, `_next_button`, `_back_button`, `_skip_button` | var | Nodes built in `_build`. |

No signals declared.

## Functions

### setup
`func setup(main: Control) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:240`

Stores the hall, fills the screen, builds the nodes, hides itself, and listens to `tutorial_event`. On a fresh Day 1 run (not resumed) it also turns the Welcome card off and starts the Day 1 script, unless the intro crawl is open (then [[hall_main#close_intro]] calls `resume_today`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `Control` | The hall | `self` in [[hall_main#_ready]] (`hall_main.gd:462`, after `add_child(tutorial)`) |

**Returns:** nothing.

**Side effects:** connects `hall.tutorial_event` to [[overlay_tutorial#_on_event]]; may set `hall.is_welcome_open = false`; defers [[overlay_tutorial#start]] (1).

**Called by:** [[hall_main#_ready]] (`hall_main.gd:462`).

**Calls:** [[overlay_tutorial#_build]], [[hall_main#is_intro_open]], [[overlay_tutorial#start]].

### resume_today
`func resume_today() -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:261`

After a saved run loads (or the intro closes): if today has a tutorial script not yet done, run it from its first step. Does nothing when disabled, skipped, not a tutorial day, already done or running, while the intro is open, or while a report, credits, Game Over or boss crawl is up.

**Returns:** nothing.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:475`, resumed run); [[hall_main#close_intro]] (`hall_main.gd:929`).

**Calls:** [[overlay_tutorial#_is_tutorial_day]], [[overlay_tutorial#_script_for_day]], [[overlay_tutorial#is_running]], [[hall_main#is_intro_open]], [[overlay_tutorial#start]] (deferred).

### is_locked
`func is_locked(feature: String) -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:275`

True while the tutorial holds `feature` back: enabled, not skipped, the feature is in `UNLOCK_DAY`, and `GameState.day` is earlier than its day.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `feature` | `String` | A `FEATURE_*` id | [[hall_main#is_locked]] (`hall_main.gd:699`), whose callers pass `OverlayTutorial.FEATURE_*` (e.g. `tab_board.gd:76`, `screen_assign.gd:384`, `member_card.gd:54`) |

**Returns:** `bool`. Used by `hall_main.is_locked` to grey out Applicants, hero pages and Deny.

**Called by:** [[hall_main#is_locked]] (`hall_main.gd:699`).

### _is_tutorial_day
`func _is_tutorial_day(day: int) -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:283`

True if `day` is in `TUTORIAL_DAYS` or equals `GuildUpgrades.UNLOCK_DAY`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day number | `GameState.day` in [[overlay_tutorial#resume_today]]; `int(data)` of the `new_day` event in [[overlay_tutorial#_on_event]] |

**Returns:** `bool`.

**Called by:** [[overlay_tutorial#resume_today]], [[overlay_tutorial#_on_event]].

### _script_for_day
`func _script_for_day(day: int) -> int` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:289`

The script key for `day`: `GUILD_SCRIPT` on `GuildUpgrades.UNLOCK_DAY`, otherwise the day itself. It is also the key in `done`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | A day number | as in [[overlay_tutorial#_is_tutorial_day]] |

**Returns:** `int` script key.

**Called by:** [[overlay_tutorial#resume_today]], [[overlay_tutorial#_on_event]].

### is_running
`func is_running() -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:293`

True while a script is active (`_index >= 0`).

**Returns:** `bool`. Used by hall_main to skip the tutorial when a run ends and by the Debug overlay to enable its buttons.

**Called by:** [[hall_main#debug_skip_tutorial]] (`hall_main.gd:1493`); [[hall_main#_show_final_credits]] (`hall_main.gd:1601`); [[hall_main#_check_run_over]] (`hall_main.gd:1690`); [[overlay_debug#refresh]] (`overlay_debug.gd:148`, `:150`, which enables its tutorial and intro buttons); [[overlay_tutorial#resume_today]], [[overlay_tutorial#_on_event]], [[overlay_tutorial#_process]].

### start
`func start(day: int, script: int = day) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:300`

Runs a script: resets step state, shows the overlay, enables `_process`, parks the bubble below the screen and advances to the first step.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `day` | `int` | Day shown on Pip's counter | `1` in [[overlay_tutorial#setup]]; `GameState.day` in [[overlay_tutorial#resume_today]]; `int(data)` of `new_day` or `freeplay` in [[overlay_tutorial#_on_event]] |
| `script` | `int` | Script key; defaults to `day` | `_script_for_day(day)` or `FREEPLAY_SCRIPT` |

**Returns:** nothing.

**Called by:** [[overlay_tutorial#setup]] (`overlay_tutorial.gd:254`, deferred), [[overlay_tutorial#resume_today]] (`:270`, deferred), [[overlay_tutorial#_on_event]] (`:380`, `:386`).

**Calls:** [[overlay_tutorial#_steps_for]], [[overlay_tutorial#_advance]].

### _advance
`func _advance() -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:315`

Moves to the next step: records history, retraces `_forward` after a Back, otherwise skips steps whose `skip` returns true, and finishes after the last.

**Returns:** nothing.

**Called by:** [[overlay_tutorial#start]], [[overlay_tutorial#_on_event]], signal `pressed` on the Next button (`_next_button`).

**Calls:** [[overlay_tutorial#_reset_step]], [[overlay_tutorial#_finish]].

### _go_back
`func _go_back() -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:333`

Shows the previous step again, read-only.

**Returns:** nothing.

**Called by:** signal `pressed` on the Back button (`_back_button`; hidden while `SHOW_BACK_BUTTON` is false).

**Calls:** [[overlay_tutorial#_reset_step]].

### _is_reviewing
`func _is_reviewing() -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:342`

True when the current step is before the furthest reached (its action is already done).

**Returns:** `bool`. Used by `_on_event`, `_is_free`, `_is_live`, `_layout`.

**Called by:** [[overlay_tutorial#_on_event]], [[overlay_tutorial#_is_free]], [[overlay_tutorial#_is_live]], [[overlay_tutorial#_layout]].

### _reset_step
`func _reset_step() -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:346`

Clears the per-step state (missing timer, last target, shown text, dock force, expanded chip, `_shown_full`, `_dock_settled`, lock timer).

**Returns:** nothing.

**Called by:** [[overlay_tutorial#_advance]], [[overlay_tutorial#_go_back]].

### _finish
`func _finish() -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:357`

Marks the script `done`, goes idle, hides, stops processing, releases locks and asks the hall for a refresh.

**Returns:** nothing.

**Side effects:** sets `done[_script]`; re-enables every locked button; calls [[hall_main#queue_refresh]].

**Called by:** [[overlay_tutorial#_advance]], [[overlay_tutorial#skip_tutorial]], [[overlay_tutorial#_on_event]].

**Calls:** [[overlay_tutorial#_release_locks]], [[hall_main#queue_refresh]].

### skip_tutorial
`func skip_tutorial() -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:367`

Sets `is_skipped` (which also lifts the feature locks) and finishes the running script.

**Returns:** nothing.

**Called by:** [[hall_main#debug_skip_tutorial]] (`hall_main.gd:1494`); [[hall_main#_show_final_credits]] (`hall_main.gd:1602`); [[hall_main#_check_run_over]] (`hall_main.gd:1691`); signal `pressed` on the "Skip tutorial" button (`_skip_button`).

**Calls:** [[overlay_tutorial#_finish]].

### _on_event
`func _on_event(event: String, data: Variant = null) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:372`

Handles every `tutorial_event`. Records it in `_seen`; remembers a bought item; starts the day's script on `new_day` (tutorial days not yet done) and the freeplay script on `freeplay` (even after Skip). Otherwise, if the current step waits for this event and its `when` holds, advances; if `when` fails and the step has `reject`, shows an error toast and closes the screen.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `String` | Event name | first arg of `hall.tutorial_event.emit(...)` in [[hall_main]] (e.g. `hall_main.gd:775`, `:801`, `:1519`, `:1674`, `:1741`, `:1748`) |
| `data` | `Variant` | Event payload (tab dict, quest index, hero, item, day...) | second arg of the same emit |

**Returns:** nothing.

**Called by:** signal `tutorial_event` on [[hall_main]] (connected in [[overlay_tutorial#setup]], `overlay_tutorial.gd:248`).

**Calls:** [[overlay_tutorial#start]], [[overlay_tutorial#_finish]], [[overlay_tutorial#_advance]], [[hall_main#show_error_toast]], [[hall_main#close_screen]] (deferred).

### _process
`func _process(delta: float) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:403`

Engine callback each frame while a script runs. Finds the step's target (must be a valid, visible Control), scrolls it into view when it changes, counts how long it has been missing, re-applies or releases button locks every `LOCK_INTERVAL`, then lays out.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `delta` | `float` | Seconds since last frame | the engine |

**Returns:** nothing.

**Called by:** the engine (enabled by [[overlay_tutorial#start]], disabled in `setup` and [[overlay_tutorial#_finish]]).

**Calls:** [[overlay_tutorial#is_running]], [[overlay_tutorial#_scroll_into_view]], [[overlay_tutorial#_is_free]], [[overlay_tutorial#_release_locks]], [[overlay_tutorial#_apply_locks]], [[overlay_tutorial#_layout]].

### _is_free
`func _is_free(step: Dictionary) -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:435`

A `free` step (no dim, no locks, no Pip). A step re-read after Back is never free.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `step` | `Dictionary` | The current step | `_steps[_index]` in `_process` and `_layout` |

**Returns:** `bool`.

**Called by:** [[overlay_tutorial#_process]], [[overlay_tutorial#_layout]].

### _is_live
`func _is_live(step: Dictionary) -> bool`  · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:440`

Is the spotlit control meant to be used: not reviewing, and the step has `on` or `tap`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `step` | `Dictionary` | The current step | `_steps[_index]` |

**Returns:** `bool`.

**Called by:** [[overlay_tutorial#_apply_locks]], [[overlay_tutorial#_layout]].

### _apply_locks
`func _apply_locks(step: Dictionary, target: Control) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:449`

Disables every button in the hall except those inside a live spotlight (and not named in `deny`), remembering each button's own `disabled` value in `_locked`. If the hall re-enabled a locked button in a refresh, that becomes its remembered state. Rows that are tap panels are stopped by the dim blockers instead.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `step` | `Dictionary` | Current step | `_process` |
| `target` | `Control` | The spotlit control, or null | found in `_process` from `step.target` |

**Returns:** nothing.

**Side effects:** sets `disabled` on many buttons; edits `_locked`.

**Called by:** [[overlay_tutorial#_process]].

**Calls:** [[overlay_tutorial#_is_live]], [[overlay_tutorial#_collect_buttons]].

### _collect_buttons
`func _collect_buttons(node: Node, out: Array) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:472`

Appends every `BaseButton` under `node` to `out`, skipping this overlay and any `CanvasLayer`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Node` | Where to start | `hall` in [[overlay_tutorial#_apply_locks]], then recursion |
| `out` | `Array` | Collected buttons | the `buttons` array in `_apply_locks` |

**Returns:** nothing (fills `out`).

**Called by:** [[overlay_tutorial#_apply_locks]] (and itself).

### _is_enabled
`func _is_enabled(button: BaseButton) -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:482`

A button's own enabled state, ignoring this coach's locks.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `button` | `BaseButton` | A button | the filter callables in the Guild script's steps (`overlay_tutorial.gd:1107`, `:1115`) |

**Returns:** `bool`. Used as a `_row` filter so the step points at an enabled button.

**Called by:** the target/filter lambdas in [[overlay_tutorial#_day_three]].

### _release_locks
`func _release_locks() -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:486`

Restores every locked button's own `disabled` value and clears `_locked`.

**Returns:** nothing.

**Called by:** [[overlay_tutorial#_finish]], [[overlay_tutorial#_process]] (free steps).

### _layout
`func _layout(step: Dictionary, target: Control, delta: float) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:494`

Per frame: computes the spotlight hole, positions the four dim blockers around it (none on free steps), the cover over explain-only holes, and the pulsing ring; sets the bubble's text, counter ("Day N · i/n"), instruction line and Next/Back text; picks the top or bottom dock clear of the hole (or shrinks to a chip), with hysteresis so scrolling inside a live spotlight can't make Pip flicker; glides the bubble there (with a shake after a blocked tap); and places the arrow just outside the hole.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `step` | `Dictionary` | Current step | `_process` |
| `target` | `Control` | Spotlit control or null | `_process` |
| `delta` | `float` | Frame seconds | `_process` |

**Returns:** nothing.

**Side effects:** plays `Sfx.play(&"pip_talk")` when a step's text first appears.

**Called by:** [[overlay_tutorial#_process]].

**Calls:** [[overlay_tutorial#_is_free]], [[overlay_tutorial#_is_reviewing]], [[overlay_tutorial#_is_live]], [[overlay_tutorial#_set_rect]], [[overlay_tutorial#_set_compact]], [[overlay_tutorial#_measure_bubble]].

> [!note] Dock hysteresis (new)
> Pip's bubble can sit at the top or bottom, in full or as a small chip. Every cut-off is sticky by `DOCK_HYSTERESIS` (20 px):
> - **Full bubble clear test:** a side counts as clear when its rect misses the spotlight grown by `BUBBLE_CLEARANCE`. The side Pip already sits on in full (`_shown_full`) only needs the smaller gap `BUBBLE_CLEARANCE - DOCK_HYSTERESIS`, so it stays put; a new side needs the whole clearance.
> - **Choosing a side:** `margin` is `DOCK_HYSTERESIS` once `_dock_settled`, else 0 (a new step picks freely). If only the other side is clear Pip moves there. If both are clear Pip moves only when the spotlight's centre is more than `margin` px into Pip's own half of the screen.
> - **Chip corner (neither side clear):** Pip changes corner only when the other corner overlaps the spotlight by clearly less (by a `DOCK_HYSTERESIS`-tall strip of the chip), or on the first frame of a step when it's merely less.
> - At the end, `_shown_full = hole.has_area() and fits` and `_dock_settled |= hole.has_area()`.

### _set_compact
`func _set_compact(is_compact: bool) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:633`

Full bubble or a chip (Pip plus the instruction): hides text, counter and Skip when compact and sets the hint text.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `is_compact` | `bool` | Shrink to a chip | `false` first, then `true` in `_layout` when neither dock is clear |

**Returns:** nothing.

**Called by:** [[overlay_tutorial#_layout]].

### _measure_bubble
`func _measure_bubble(width: float) -> float`  · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:643`

Sets the bubble's width and returns its minimum height.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `width` | `float` | Bubble width (px) | screen width minus margins in `_layout` |

**Returns:** `float`, the bubble's combined minimum height (px). Used by `_layout` to test which dock fits.

**Called by:** [[overlay_tutorial#_layout]].

### _set_rect
`func _set_rect(control: Control, rect: Rect2) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:648`

Sets a control's position and size, visible only when the rect has area.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `control` | `Control` | A blocker or the cover | `_blockers[i]`, `_cover` |
| `rect` | `Rect2` | Area to cover (empty hides it) | computed from the hole in `_layout` |

**Returns:** nothing.

**Called by:** [[overlay_tutorial#_layout]].

### _scroll_into_view
`func _scroll_into_view(target: Control) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:655`

Walks up from the target to the first `ScrollContainer` below the hall and centres the target in it (deferred).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `target` | `Control` | The spotlit control | `_process` when the target changes |

**Returns:** nothing.

**Called by:** [[overlay_tutorial#_process]].

**Calls:** [[overlay_tutorial#_center_in_scroll]] (deferred).

### _center_in_scroll
`func _center_in_scroll(scroll: ScrollContainer, target: Control) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:664`

Sets `scroll.scroll_vertical` so the target sits in the middle (skips freed nodes).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `scroll` | `ScrollContainer` | The scroll holding the target | found in `_scroll_into_view` |
| `target` | `Control` | The spotlit control | `_scroll_into_view` |

**Returns:** nothing.

**Called by:** [[overlay_tutorial#_scroll_into_view]] (deferred).

### _on_blocked_input
`func _on_blocked_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:671`

A tap on the dim or cover makes the bubble shake for 0.35 s.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on each blocker and on `_cover` (connected in `_build`) |

**Returns:** nothing.

**Called by:** signal `gui_input` on the dim blockers and `_cover`.

**Calls:** [[overlay_tutorial#_is_press]].

### _on_face_input
`func _on_face_input(event: InputEvent) -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:678`

Tap Pip: opens the compact chip, or (only with `PIP_CAN_MOVE`) swaps top and bottom; otherwise closes an opened chip.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | `gui_input` on `_face` |

**Returns:** nothing.

**Called by:** signal `gui_input` on Pip's portrait (`_face`).

**Calls:** [[overlay_tutorial#_is_press]].

### _is_press
`func _is_press(event: InputEvent) -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:692`

True for a left mouse press or a screen touch press.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `InputEvent` | Raw input | the two input handlers above |

**Returns:** `bool`.

**Called by:** [[overlay_tutorial#_on_blocked_input]], [[overlay_tutorial#_on_face_input]].

### _build
`func _build() -> void` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:697`

Builds every node in code: four dim blockers, the cover, the gold ring (stamp stylebox), the arrow `Pointer`, and Pip's bubble (portrait, hint, name, step counter, rich text, instruction label, Back / Next / Skip tutorial buttons).

**Returns:** nothing.

**Side effects:** connects `gui_input` on blockers and cover to [[overlay_tutorial#_on_blocked_input]], on the face to [[overlay_tutorial#_on_face_input]]; `pressed` on Back to [[overlay_tutorial#_go_back]], on Next to [[overlay_tutorial#_advance]], on Skip to [[overlay_tutorial#skip_tutorial]].

**Called by:** [[overlay_tutorial#setup]].

**Calls:** [[overlay_tutorial#_build_portrait]], [[hall_style#tint_art]], [[hall_style#set_look]], [[hall_style#style_button]], [[hall_font_scale#set_size]], [[hall_style#set_font_color]].

### _build_portrait
`func _build_portrait() -> Control` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:835`

Pip's portrait: art on the round mask (parchment ground, clipped by [[hall_style#mask_to]]), with the round frame on top, like the heroes' portraits.

**Returns:** `Control`, the portrait holder. [[overlay_tutorial#_build]] adds it as `_face`.

**Called by:** [[overlay_tutorial#_build]].

**Calls:** [[hall_style#tint_art]], [[hall_style#mask_to]].

### Pointer._draw
`func _draw() -> void` (inner class `Pointer extends Control`) · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:881`

Draws the left-pointing arrow icon rotated to point down (`points_down`) or up, tinted gold. `Pointer` has the vars `points_down`, `arrow`, `tint`.

**Returns:** nothing.

**Called by:** the engine (redraw requested by `_layout` via `queue_redraw`).

### _tab
`func _tab(tab_id: String) -> Node` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:893`

The hall's tab node for `tab_id` (reads `hall._tabs`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tab_id` | `String` | "board", "guild", "upgrades" or "shop" | literals in the step scripts |

**Returns:** `Node`, the tab. Used by target lambdas.

**Called by:** [[overlay_tutorial#_training_section]], [[overlay_tutorial#_hospital_section]], and the step lambdas in [[overlay_tutorial#_day_one]], [[overlay_tutorial#_day_two]], [[overlay_tutorial#_day_three]], [[overlay_tutorial#_day_five]].

### _screen
`func _screen(kind: String) -> Node` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:897`

The hall's screen node for `kind` ("assign", "character"; reads `hall._screens`).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `kind` | `String` | Screen id | literals in the step scripts |

**Returns:** `Node`.

**Called by:** step lambdas in [[overlay_tutorial#_day_one]], [[overlay_tutorial#_day_two]], [[overlay_tutorial#_day_five]].

### _nav
`func _nav(tab_id: String) -> Control` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:901`

A nav button via [[hall_main#nav_button]].

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tab_id` | `String` | Tab id | literals in the step scripts |

**Returns:** `Control`, the nav button.

**Called by:** step lambdas in all four day scripts.

**Calls:** [[hall_main#nav_button]].

### _u
`func _u(node: Node, unique_name: String) -> Control` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:906`

A scene-unique node (`%Name`) inside `node`'s scene, or null.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `node` | `Node` | Scene root to search | `_tab(...)`, `_screen(...)`, `_report()`, the hall's overlays |
| `unique_name` | `String` | The `%` name without the percent | literals such as `"SegRoster"` |

**Returns:** `Control`, or null if `node` is null or has no such node.

**Called by:** [[overlay_tutorial#_row]], [[overlay_tutorial#_training_section]], [[overlay_tutorial#_hospital_section]], step lambdas.

### _row
`func _row(root: Node, script_file: String, unique_child := "", filter := Callable()) -> Control` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:914`

Breadth-first search under `root` for the first visible control whose script file name is `script_file` (e.g. `member_card.gd`), or its `%unique_child`, that passes `filter`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `root` | `Node` | Where to search | `_tab(...)`, `_report()`, `_training_section()`... |
| `script_file` | `String` | Script file name of the row | literals in the steps |
| `unique_child` | `String` | Optional `%` child to return instead | literals |
| `filter` | `Callable` | Optional test on the hit | lambdas using `_is_enabled` or the item text |

**Returns:** `Control`, the match, or null.

**Called by:** [[overlay_tutorial#_report_letter]] and step lambdas in the day scripts.

**Calls:** [[overlay_tutorial#_u]].

### _report
`func _report() -> Node` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:930`

The Day Report overlay (`hall.get_node("%OverlayReport")`, i.e. [[overlay_report (scene)]]).

**Returns:** `Node`. Used by `_report_letter` and the Day 1 report steps.

**Called by:** [[overlay_tutorial#_report_letter]], [[overlay_tutorial#_day_one]].

### _report_letter
`func _report_letter(folded: bool) -> Control` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:936`

The first everyday (non-story) letter in the report that is folded (`folded` true) or open.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `folded` | `bool` | Wanted fold state | literals `true` / `false` in [[overlay_tutorial#_day_one]] |

**Returns:** `Control`, the [[report_entry]] letter or null.

**Called by:** [[overlay_tutorial#_day_one]].

**Calls:** [[overlay_tutorial#_row]], [[overlay_tutorial#_report]].

### _has_foldable_letter
`func _has_foldable_letter() -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:943`

True when tonight's report has a non-story letter (reads `hall.shown_report`, so it works before the letters are built).

**Returns:** `bool`. Used as the `skip` test of the two letter steps.

**Called by:** [[overlay_tutorial#_day_one]].

**Calls:** [[hall_style#is_story_quest]].

### _training_section
`func _training_section() -> Node` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:947`

The Guild tab's `%TrainingSection`.

**Returns:** `Node`.

**Called by:** [[overlay_tutorial#_day_three]].

**Calls:** [[overlay_tutorial#_u]], [[overlay_tutorial#_tab]].

### _hospital_section
`func _hospital_section() -> Node` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:951`

The Guild tab's `%HospitalSection`.

**Returns:** `Node`.

**Called by:** [[overlay_tutorial#_day_three]].

**Calls:** [[overlay_tutorial#_u]], [[overlay_tutorial#_tab]].

### _party_ready
`func _party_ready(entry: Dictionary) -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:957`

Day 1's party is ready with two heroes, or fewer if the quest or roster is smaller (at least 1).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `entry` | `Dictionary` | The quest entry from the `pick` event | `d` in the `when` lambda of the Day 1 pick step (payload of `hall_main.gd:987`) |

**Returns:** `bool`. Decides whether the `pick` event finishes the step.

**Called by:** [[overlay_tutorial#_day_one]].

**Calls:** [[hall_main#party_size_limit]], [[hall_main#roster]].

### _pick_text
`func _pick_text() -> String`  · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:962`

Pick-step text: "This quest requires one adventurer only." for one-slot quests, otherwise the tap instruction.

**Returns:** `String` (BBCode). Used as the step's `text` callable.

**Called by:** [[overlay_tutorial#_day_one]].

**Calls:** [[hall_main#current_quest_entry]], [[hall_main#party_size_limit]].

### _tonight_text
`func _tonight_text() -> String` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:971`

The Facilities step text: Training Yard and Hospital in one line, prefixed with a "Nothing you can build yet!" note when no `upgrade` event was seen.

**Returns:** `String`.

**Called by:** [[overlay_tutorial#_day_three]].

### _shop_open_text
`func _shop_open_text() -> String` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:979`

Day 5's first step text, with a heads-up when nothing in the Shop is affordable.

**Returns:** `String`.

**Called by:** [[overlay_tutorial#_day_five]].

**Calls:** [[overlay_tutorial#_any_affordable]].

### _anyone_can_train
`func _anyone_can_train() -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:986`

True if any roster hero is not training and can train.

**Returns:** `bool`. Used as a `skip` test.

**Called by:** [[overlay_tutorial#_day_three]].

**Calls:** [[hall_main#roster]], [[guild_upgrades#is_training]], [[guild_upgrades#can_train]].

### _any_affordable
`func _any_affordable() -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:991`

True if any item in `ItemShop.stock` can be bought now.

**Returns:** `bool`. Used for Day 5 `skip` tests and the shop text.

**Called by:** [[overlay_tutorial#_shop_open_text]], [[overlay_tutorial#_day_five]].

**Calls:** [[item_shop#can_buy]].

### _bought_role
`func _bought_role() -> String` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:998`

The role name that can use the item bought on Day 5, or "".

**Returns:** `String`.

**Called by:** [[overlay_tutorial#_fits_bought]], [[overlay_tutorial#_day_five]].

**Calls:** [[hall_style#item_role_name]].

### _bought_name
`func _bought_name() -> String` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1002`

The bought item's display name, or "item".

**Returns:** `String`.

**Called by:** [[overlay_tutorial#_day_five]].

**Calls:** [[hall_style#item_look]].

### _fits_bought
`func _fits_bought(character: Variant) -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1006`

True if `character` is a `GuildCharacter` whose role matches the bought item's role.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `character` | `Variant` | Event payload or roster hero | `d` of the `character` event (`hall_main.gd:811`); roster heroes in `_someone_fits_bought` |

**Returns:** `bool`. Decides whether the `character` event finishes the Day 5 step.

**Called by:** [[overlay_tutorial#_someone_fits_bought]], [[overlay_tutorial#_day_five]].

**Calls:** [[hall_style#role_name]].

### _someone_fits_bought
`func _someone_fits_bought() -> bool` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1010`

True if a living roster hero can use the bought item.

**Returns:** `bool`. Used as `skip` tests in Day 5.

**Called by:** [[overlay_tutorial#_day_five]].

**Calls:** [[hall_main#roster]], [[overlay_tutorial#_fits_bought]], [[hall_style#is_dead]].

### _steps_for
`func _steps_for(script: int) -> Array` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1015`

Returns the step list for a script key: 1, 2, `GUILD_SCRIPT`, 5 or `FREEPLAY_SCRIPT`; otherwise empty.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `script` | `int` | Script key | `_script` set in [[overlay_tutorial#start]] |

**Returns:** `Array` of step dictionaries, stored in `_steps`.

**Called by:** [[overlay_tutorial#start]].

**Calls:** [[overlay_tutorial#_day_one]], [[overlay_tutorial#_day_two]], [[overlay_tutorial#_day_three]], [[overlay_tutorial#_day_five]], [[overlay_tutorial#_freeplay]].

### _day_one
`func _day_one() -> Array` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1030`

Day 1 script: welcome card, open Members and Your Guild, meet [[hall_rules]] `STARTING_HERO_NAME`, open Quests, pick a quest and a party, Back to Quests, End Day (button then sheet), then the Day Report totals, a letter, its story, and "Open the Doors" (`new_day`). The last step is now a `free` step ("Read the report, then tap to start Day 2"): Pip steps back (no dim, no locks, no bubble) so the player can scroll the whole report and open other letters; only the ring on the Day 2 button stays.

**Returns:** `Array` of steps.

**Called by:** [[overlay_tutorial#_steps_for]].

**Calls:** [[overlay_tutorial#_nav]], [[overlay_tutorial#_u]], [[overlay_tutorial#_tab]], [[overlay_tutorial#_screen]], [[overlay_tutorial#_row]], [[overlay_tutorial#_party_ready]], [[overlay_tutorial#_pick_text]], [[overlay_tutorial#_report]], [[overlay_tutorial#_report_letter]], [[overlay_tutorial#_has_foldable_letter]], [[hall_main#end_day_button]].

### _day_two
`func _day_two() -> Array` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1073`

Day 2 script: open a hero's page and its stats, Back, Applicants (a `free` step where the player may hire), then Quests and Deny/death warning.

**Returns:** `Array` of steps.

**Called by:** [[overlay_tutorial#_steps_for]].

**Calls:** [[overlay_tutorial#_nav]], [[overlay_tutorial#_u]], [[overlay_tutorial#_tab]], [[overlay_tutorial#_screen]], [[overlay_tutorial#_row]].

### _day_three
`func _day_three() -> Array` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1100`

The Guild-tab script (key `GUILD_SCRIPT`, runs on `GuildUpgrades.UNLOCK_DAY`; the name is historical): Guild tab, Build section, building an upgrade, Facilities, Training Yard (add a hero, pick a stat) and Hospital (admit). The admit step is skipped when no hero is hurt and waiting, or when `GameState.gold < GuildUpgrades.nightly_fee()` (the guild couldn't pay for the bed; [[guild_upgrades#nightly_fee]]).

**Returns:** `Array` of steps.

**Called by:** [[overlay_tutorial#_steps_for]].

**Calls:** [[overlay_tutorial#_nav]], [[overlay_tutorial#_u]], [[overlay_tutorial#_tab]], [[overlay_tutorial#_row]], [[overlay_tutorial#_is_enabled]], [[overlay_tutorial#_training_section]], [[overlay_tutorial#_hospital_section]], [[overlay_tutorial#_tonight_text]], [[overlay_tutorial#_anyone_can_train]], [[hall_main#affordable_buildings]], [[hall_main#hurt_waiting_count]], [[guild_upgrades#has_free_training_slot]], [[guild_upgrades#nightly_fee]].

### _day_five
`func _day_five() -> Array` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1129`

Day 5 script: open Items, compare items, buy, then (if a living hero can use it) open Members and the right hero and equip; otherwise tell the player to hire the right role.

**Returns:** `Array` of steps.

**Called by:** [[overlay_tutorial#_steps_for]].

**Calls:** [[overlay_tutorial#_nav]], [[overlay_tutorial#_u]], [[overlay_tutorial#_tab]], [[overlay_tutorial#_screen]], [[overlay_tutorial#_shop_open_text]], [[overlay_tutorial#_any_affordable]], [[overlay_tutorial#_someone_fits_bought]], [[overlay_tutorial#_fits_bought]], [[overlay_tutorial#_bought_role]], [[overlay_tutorial#_bought_name]].

### _freeplay
`func _freeplay() -> Array` · `Scripts/UI/Overlays/Day/overlay_tutorial.gd:1161`

The single freeplay card shown after the final battle is won.

**Returns:** `Array` with one text-only step.

**Called by:** [[overlay_tutorial#_steps_for]].

## Suspected issues
- `overlay_tutorial.gd:176`: the comment says "untyped: hall_main preloads this file", but hall_main now reaches it by `class_name` (`OverlayTutorial.new()`, `hall_main.gd:449`).
- `overlay_tutorial.gd:1100`: `_day_three` is the Guild-tab script (key 3 = `GUILD_SCRIPT`, day 10), a leftover name from when it ran on Day 3.
- The header says "Days 1, 2, 5 and ... (10)" and `_freeplay` is documented in the header, but the `game_over` event is emitted by hall_main (`hall_main.gd:1694`) and not handled here (only `run_logger.gd` and `_seen` see it).
