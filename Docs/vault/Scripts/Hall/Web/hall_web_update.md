---
source: Scripts/Hall/Web/hall_web_update.gd
class_name: HallWebUpdate
extends: RefCounted
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# hall_web_update.gd

## Purpose
`HallWebUpdate`: gets new web deploys onto phones without clearing caches. The web export is a PWA whose service worker serves `index.pck` / `index.wasm` cache-first; a new deploy installs a new worker that waits until every tab is closed. `JavaScriptBridge` can see when a worker is waiting (`pwa_needs_update`) and switch to it (`pwa_update`, which reloads the page).

[[hall_main#_ready]] calls `apply_waiting_update()` first (an already-waiting update is applied before anything else; the run is saved and [[hall_save]] loads it after the reload) and `watch(hall)` after setup. Menu > Debug tools > Check for update calls `check_latest`; the confirm popup's Update button calls `update_now`. Everything does nothing off the web.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `CheckResult` | enum | Result of `check_latest`: `UP_TO_DATE` (site stamp equals this build's), `UPDATE_AVAILABLE` (site has a different build), `NOT_WEB`, `FAILED` (stamp couldn't be fetched). |
| `APPLY_WINDOW_SECONDS` | const | 10.0 s. An update found this soon after `watch` is applied at once. |
| `UPDATE_TIMEOUT_SECONDS` | const | 15.0 s. How long `update_now` waits for the service worker before a plain page reload. |
| `CHECK_TIMEOUT_SECONDS` | const | 10.0 s. How long `check_latest` waits for the stamp before FAILED. |
| `TOAST_UPDATING` / `TOAST_UPDATE_READY` / `TOAST_DOWNLOADING` | const | Toast texts: "Updating to the newest version…", "Update ready · it loads next time you open the game", "Downloading the update…". |
| `_is_update_requested` | static var (`bool`) | True once the player tapped Update (`update_now`): the next new worker is applied straight away. Page state, cleared by the reload. |

Signals listened to: `JavaScriptBridge.pwa_update_available` is connected once (one-shot) in `watch` (`hall_web_update.gd:75`).

## Functions

### apply_waiting_update
`static func apply_waiting_update() -> bool` · `Scripts/Hall/Web/hall_web_update.gd:57`

If a newer deploy is already waiting, switch to it now (the page reloads).

**Returns:** `bool`, true when an update was started. [[hall_main#_ready]] stops setting up when it's true (`hall_main.gd:419`). False off the web or if none waits.

**Side effects:** `JavaScriptBridge.pwa_update()` (page reload).

**Called by:** [[hall_main#_ready]] (`hall_main.gd:419`).

**Calls:** nothing in the project.

### watch
`static func watch(hall: HallMain) -> void` · `Scripts/Hall/Web/hall_web_update.gd:67`

Listen for a newer deploy turning up while the game is open: connects `pwa_update_available` one-shot to `_on_update_available(hall, started_msec)`, and calls it at once if a worker already finished installing during load.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The hall, for toasts and the save before an early reload | `self` in [[hall_main#_ready]] |

**Returns:** nothing.

**Side effects:** connects a signal on the `JavaScriptBridge` singleton (it can outlive this hall; `_on_update_available` ignores a hall that's gone). Does nothing off the web.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:478`).

**Calls:** [[hall_web_update#_on_update_available]].

### check_latest
`static func check_latest(host: Node, on_done: Callable) -> void` · `Scripts/Hall/Web/hall_web_update.gd:86`

Ask the live site which build it serves and compare with this one. Adds a temporary `HTTPRequest` under `host`, sends a no-cache GET of `_latest_stamp_url()`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `host` | `Node` | A node in the tree | `self` ([[overlay_debug]]) |
| `on_done` | `Callable` | Called once as `on_done(result: CheckResult, latest_stamp: String)` | `_on_update_checked` in [[overlay_debug#_on_update_pressed]] |

**Returns:** nothing. `latest_stamp` is `""` unless the fetch worked. Off the web it calls `on_done(NOT_WEB, "")` immediately; if the request can't start it calls `FAILED`.

**Side effects:** adds and frees an `HTTPRequest`; connects `request_completed` (one-shot) to `_on_check_completed`.

**Called by:** [[overlay_debug#_on_update_pressed]] (`overlay_debug.gd:172`).

**Calls:** [[hall_web_update#_latest_stamp_url]], [[hall_web_update#_on_check_completed]].

### _on_check_completed
`static func _on_check_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest, on_done: Callable) -> void` · `Scripts/Hall/Web/hall_web_update.gd:104`

`request_completed` handler of the HTTPRequest made in `check_latest`: frees it, parses the body with `HallBuildInfo.parse_stamp`, and calls `on_done` with `FAILED` (bad result, non-200 code or empty stamp), `UP_TO_DATE` (equals `HallBuildInfo.stamp()`) or `UPDATE_AVAILABLE`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result`, `code`, `_headers`, `body` | engine args | From `request_completed` | the engine |
| `request` | `HTTPRequest` | The temporary node (freed here) | bound in `check_latest` |
| `on_done` | `Callable` | `check_latest`'s callback | bound in `check_latest` |

**Returns:** nothing.

**Side effects:** `request.queue_free()`; calls `on_done`.

**Called by:** signal `request_completed` on the temporary `HTTPRequest` (connected at `hall_web_update.gd:93`). Not called directly.

**Calls:** [[hall_build_info#parse_stamp]], [[hall_build_info#stamp]].

### update_now
`static func update_now(hall: HallMain) -> void` · `Scripts/Hall/Web/hall_web_update.gd:119`

The confirm popup's Update button: save the run, then switch to the newest deploy. If a worker is already waiting: toast and `pwa_update()`. Otherwise sets `_is_update_requested`, toasts "Downloading…", asks the service worker to `update()`, and starts a `UPDATE_TIMEOUT_SECONDS` timer that does `location.reload()` if nothing took over.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | For the save and toasts | `hall` in [[overlay_update_confirm]] |

**Returns:** nothing.

**Side effects:** [[hall_main#save_now]] (does nothing while saving is off or in a debug run), toasts, JS calls, page reload. Does nothing off the web.

**Called by:** [[overlay_update_confirm#_on_update_pressed]] (`overlay_update_confirm.gd:85`).

**Calls:** [[hall_main#save_now]], `hall.show_toast`.

### _on_update_available
`static func _on_update_available(hall: HallMain, started_msec: int) -> void` · `Scripts/Hall/Web/hall_web_update.gd:147`

A newer deploy is waiting. If `_is_update_requested`: `pwa_update()`. Else, if the hall is gone, ignore. If the game opened within `APPLY_WINDOW_SECONDS` seconds: toast, `save_now()`, `pwa_update()`. Otherwise toast `TOAST_UPDATE_READY` (loads next launch).

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `hall` | `HallMain` | The watching hall (may be freed after `start_new_run`) | `hall` bound in `watch` |
| `started_msec` | `int` | `Time.get_ticks_msec()` when `watch` ran | `watch` |

**Returns:** nothing.

**Side effects:** toasts, [[hall_main#save_now]], page reload.

**Called by:** [[hall_web_update#watch]] (`hall_web_update.gd:75` via the `pwa_update_available` signal, and `hall_web_update.gd:79` directly).

**Calls:** [[hall_main#save_now]].

### _latest_stamp_url
`static func _latest_stamp_url() -> String` · `Scripts/Hall/Web/hall_web_update.gd:165`

The site's build stamp next to this page (`HallBuildInfo.LATEST_WEB_FILE`) with a throwaway `?t=<ms>` query so no cache answers, built in JS from `window.location.href`.

**Returns:** `String` URL, passed to `HTTPRequest.request` in `check_latest`.

**Side effects:** runs JS.

**Called by:** [[hall_web_update#check_latest]] (`hall_web_update.gd:96`).

**Calls:** nothing in the project (reads `HallBuildInfo.LATEST_WEB_FILE`).

## Suspected issues
- None found.
