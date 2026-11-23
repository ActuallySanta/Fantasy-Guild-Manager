---
source: Scripts/Playtest/agent_bridge.gd
extends: Control
scene: "[[agent_bridge (scene)]]"
systems: ["[[Playtest Bridge]]"]
last_verified: 624dc5db52f5a4818a2f9bd32b1900ff30c299b2
tags: [script]
---

# agent_bridge.gd

## Purpose
Debug-only bridge that lets an AI playtester drive the real game. Transport is files in a bridge directory (`--bridge-dir`): it polls `cmd.json`, answers in `resp.json` (written atomically) and writes `ready.json` once the hall is up. Client side: `tools/playtest/bridge.sh`. The hall is a child of this node, so it never saves. Scene: [[agent_bridge (scene)]]. Excluded from exports. Helpers: [[agent_bridge_actions]], [[agent_bridge_eyes]], [[agent_bridge_state]].

## State
| Name | Kind | Meaning (units) |
|---|---|---|
| `POLL_INTERVAL_SECONDS` | const | How often cmd.json is checked (0.05 s). |
| `COMMAND_FILE`, `RESPONSE_FILE`, `RESPONSE_TEMP_FILE`, `READY_FILE` | const | File names in the bridge directory. |
| `QUIT_FLUSH_SECONDS` | const | Longest `quit` waits for the run log to post (15 s). |
| `FLUSH_STEP_SECONDS` | const | Recheck interval while flushing (0.25 s). |
| `ACTION_COMMANDS` | const | `plan`, `end_day`: refused once the run is over. |
| `options` | var | Parsed user args (bridge_dir, mode, seed, persona, run, label, ...). |
| `_bridge_dir` | var | Bridge directory, forward slashes, trailing slash. |
| `_poll_timer` | var | Seconds since the last poll. |
| `_last_handled_id` | var | Id of the last answered command. |
| `_busy` | var | True while a command is answered; new commands wait in cmd.json. |
| `_shot_count` | var | Screenshots taken this run. |
| `_logger` | var | The hall's `RunLogger` (null if absent). |
| `_hall` | onready var | `$HallMain`. |

## Functions

### _enter_tree
`func _enter_tree() -> void` · `Scripts/Playtest/agent_bridge.gd:50`

Called by the engine. Parses args, seeds the RNG if `--seed` is given (before the hall rolls anything), and with `--intro` sets `HallMain.shows_intro_without_save`.

**Side effects:** `seed()`, sets a flag on the hall.

