---
source: Scripts/Playtest/agent_bridge_eyes.gd
class_name: AgentBridgeEyes
extends: RefCounted
scene: ""
systems: ["[[Playtest Bridge]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# agent_bridge_eyes.gd

## Purpose
Eyes-mode helpers of the AI playtest bridge: screenshots, taps, swipes and waits. All static; counters are passed in because run state lives on the bridge node. Used only by [[agent_bridge]]. No scene. Excluded from exports.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `TAP_SETTLE_SECONDS` | const | Wait after a tap or swipe before the screenshot (0.6 s). |
| `SWIPE_DEFAULT_SECONDS` | const | Swipe duration when none is given (0.3 s). |
| `MAX_SWIPE_SECONDS` | const | Longest swipe (2 s). |
| `MAX_WAIT_SECONDS` | const | Longest `wait` (10 s). |
| `GAME_SIZE` | const | Game size and screenshot size, 720x1280 px. |
| `WINDOW_MARGIN_PIXELS` | const | Room left for frame and taskbar when fitting the window (80 px). |
| `SHOTS_FOLDER` | const | `shots/` inside the bridge directory. |
| `ALLOWED_COMMANDS` | const | Commands an eyes persona may use: ping, status, screenshot, tap, swipe, wait, quit. |
| `NOT_ALLOWED_ERROR` | const | Refusal text `"not allowed in eyes mode"`. |

## Functions

### fit_window
`static func fit_window(window: Window) -> void` · `Scripts/Playtest/agent_bridge_eyes.gd:36`

Scales content to fit (aspect kept, base size 720x1280) and sizes the window to 9:16 at the screen's usable height minus `WINDOW_MARGIN_PIXELS`, placed at the usable rect's origin.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `window` | `Window` | Root window | `get_window()` in [[agent_bridge#_apply_launch_flags]] |

**Side effects:** changes the window's content scale, size and position.

**Called by:** [[agent_bridge#_apply_launch_flags]] (`agent_bridge.gd:99`), eyes mode only.

### is_allowed
`static func is_allowed(command: String) -> bool` · `Scripts/Playtest/agent_bridge_eyes.gd:48`

**Returns:** true if `command` is in `ALLOWED_COMMANDS`. `debug_rect` is let through by the caller. Used by [[agent_bridge#_dispatch]] (`agent_bridge.gd:182`) to refuse other commands with `NOT_ALLOWED_ERROR`.

### screenshot
`static func screenshot(viewport: Viewport, bridge_dir: String, shot_number: int) -> Dictionary` · `Scripts/Playtest/agent_bridge_eyes.gd:57`

Coroutine. Waits for `frame_post_draw`, grabs the viewport image (resized to `GAME_SIZE` if different), saves `<bridge_dir>/shots/<day>-<n>.png`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `viewport` | `Viewport` | Bridge's viewport | `get_viewport()` in [[agent_bridge#_take_screenshot]] |
| `bridge_dir` | `String` | With trailing slash | `_bridge_dir` |
| `shot_number` | `int` | Running counter | `_shot_count`, incremented first |

**Returns:** `{ok, path, width, height, day}` or `{ok: false, error}` when saving fails. Used by [[agent_bridge#_take_screenshot]] (`agent_bridge.gd:144`).

**Side effects:** creates the folder, writes a PNG.

### tap
`static func tap(viewport: Viewport, tree: SceneTree, tap_args: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_eyes.gd:76`

Coroutine. Pushes a mouse motion, a press, one frame later a release into the viewport, then waits `TAP_SETTLE_SECONDS`.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `viewport` | `Viewport` | Bridge's viewport | `get_viewport()` in [[agent_bridge#_dispatch]] |
| `tree` | `SceneTree` | For frame and timer waits | `get_tree()` |
| `tap_args` | `Dictionary` | `{x, y}` in 720x1280 game space | the `tap` command's `args` |

**Returns:** `{ok: true}`, or `{ok: false, error}` for non-numeric coordinates ("tap needs numeric x and y") or outside the screen. [[agent_bridge#_dispatch]] (`agent_bridge.gd:191`) adds a screenshot when ok, else returns the error.

**Side effects:** synthetic input events.

### swipe
`static func swipe(viewport: Viewport, tree: SceneTree, swipe_args: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_eyes.gd:115`

Coroutine. Press at the start, one interpolated mouse motion per frame (left button held) over the duration, release at the end, then waits `TAP_SETTLE_SECONDS`. Drag-scrolling works from plain mouse events.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `viewport`, `tree` | | as `tap` | [[agent_bridge#_dispatch]] |
| `swipe_args` | `Dictionary` | `{x1, y1, x2, y2, seconds?}` (seconds clamped to 0..`MAX_SWIPE_SECONDS`) | the `swipe` command's `args` |

**Returns:** `{ok: true}` or `{ok: false, error}` (non-numeric or outside the screen). Used by [[agent_bridge#_dispatch]] (`agent_bridge.gd:194`) like `tap`.

### wait
`static func wait(tree: SceneTree, wait_args: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_eyes.gd:161`

Coroutine. Sleeps `seconds` (default 1, clamped to 0..`MAX_WAIT_SECONDS`).

**Returns:** `{ok, waited}`. The return value is ignored by [[agent_bridge#_dispatch]] (`agent_bridge.gd:197`), which answers with a screenshot.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `tree` | `SceneTree` | For the timer | `get_tree()` |
| `wait_args` | `Dictionary` | `{seconds}` | the `wait` command's `args` |

### debug_rect
`static func debug_rect(hall: Node, debug_args: Dictionary) -> Dictionary` · `Scripts/Playtest/agent_bridge_eyes.gd:172`

Test hook (`--test-hooks` only). Finds a Control by unique name (searched anywhere under the hall) or by a NodePath relative to the hall (if the name contains `/`) and reports its global rect so a test can tap its center.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `Node` | The running hall | `_hall` in [[agent_bridge#_dispatch]] |
| `debug_args` | `Dictionary` | `{node}` (a leading `%` is trimmed) | the command's `args` |

**Returns:** `{ok, x, y, w, h, cx, cy, visible}` or `{ok: false, error}`. Returned straight to the client by [[agent_bridge#_dispatch]] (`agent_bridge.gd:203`).

## Suspected issues
- None found.
