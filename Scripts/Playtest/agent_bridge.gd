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

@onready var _hall: HallMain = $HallMain


func _enter_tree() -> void:
	_parse_args()
	# Before the hall's _ready (and the autoloads' deferred first restock) roll
	# anything, so the first hire pool, shop stock and Board come from the seed.
	if options.has("seed"):
		seed(int(options.seed))


func _ready() -> void:
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


## Reads cmd.json if it holds a command not yet answered, and answers it.
func _poll_command() -> void:
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
	var response: Dictionary = await _dispatch(str(parsed.get("command", "")), parsed.get("args", {}))
	response["id"] = id
	_write_json(RESPONSE_FILE, response)
	if response.get("quit", false):
		get_tree().quit()


## Runs one command (a coroutine: end_day waits for the night). Returns the response dictionary (without "id").
func _dispatch(command: String, args: Variant) -> Dictionary:
	var arg_dict: Dictionary = args if args is Dictionary else {}
	# once the run has ended every action is refused
	if command in ACTION_COMMANDS and AgentBridgeActions.is_run_over(_hall):
		return {"ok": false, "error": "run over"}
	match command:
		"plan":
			return AgentBridgeActions.plan(_hall, arg_dict)
		"end_day":
			return await AgentBridgeActions.end_day(_hall, get_tree())
		"debug", "kill_all":
			# test hooks: personas never get them (no --test-hooks flag)
			if not options.get("test_hooks", false):
				return {"ok": false, "error": "unknown command %s" % command}
			if command == "kill_all":
				return AgentBridgeActions.kill_all(_hall)
			return AgentBridgeActions.debug(_hall, arg_dict)
		"ping":
			return {"ok": true, "mode": options.get("mode", "rules"), "day": GameState.day}
		"state":
			var state := AgentBridgeState.build(_hall)
			state["ok"] = true
			return state
		"quit":
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