**Calls:** [[agent_bridge#_parse_args]].

### _ready
`func _ready() -> void` · `Scripts/Playtest/agent_bridge.gd:61`

Called by the engine. Applies launch flags, configures the logger and writes `ready.json` `{ok, mode}`.

**Calls:** [[agent_bridge#_apply_launch_flags]], [[agent_bridge#_configure_logger]], [[agent_bridge#_write_json]].

### _process
`func _process(delta: float) -> void` · `Scripts/Playtest/agent_bridge.gd:67`

Called by the engine each frame (`delta`: frame time in seconds); every `POLL_INTERVAL_SECONDS` calls [[agent_bridge#_poll_command]].

### _parse_args
`func _parse_args() -> void` · `Scripts/Playtest/agent_bridge.gd:77`

Fills `options` from `OS.get_cmdline_user_args()`: `--key=value` or a bare `--flag` (true); dashes in keys become underscores. Default `mode` is `"rules"`. Also sets `_bridge_dir`.

**Called by:** [[agent_bridge#_enter_tree]] (`agent_bridge.gd:51`).

### _apply_launch_flags
`func _apply_launch_flags() -> void` · `Scripts/Playtest/agent_bridge.gd:97`

Eyes mode fits the window. Always applies `--text-size`, `--color-filter` and reduce motion (always on in rules mode) so a saved setting never leaks into a later launch.

**Called by:** [[agent_bridge#_ready]] (`agent_bridge.gd:62`).

**Calls:** [[agent_bridge_eyes#fit_window]], [[hall_main#set_text_size]], [[hall_main#set_color_filter]], [[hall_main#set_reduce_motion]].

### _configure_logger
`func _configure_logger() -> void` · `Scripts/Playtest/agent_bridge.gd:108`

Finds the hall's `RunLogger` and points it at the AI target. Run id: `ai-<label>-<persona>-<run>-<unix time>`; `--no-sheet` keeps it local.

**Called by:** [[agent_bridge#_ready]] (`agent_bridge.gd:63`).

**Calls:** [[run_logger#configure_ai]].

### _log_status
`func _log_status() -> Dictionary` · `Scripts/Playtest/agent_bridge.gd:117`

**Returns:** `{run_id, sheet, pending_rows}` (`""`, `"off"`, 0 with no logger). Used by the `status` command in [[agent_bridge#_dispatch]] (`agent_bridge.gd:223`).

**Calls:** [[run_logger#run_id]], [[run_logger#pending_rows]].

### _flush_logger
`func _flush_logger() -> void` · `Scripts/Playtest/agent_bridge.gd:126`

Coroutine. Waits (max `QUIT_FLUSH_SECONDS` total) for the sheet check, then for pending rows to post, calling `flush` each step. Returns early unless sheet status is `"ready"`.

**Called by:** [[agent_bridge#_dispatch]] (`agent_bridge.gd:235`, `quit`).

**Calls:** [[run_logger#pending_rows]], [[run_logger#flush]].

### _take_screenshot
`func _take_screenshot() -> Dictionary` · `Scripts/Playtest/agent_bridge.gd:142`

Coroutine. Increments `_shot_count` and screenshots the viewport.

**Returns:** `{ok, path, width, height, day}`. Used by [[agent_bridge#_dispatch]] (`agent_bridge.gd:189`, `192`, `195`, `198`) as the answer to screenshot, tap, swipe and wait.

**Calls:** [[agent_bridge_eyes#screenshot]].

### _poll_command
`func _poll_command() -> void` · `Scripts/Playtest/agent_bridge.gd:148`

Reads `cmd.json` if not busy; ignores garbage or ids not newer than `_last_handled_id`. Dispatches the command, then writes `resp.json` with `id` and `resp_id`. An empty or non-dictionary result becomes `{ok: false, error: "internal error in <command>"}`. If the response has `quit`, quits the tree.

**Side effects:** sets/clears `_busy`, writes resp.json, may quit.

**Called by:** [[agent_bridge#_process]] (`agent_bridge.gd:72`).

**Calls:** [[agent_bridge#_dispatch]], [[agent_bridge#_write_json]].

### _dispatch
`func _dispatch(command: String, args: Variant) -> Dictionary` · `Scripts/Playtest/agent_bridge.gd:177`

Coroutine; runs one command and returns the response (without `id`).

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `command` | `String` | Command name | `cmd.json` "command" in [[agent_bridge#_poll_command]] |
| `args` | `Variant` | Arguments (non-dictionary treated as {}) | `cmd.json` "args" |

**Returns:** the response `Dictionary`. Error cases: `NOT_ALLOWED_ERROR` in eyes mode for non-allowed commands, `"run over"` for `ACTION_COMMANDS` after the run ended, `"unknown command X"` (also for test hooks without `--test-hooks`).

**Called by:** [[agent_bridge#_poll_command]] (`agent_bridge.gd:164`).

**Calls:** [[agent_bridge_eyes#is_allowed]], [[agent_bridge_actions#is_run_over]], [[agent_bridge#_take_screenshot]], [[agent_bridge_eyes#tap]], [[agent_bridge_eyes#swipe]], [[agent_bridge_eyes#wait]], [[agent_bridge_eyes#debug_rect]], [[agent_bridge_actions#plan]], [[agent_bridge_actions#end_day]], [[agent_bridge_actions#kill_all]], [[agent_bridge_actions#debug]], [[agent_bridge#_log_status]], [[hall_main#is_intro_open]], [[agent_bridge_state#build]], [[agent_bridge#_flush_logger]].

> [!note] Commands
> Both modes: `ping`, `status`, `quit`. Eyes: `screenshot`, `tap`, `swipe`, `wait` (tap, swipe and wait answer with a screenshot). Rules: `plan`, `end_day`, `state`. Test hooks (need `--test-hooks`): `debug_rect`, `crash` (a deliberate error), `debug`, `kill_all`. In eyes mode only the `ALLOWED_COMMANDS` of [[agent_bridge_eyes]] pass, plus `debug_rect` with test hooks.

### _write_json
`func _write_json(file_name: String, data: Dictionary) -> void` · `Scripts/Playtest/agent_bridge.gd:242`

Writes `data` as JSON to `resp.tmp` then renames it to `file_name` in the bridge directory. Pushes an error if the temp file can't be opened.

| Name | Type | Meaning | Where callers get it |
|---|---|---|---|
| `file_name` | `String` | Target file | `READY_FILE` in `_ready`, `RESPONSE_FILE` in `_poll_command` |
| `data` | `Dictionary` | Payload | built by the callers |

**Called by:** [[agent_bridge#_ready]] (`agent_bridge.gd:64`), [[agent_bridge#_poll_command]] (`agent_bridge.gd:171`).

## Suspected issues
- `agent_bridge.gd:243`: the temp file is always `resp.tmp`, even for `ready.json`. Harmless while writes are sequential.
