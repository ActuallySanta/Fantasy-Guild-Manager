## Debug-only bridge that lets an AI playtester drive the real game.
## Scene: Scenes/Playtest/agent_bridge.tscn (a HallMain child, like the
## scenario_*.tscn playtest scenes).
##
## Transport is files in a bridge directory (--bridge-dir): the bridge polls
## cmd.json, answers in resp.json (written atomically) and writes ready.json
## once the hall is up. See tools/playtest/bridge.sh for the client side.
##
## The hall is instanced under this node (not the root), so it never saves.
## Run state lives on this node, never in a static var or an autoload.
## This script is excluded from exports (export_presets.cfg exclude_filter).
extends Control

## How often cmd.json is checked, in seconds.
const POLL_INTERVAL_SECONDS := 0.05
## File names inside the bridge directory.
const COMMAND_FILE := "cmd.json"
const RESPONSE_FILE := "resp.json"
const RESPONSE_TEMP_FILE := "resp.tmp"
const READY_FILE := "ready.json"

## Longest `quit` waits for the run log to finish posting, in seconds.
const QUIT_FLUSH_SECONDS := 15

## Commands that change the game; refused once the run is over.
const ACTION_COMMANDS: Array[String] = ["plan", "end_day"]

## Parsed user args (see _parse_args): bridge_dir, mode, seed, persona, run, label...
var options: Dictionary = {}
## Bridge directory with forward slashes and a trailing slash.
var _bridge_dir := ""
## Seconds since the last poll.
var _poll_timer := 0.0
## Id of the last command answered, so one cmd.json is handled once.
var _last_handled_id := 0
## True while a command is being answered (end_day waits for the night over
## several frames). New commands wait in cmd.json until it clears, so they are
## never run against a half-played night and responses stay in order.
var _busy := false
## Screenshots taken so far this run (names the files in shots/).
var _shot_count := 0
## The hall's RunLogger, switched to the AI target in _ready (null if absent).
var _logger: RunLogger

@onready var _hall: HallMain = $HallMain


func _enter_tree() -> void:
	_parse_args()
	# Before the hall's _ready (and the autoloads' deferred first restock) roll
	# anything, so the first hire pool, shop stock and Board come from the seed.
	if options.has("seed"):
		seed(int(options.seed))
	# --intro: the hall decides in its _ready whether the crawl shows, so set it now
	if options.get("intro", false):
		$HallMain.shows_intro_without_save = true


func _ready() -> void:
	_apply_launch_flags()
	_configure_logger()
	_write_json(READY_FILE, {"ok": true, "mode": options.get("mode", "rules")})


func _process(delta: float) -> void:
	_poll_timer += delta
	if _poll_timer < POLL_INTERVAL_SECONDS:
		return
	_poll_timer = 0.0
	_poll_command()


## Fills `options` from OS.get_cmdline_user_args(): "--key=value" or a bare
## "--flag" (stored as true). Dashes in keys become underscores.
func _parse_args() -> void:
	options = {"mode": "rules"}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		if eq == -1:
			options[body.replace("-", "_")] = true
		else:
			options[body.substr(0, eq).replace("-", "_")] = body.substr(eq + 1)
	_bridge_dir = str(options.get("bridge_dir", "")).replace("\\", "/")
	if not _bridge_dir.ends_with("/"):
		_bridge_dir += "/"


## Applies --text-size=N, --color-filter=N and --reduce-motion (both modes), and
## always reduce motion in rules mode. The hall's own _ready has already run.
## Every setting is applied (to its default when no flag is given), because the
## hall saves them to user://settings and a later launch would inherit them.
func _apply_launch_flags() -> void:
	if options.get("mode", "rules") == "eyes":
		AgentBridgeEyes.fit_window(get_window())
	_hall.set_text_size(int(options.get("text_size", HallSettings.DEFAULT_TEXT_SIZE)))
	_hall.set_color_filter(int(options.get("color_filter", 0)))
	_hall.set_reduce_motion(options.get("reduce_motion", false) or options.get("mode", "rules") == "rules")


## Points the hall's RunLogger at the AI target (own CSV, "AI Raw" tab).
## --no-sheet keeps it local. The run id is unique per launch even with a
## shared seed: ai-<label>-<persona>-<run>-<unix time>.
func _configure_logger() -> void:
	_logger = _hall.get_node_or_null("RunLogger") as RunLogger
	if _logger == null:
		return
	var run_id := "ai-%s-%s-%s-%d" % [options.get("label", "none"), options.get("persona", "none"), options.get("run", "0"), int(Time.get_unix_time_from_system())]
	_logger.configure_ai(run_id, str(options.get("persona", "")), int(options.get("seed", 0)), int(options.get("run", 0)), str(options.get("mode", "rules")), not options.get("no_sheet", false))


## The run log's part of the status answer.
func _log_status() -> Dictionary:
	if _logger == null:
		return {"run_id": "", "sheet": "off", "pending_rows": 0}
	return {"run_id": _logger.run_id(), "sheet": _logger.ai_sheet_status, "pending_rows": _logger.pending_rows()}


