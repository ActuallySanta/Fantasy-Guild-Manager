---
source: Scripts/Hall/Debug/run_logger.gd
class_name: RunLogger
extends: Node
scene: null
systems: []
last_verified: 5c8482e595c5dc23b21af42f0b1551f05e444767
tags: [script]
---

# run_logger.gd

## Purpose
`RunLogger`: one row per day (gold, standing, heroes, quest tallies, the day's min/average quest odds, average and top Pluck) for balancing. Each row goes to a local CSV (`user://run_log.csv`) and, when `SHEET_URL` is set, to a Google Sheet through an Apps Script web app (`Scripts/Playtest/run_log_apps_script.gs`). It only wakes on the hall's `tutorial_event` (`end_day` / `game_over`), builds one Dictionary, appends one CSV line, and posts with a threaded `HTTPRequest`, so the game never waits on the network. Rows that fail to send stay queued and go out with the next day.

AI playtests: [[agent_bridge]] calls `configure_ai`, which switches to `user://run_log_ai.csv`, the sheet's "AI Raw" tab, and a one-time redeploy check of the Apps Script (`ai_sheet_status`). It's UI only: [[hall_main#_ready]] adds it as a child node named `RunLogger`; it reads hall state and never changes it.

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `ENABLED` | const | `true`. Off = log nothing anywhere. |
| `SHEET_URL` | const | The Apps Script web app's `/exec` URL. Empty = local CSV only. |
| `TOKEN` | const | `"goobers"`. Must match `TOKEN` in the Apps Script. |
| `CSV_PATH` | const | `"user://run_log.csv"`. |
| `AI_COLUMNS` | const | `["persona", "seed", "run_number", "mode"]`: extra columns on AI rows only, after `COLUMNS`. |
| `AI_CSV_PATH` | const | `"user://run_log_ai.csv"`. |
| `AI_SHEET_NAME` | const | `"AI Raw"`. Documentation only: the Apps Script owns the name. |
| `TIMEOUT` | const | 10.0 seconds before a send gives up. Keep above `LOCK_WAIT_MS` plus the Apps Script's write time (5 s) so the server answers "busy" first, otherwise a resend duplicates rows. |
| `DEBUG` | const | `false`. Print each send and Google's answer. |
| `SEND_TEST_ROW_ON_START` | const | `false`. Post one "test" row when the hall opens (`setup` calls `_log("test", [])` deferred). |
| `MAX_QUEUE` | const | 200 rows held while offline; oldest dropped past this. |
| `COLUMNS` | const | Column order for CSV and sheet: `run_id, logged_at, platform, event, day, gold, standing, standing_change, heroes_alive, heroes_hurt, heroes_dead, quests_sent_today, quests_won_today, gold_earned_today, gold_earned_total, gold_spent_total, quests_sent_total, quests_won_total, heroes_hired_total, items_found_total, avg_pluck, freeplay, tutorial_skipped, avg_hire_total, quest_odds_min_today, quest_odds_avg_today, max_pluck`. New columns go on the END only (the sheet writes by position). |
| `hall` | var (`HallMain`) | The hall being logged; set in `setup`. |
| `_run_id` | var | One id per run (the hall scene reloads on a new run, so this does too). |
| `_last_standing` | var (`int`) | Standing at the last row, for `standing_change`. |
| `_queue` | var (`Array[Dictionary]`) | Rows not yet accepted by the sheet. |
| `_http` | var (`HTTPRequest`) | Posts rows. Null when `SHEET_URL` is empty. |
| `_is_sending` | var (`bool`) | A request is in flight. |
| `_sending_count` | var (`int`) | Rows in the request in flight (dropped from the queue once it lands). |
| `_is_ai` | var (`bool`) | True once `configure_ai` switched to the AI target. |
| `_ai_extras` | var (`Dictionary`) | Extra cells on every AI row, set by `configure_ai`. |
| `ai_sheet_status` | var (`String`) | `"off"` (not AI or not posting), `"checking"`, `"ready"` (redeployed script answered), `"not_redeployed"` (old script answered), `"offline"` (check failed). Only `"ready"` allows posting. Read by [[agent_bridge]] (`agent_bridge.gd:120, 130`). |
| `_check_http` | var (`HTTPRequest`) | The one-time AI sheet check. |

Signals listened to: `hall.tutorial_event` is connected to `_on_event` (`run_logger.gd:89`). `tutorial_event(event: String, data: Variant)` is declared at `hall_main.gd:60` and `run_logger.gd` is its only `.connect` site found in `Globals/`, `Scripts/`, `Scenes/`.

## Functions

### setup
`func setup(main: HallMain) -> void` · `Scripts/Hall/Debug/run_logger.gd:83`

Stores the hall, makes the run id (`YYYYMMDDTHHMMSS-NNNN` from the system time plus a random number), remembers current standing, connects `tutorial_event` to `_on_event`, and, if `SHEET_URL` is set, creates the threaded `HTTPRequest` (no threads on the web) and connects `request_completed` to `_on_sent`. Does nothing if `ENABLED` is false.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `main` | `HallMain` | The hall | `self` in [[hall_main#_ready]] |

**Returns:** nothing.

**Side effects:** adds `_http` as a child; connects signals.

**Called by:** [[hall_main#_ready]] (`hall_main.gd:465`). The other `.setup(` matches in the index are on other objects (views, overlays, the tutorial) and are not callers.

**Calls:** [[run_logger#_log]] (deferred, only with `SEND_TEST_ROW_ON_START`).

### configure_ai
`func configure_ai(new_run_id: String, persona: String, seed_value: int, run_number: int, mode: String, can_post: bool) -> void` · `Scripts/Hall/Debug/run_logger.gd:107`

Switch this logger to the AI playtest target: rows go to `AI_CSV_PATH` with `AI_COLUMNS` appended and are posted with `"sheet":"ai"`. Posting only starts once a GET of `SHEET_URL` answers `ai_tab:true` (the redeployed script); the old script would write AI rows into the human tab, so then nothing is posted. Call before the first row.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `new_run_id` | `String` | Unique per run | `run_id` built in [[agent_bridge#_configure_logger]] |
| `persona` | `String` | AI persona name | `options.persona` |
| `seed_value` | `int` | Random seed | `options.seed` |
| `run_number` | `int` | Run index | `options.run` |
| `mode` | `String` | Run mode | `options.mode` (default `"rules"`) |
| `can_post` | `bool` | False (`--no-sheet`) keeps everything local | `not options.no_sheet` |

**Returns:** nothing.

**Side effects:** sets `_is_ai`, `_run_id`, `_ai_extras`; clears `_queue`; sets `ai_sheet_status` (`"off"` if no posting, else `"checking"`, or `"offline"` if the GET can't start); creates `_check_http` and connects `request_completed` to `_on_sheet_checked`.

**Called by:** [[agent_bridge#_configure_logger]] (`agent_bridge.gd:113`).

**Calls:** [[run_logger#_on_sheet_checked]] (as the signal handler).

### pending_rows
`func pending_rows() -> int` · `Scripts/Hall/Debug/run_logger.gd:128`

Rows logged but not yet accepted by the sheet.

**Returns:** `int`. [[agent_bridge#_log_status]] puts it in the status (`agent_bridge.gd:120`); [[agent_bridge#_flush_logger]] loops while it's above 0 (`agent_bridge.gd:135`).

**Side effects:** none.

**Called by:** [[agent_bridge#_log_status]] (`agent_bridge.gd:120`), [[agent_bridge#_flush_logger]] (`agent_bridge.gd:135`).

**Calls:** nothing.

### run_id
`func run_id() -> String` · `Scripts/Hall/Debug/run_logger.gd:133`

This run's id.

**Returns:** `String`, reported by [[agent_bridge#_log_status]] (`agent_bridge.gd:120`).

**Side effects:** none.

**Called by:** [[agent_bridge#_log_status]] (`agent_bridge.gd:120`).

**Calls:** nothing.

### flush
`func flush() -> void` · `Scripts/Hall/Debug/run_logger.gd:138`

Try to send what is queued (the bridge calls it while quitting).

**Returns:** nothing.

**Side effects:** may start a request.

**Called by:** [[agent_bridge#_flush_logger]] (`agent_bridge.gd:136`).

**Calls:** [[run_logger#_send]].

### _on_sheet_checked
`func _on_sheet_checked(result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void` · `Scripts/Hall/Debug/run_logger.gd:143`

The GET answer for the AI sheet check. Failed request -> `ai_sheet_status = "offline"`. A JSON answer with `ok` and `ai_tab` true -> `"ready"` and `_send()`. Anything else -> `"not_redeployed"` and the queue is cleared.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result`, `_code`, `_headers`, `body` | engine args | From `request_completed` | the engine |

**Returns:** nothing.

**Side effects:** sets `ai_sheet_status`; clears `_queue` or starts a send.

**Called by:** signal `request_completed` on `_check_http` (connected at `run_logger.gd:122`).

**Calls:** [[run_logger#_send]].

### _on_event
`func _on_event(event: String, data: Variant = null) -> void` · `Scripts/Hall/Debug/run_logger.gd:156`

Handler for `HallMain.tutorial_event`. On `"end_day"` it logs a row with kind `day_end`, or `final_won` / `final_lost` when `hall.run_stats.final_result` is `FINAL_RESULT_WON` / `FINAL_RESULT_LOST`, passing `data` (the day's results Array, else empty). On `"game_over"` it logs `game_over`. Other events are ignored.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `event` | `String` | Event name | `tutorial_event.emit(...)` in [[hall_main]] (`"end_day"` at `hall_main.gd:1556`, `"game_over"` at `hall_main.gd:1669`) |
| `data` | `Variant` | For `end_day`, the quest results Array | `results` in [[hall_main#end_day]] |

**Returns:** nothing.

**Side effects:** via `_log`.

**Called by:** signal `tutorial_event` on [[hall_main]] (connected at `run_logger.gd:89`).

**Calls:** [[run_logger#_log]].

### _log
`func _log(kind: String, results: Array) -> void` · `Scripts/Hall/Debug/run_logger.gd:169`

Builds one row (a Dictionary keyed by `COLUMNS`). Counts living, hurt and dead heroes (`HallStyle.is_dead`), total and max Pluck of the living, quests won and gold from `results` (`gold`, `succeeded`), and success odds per result (`chance`, clamped 0-100; blank cells on a day nothing was sent). Takes totals from `hall.run_stats`. Adds `_ai_extras` for AI rows, writes the CSV, and (if `_http` exists and the AI sheet check allows) appends to `_queue`, trims to `MAX_QUEUE`, and calls `_send`.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `kind` | `String` | Row's `event` column | `day_end`, `final_won`, `final_lost`, `game_over` in `_on_event`; `"test"` in `setup` |
| `results` | `Array` | The day's quest result Dictionaries | `data` of `end_day`; `[]` otherwise |

**Returns:** nothing.

**Side effects:** updates `_last_standing`; writes the CSV; queues and may send.

**Called by:** [[run_logger#_on_event]] (`run_logger.gd:164, 166`), [[run_logger#setup]] (`run_logger.gd:98`, deferred).

**Calls:** [[hall_main#roster]], [[hall_style#is_dead]], [[run_logger#_avg_hire_total]], [[run_logger#_write_csv]], [[run_logger#_send]].

### _avg_hire_total
`func _avg_hire_total() -> float` · `Scripts/Hall/Debug/run_logger.gd:251`

The average stat total (`HallStyle.quest_stat_total`, the applicant letter's total) of the new faces in For Hire right now, so playtests show whether recruits keep up with the guild ([[hire_scaling]]). Returning released heroes are left out.

**Returns:** `float` (rounded to 0.01), or 0.0 when there are no new recruits. Used as the `avg_hire_total` cell.

**Side effects:** none.

**Called by:** [[run_logger#_log]] (`run_logger.gd:228`).

**Calls:** [[hall_style#quest_stat_total]].

### _active_columns
`func _active_columns() -> Array` · `Scripts/Hall/Debug/run_logger.gd:263`

`COLUMNS`, plus `AI_COLUMNS` for AI rows.

**Returns:** `Array`, the header used by `_write_csv` and `_send`.

**Side effects:** none.

**Called by:** [[run_logger#_write_csv]] (`run_logger.gd:268`), [[run_logger#_send]] (`run_logger.gd:311`).

**Calls:** nothing.

### _write_csv
`func _write_csv(row: Dictionary) -> void` · `Scripts/Hall/Debug/run_logger.gd:267`

Append `row` to `CSV_PATH` (or `AI_CSV_PATH` for AI rows), first moving an outdated file aside, and writing the header line when the file is new. Silently returns if the file can't be opened.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `row` | `Dictionary` | One row keyed by column name | built in `_log` |

**Returns:** nothing.

**Side effects:** writes a file in `user://`.

**Called by:** [[run_logger#_log]] (`run_logger.gd:237`).

**Calls:** [[run_logger#_active_columns]], [[run_logger#_retire_old_csv]].

### _retire_old_csv
`func _retire_old_csv(path: String, columns: Array) -> void` · `Scripts/Hall/Debug/run_logger.gd:289`

If the CSV at `path` has a different header than `columns` (it was started before the columns changed), move it to `<name>_old.csv` (replacing an older one) so `_write_csv` starts fresh.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `path` | `String` | CSV to check | `CSV_PATH` / `AI_CSV_PATH` in `_write_csv` |
| `columns` | `Array` | The header it should have | `_active_columns()` |

**Returns:** nothing.

**Side effects:** removes and renames files.

**Called by:** [[run_logger#_write_csv]] (`run_logger.gd:270`).

**Calls:** nothing.

### _send
`func _send() -> void` · `Scripts/Hall/Debug/run_logger.gd:305`

Post every queued row in one request, one request at a time (returns if one is in flight or the queue is empty). AI rows don't post until `ai_sheet_status == "ready"`. The body is JSON `{token, columns, rows[, sheet: "ai"]}`, sent as `text/plain` so a web build skips the CORS preflight.

**Returns:** nothing.

**Side effects:** starts a POST; sets `_is_sending` and `_sending_count`; warns if the request can't start.

**Called by:** [[run_logger#flush]] (`run_logger.gd:139`), [[run_logger#_on_sheet_checked]] (`run_logger.gd:150`), [[run_logger#_log]] (`run_logger.gd:244`), [[run_logger#_on_sent]] (`run_logger.gd:344`).

**Calls:** [[run_logger#_active_columns]].

### _on_sent
`func _on_sent(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void` · `Scripts/Hall/Debug/run_logger.gd:333`

The POST finished. Success needs request success and a JSON `{"ok": true}` body (a Google sign-in or error page also comes back 200). On success the sent rows are dropped from `_queue` and `_send` runs again; otherwise a warning with the first 300 characters of the reply is pushed and the rows stay queued.

**Parameters**
| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `result`, `code`, `_headers`, `body` | engine args | From `request_completed` | the engine |

**Returns:** nothing.

**Side effects:** clears `_is_sending`; trims `_queue`.

**Called by:** signal `request_completed` on `_http` (connected at `run_logger.gd:95`).

**Calls:** [[run_logger#_send]].

## Suspected issues
- `SHEET_URL` and `TOKEN` (`run_logger.gd:25-28`) are hard-coded in the script, and `TOKEN` is shipped in exports; it only guards against stray posts, not as a secret.
- `_write_csv` (`run_logger.gd:267`) and `_on_event` / `_log` / `_on_sent` have no `##` doc comments, against the project convention.
- `_log` on a failed send in `_on_sent`: `_sending_count` is not reset on failure, but it's overwritten by the next `_send`, so harmless.