## Waits (up to QUIT_FLUSH_SECONDS in all) for the sheet check to finish, then
## for queued run-log rows to post, retrying the send. Only when the sheet
## check passed; otherwise nothing could post.
func _flush_logger() -> void:
	if _logger == null:
		return
	var waited := 0.0
	while _logger.ai_sheet_status == "checking" and waited < QUIT_FLUSH_SECONDS:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	if _logger.ai_sheet_status != "ready":
		return
	while _logger.pending_rows() > 0 and waited < QUIT_FLUSH_SECONDS:
		_logger.flush()
		await get_tree().create_timer(0.25).timeout
		waited += 0.25


## Takes a screenshot of the viewport. Returns {ok, path, width, height, day}.
func _take_screenshot() -> Dictionary:
	_shot_count += 1
	return await AgentBridgeEyes.screenshot(get_viewport(), _bridge_dir, _shot_count)


## Reads cmd.json if it holds a command not yet answered, and answers it.
func _poll_command() -> void:
	if _busy:
		return
	var path := _bridge_dir + COMMAND_FILE
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return  # half-written or garbage; try again next poll
	var id := int(parsed.get("id", 0))
	if id <= _last_handled_id:
		return
	_last_handled_id = id
	_busy = true
	var command := str(parsed.get("command", ""))
	# untyped: a runtime error inside _dispatch aborts it and yields null (or an empty dictionary)
	var result: Variant = await _dispatch(command, parsed.get("args", {}))
	# cleared first thing, so nothing below can leave the bridge wedged
	_busy = false
	var response: Dictionary = result if result is Dictionary and not result.is_empty() else {"ok": false, "error": "internal error in %s" % command}
	response["id"] = id
	_write_json(RESPONSE_FILE, response)
	if response.get("quit", false):
		get_tree().quit()


## Runs one command (a coroutine: end_day waits for the night). Returns the response dictionary (without "id").
func _dispatch(command: String, args: Variant) -> Dictionary:
	var arg_dict: Dictionary = args if args is Dictionary else {}
	# first, so eyes mode never learns the run is over from a refused action
	if options.get("mode", "rules") == "eyes":
		var is_hook: bool = command == "debug_rect" and options.get("test_hooks", false)
		if not AgentBridgeEyes.is_allowed(command) and not is_hook:
			return {"ok": false, "error": AgentBridgeEyes.NOT_ALLOWED_ERROR}
	# once the run has ended every action is refused
	if command in ACTION_COMMANDS and AgentBridgeActions.is_run_over(_hall):
		return {"ok": false, "error": "run over"}
	match command:
		"screenshot":
			return await _take_screenshot()
		"tap":
			var tapped := await AgentBridgeEyes.tap(get_viewport(), get_tree(), arg_dict)
			return await _take_screenshot() if tapped.ok else tapped
		"swipe":
			var swiped := await AgentBridgeEyes.swipe(get_viewport(), get_tree(), arg_dict)
			return await _take_screenshot() if swiped.ok else swiped
		"wait":
			await AgentBridgeEyes.wait(get_tree(), arg_dict)
			return await _take_screenshot()
		"debug_rect":
			# test hook: personas never get it (eyes mode refuses it without --test-hooks)
			if not options.get("test_hooks", false):
				return {"ok": false, "error": "unknown command %s" % command}
			return AgentBridgeEyes.debug_rect(_hall, arg_dict)
		"plan":
			return AgentBridgeActions.plan(_hall, arg_dict)
		"end_day":
			return await AgentBridgeActions.end_day(_hall, get_tree())
		"crash":
			# test hook: a deliberate runtime error, to prove the bridge survives one
			if not options.get("test_hooks", false):
				return {"ok": false, "error": "unknown command %s" % command}
			var nothing: Object = null
			nothing.call("no_such_method")
			return {"ok": true}
		"debug", "kill_all":
			# test hooks: personas never get them (no --test-hooks flag)
			if not options.get("test_hooks", false):
				return {"ok": false, "error": "unknown command %s" % command}
			if command == "kill_all":
				return AgentBridgeActions.kill_all(_hall)
			return AgentBridgeActions.debug(_hall, arg_dict)
		"status":
			var status := _log_status()
			status["ok"] = true
			status["day"] = GameState.day
			status["user_dir"] = OS.get_user_data_dir()
			return status
		"ping":
			return {"ok": true, "mode": options.get("mode", "rules"), "day": GameState.day, "intro_open": _hall.is_intro_open(), "text_size": _hall.text_size}
		"state":
			var state := AgentBridgeState.build(_hall)
			state["ok"] = true
			return state
		"quit":
			await _flush_logger()
			return {"ok": true, "quit": true}
		_:
			return {"ok": false, "error": "unknown command %s" % command}


## Writes a JSON file in the bridge directory atomically (temp file, then rename).
func _write_json(file_name: String, data: Dictionary) -> void:
	var temp_path := _bridge_dir + RESPONSE_TEMP_FILE
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("agent_bridge: cannot write %s" % temp_path)
		return
	file.store_string(JSON.stringify(data))
	file.close()
	DirAccess.rename_absolute(temp_path, _bridge_dir + file_name)
