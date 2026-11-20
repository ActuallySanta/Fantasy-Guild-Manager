## Run logger: one row per day (gold, standing, heroes, quest tallies, the
## day's min/average quest odds, average and top Pluck) for
## balancing. Every row goes to a local CSV (user://run_log.csv) and, when
## SHEET_URL is set, to a Google Sheet through a small Apps Script web app
## (Scripts/Playtest/run_log_apps_script.gs has the script and setup).
##
## Cheap on purpose: it only wakes up on the hall's own tutorial_event
## (end_day / game_over), builds one small Dictionary, appends one CSV line,
## and posts with a threaded HTTPRequest, so the game never waits on the
## network. Rows that fail to send stay queued and go out with the next day.
##
## UI only, like the tutorial: hall_main._ready adds it; it reads hall state
## and never changes it.
class_name RunLogger
extends Node


## Off = log nothing anywhere.
const ENABLED := true
## The Apps Script web app's /exec URL. Empty = local CSV only.
const SHEET_URL := "https://script.google.com/macros/s/AKfycbynU-kngD_D_4h6dDVLoPhW6fNQXSDIcyCq6NvmLoucnCRABca3zTIcO25dgZBK4To_/exec"
## Must match TOKEN in the Apps Script (stops random posts to the sheet).
const TOKEN := "goobers"
const CSV_PATH := "user://run_log.csv"
## Extra columns on AI playtest rows only, appended after COLUMNS (see
## configure_ai). Human rows never have them.
const AI_COLUMNS := ["persona", "seed", "run_number", "mode"]
## Where AI playtest rows go locally, so they never mix into run_log.csv.
const AI_CSV_PATH := "user://run_log_ai.csv"
## The tab AI rows land in. Documentation only: the Apps Script owns the name.
const AI_SHEET_NAME := "AI Raw"
## Seconds before a send gives up (it retries with the next row).
const TIMEOUT := 10.0
## Print each send and Google's answer to the Output panel.
const DEBUG := false
## Post one "test" row when the hall opens, to check the sheet without
## playing a day. Turn off once rows show up.
const SEND_TEST_ROW_ON_START := false
## Most rows held while offline; the oldest are dropped past this.
const MAX_QUEUE := 200

## Column order for the CSV and the sheet. New columns go on the END only:
## the sheet writes values by position under its existing header row.
const COLUMNS := [
	"run_id", "logged_at", "platform", "event", "day",
	"gold", "standing", "standing_change",
	"heroes_alive", "heroes_hurt", "heroes_dead",
	"quests_sent_today", "quests_won_today", "gold_earned_today",
	"gold_earned_total", "gold_spent_total", "quests_sent_total", "quests_won_total",
	"heroes_hired_total", "items_found_total", "avg_pluck",
	"freeplay", "tutorial_skipped",
	# added later: kept at the end so older sheet columns don't shift
	"avg_hire_total",
	"quest_odds_min_today", "quest_odds_avg_today", "max_pluck",
]

var hall: HallMain
## One id per run (the hall scene reloads on a new run, so this does too).
var _run_id := ""
var _last_standing := 0
var _queue: Array[Dictionary] = []
var _http: HTTPRequest
var _is_sending := false
## Rows in the request in flight (dropped from the queue once it lands).
var _sending_count := 0
## True once configure_ai switched this logger to the AI target.
var _is_ai := false
## Extra cells on every AI row (persona, seed, run_number, mode), set by configure_ai.
var _ai_extras := {}
## Where the AI sheet check stands: "off" (not AI, or not posting), "checking",
## "ready" (the redeployed script answered), "not_redeployed" (the old script
## answered), or "offline" (the check failed). Only "ready" allows posting.
var ai_sheet_status := "off"
var _check_http: HTTPRequest


func setup(main: HallMain) -> void:
	hall = main
	if not ENABLED:
		return
	_run_id = "%s-%04d" % [Time.get_datetime_string_from_system(true).replace(":", "").replace("-", ""), randi() % 10000]
	_last_standing = GuildUpgrades.standing
	hall.tutorial_event.connect(_on_event)
	if SHEET_URL != "":
		_http = HTTPRequest.new()
		_http.use_threads = not OS.has_feature("web")
		_http.timeout = TIMEOUT
		add_child(_http)
		_http.request_completed.connect(_on_sent)
		if SEND_TEST_ROW_ON_START:
			_log.call_deferred("test", [])


## Switches this logger to the AI playtest target: rows go to AI_CSV_PATH with
## AI_COLUMNS appended, and are posted with "sheet":"ai" so they land in the
## "AI Raw" tab. Posting only starts once a GET of SHEET_URL answers with
## ai_tab:true (the redeployed script); the old script would write AI rows
## into the human tab, so then nothing is posted. Call before the first row.
## run_id: unique per run (the bridge builds it). persona/seed_value/run_number/mode:
## the extra cells. can_post: false (--no-sheet) keeps everything local.
func configure_ai(run_id: String, persona: String, seed_value: int, run_number: int, mode: String, can_post: bool) -> void:
	if not ENABLED:
		return
	_is_ai = true
	_run_id = run_id
	_ai_extras = {"persona": persona, "seed": seed_value, "run_number": run_number, "mode": mode}
	_queue.clear()
	if not can_post or SHEET_URL == "" or _http == null:
		ai_sheet_status = "off"
		return
	ai_sheet_status = "checking"
	_check_http = HTTPRequest.new()
	_check_http.use_threads = not OS.has_feature("web")
	_check_http.timeout = TIMEOUT
	add_child(_check_http)
	_check_http.request_completed.connect(_on_sheet_checked)
	if _check_http.request(SHEET_URL) != OK:
		ai_sheet_status = "offline"


## Rows logged but not yet accepted by the sheet.
func pending_rows() -> int:
	return _queue.size()


## This run's id (the bridge reports it in status).
func run_id() -> String:
	return _run_id


## Tries to send what is queued (the bridge calls it while quitting).
func flush() -> void:
	_send()


## The GET answer: only the redeployed script says ai_tab:true.
func _on_sheet_checked(result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		ai_sheet_status = "offline"
		return
	var answer: Variant = JSON.parse_string(body.get_string_from_utf8())
	if answer is Dictionary and answer.get("ok", false) and answer.get("ai_tab", false):
		ai_sheet_status = "ready"
		_send()
	else:
		ai_sheet_status = "not_redeployed"
		_queue.clear()


func _on_event(event: String, data: Variant = null) -> void:
	match event:
		"end_day":
			var kind := "day_end"
			if hall.run_stats.final_result == HallMain.FINAL_RESULT_WON:
				kind = "final_won"
			elif hall.run_stats.final_result == HallMain.FINAL_RESULT_LOST:
				kind = "final_lost"
			_log(kind, data if data is Array else [])
		"game_over":
			_log("game_over", [])


func _log(kind: String, results: Array) -> void:
	var alive := 0
	var hurt := 0
	var dead := 0
	var pluck_total := 0
	var max_pluck := 0
	for character in hall.roster():
		if HallStyle.is_dead(character):
			dead += 1
			continue
		alive += 1
		pluck_total += character.pluck
		max_pluck = maxi(max_pluck, character.pluck)
		if character.injury_level != GuildCharacter.InjuryLevel.HEALTHY:
			hurt += 1
	var won_today := 0
	var gold_today := 0
	# success odds (percent, 0-100) the day's quests were sent at. A party
	# with no chance yet (-1) counts as 0%; a sure thing past 100 counts as 100
	var odds_min := -1.0
	var odds_total := 0.0
	for result in results:
		gold_today += int(result.get("gold", 0))
		if result.get("succeeded", false):
			won_today += 1
		var chance := clampf(float(result.get("chance", 0)), 0.0, 100.0)
		odds_total += chance
		odds_min = chance if odds_min < 0.0 else minf(odds_min, chance)
	# blank (not 0) on a day nothing was sent, so sheet averages skip that day
	var odds_min_cell: Variant = ""
	var odds_avg_cell: Variant = ""
	if not results.is_empty():
		odds_min_cell = snappedf(odds_min, 0.1)
		odds_avg_cell = snappedf(odds_total / results.size(), 0.1)
	var stats: Dictionary = hall.run_stats
	var row := {
		"run_id": _run_id,
		"logged_at": Time.get_datetime_string_from_system(),
		"platform": OS.get_name(),
		"event": kind,
		"day": GameState.day,
		"gold": GuildUpgrades.gold,
		"standing": GuildUpgrades.standing,
		"standing_change": GuildUpgrades.standing - _last_standing,
		"heroes_alive": alive,
		"heroes_hurt": hurt,
		"heroes_dead": dead,
		"quests_sent_today": results.size(),
		"quests_won_today": won_today,
		"gold_earned_today": gold_today,
		"gold_earned_total": stats.gold_earned,
		"gold_spent_total": stats.gold_spent,
		"quests_sent_total": stats.quests_sent,
		"quests_won_total": stats.quests_won,
		"heroes_hired_total": stats.heroes_hired,
		"items_found_total": stats.items_found,
		"avg_pluck": snappedf(float(pluck_total) / alive, 0.01) if alive > 0 else 0.0,
		"freeplay": GameState.is_freeplay,
		"tutorial_skipped": hall.tutorial != null and bool(hall.tutorial.get("is_skipped")),
		"avg_hire_total": _avg_hire_total(),
		"quest_odds_min_today": odds_min_cell,
		"quest_odds_avg_today": odds_avg_cell,
		# highest Pluck among living heroes after tonight = going into tomorrow
		"max_pluck": max_pluck,
	}
	_last_standing = GuildUpgrades.standing
	if _is_ai:
		row.merge(_ai_extras)
	_write_csv(row)
	# AI rows are only held for posting while the sheet check may still pass
	var can_queue := ai_sheet_status in ["checking", "ready"] if _is_ai else true
	if _http != null and can_queue:
		_queue.append(row)
		while _queue.size() > MAX_QUEUE:
			_queue.pop_front()
		_send()


## The average stat total (HallStyle.quest_stat_total, the applicant letter's
## total) of the new faces in For Hire right now, so playtests show whether
## recruits keep up with the guild (HireScaling). Returning released heroes
## are left out. 0.0 when there are no new recruits.
func _avg_hire_total() -> float:
	var total := 0
	var count := 0
	for recruit in CharacterContainer.hireable_characters:
		if CharacterContainer.released_characters.has(recruit):
			continue
		total += HallStyle.quest_stat_total(recruit)
		count += 1
	return snappedf(float(total) / count, 0.01) if count > 0 else 0.0


## The columns this logger writes: COLUMNS, plus AI_COLUMNS for AI rows.
func _active_columns() -> Array:
	return COLUMNS + AI_COLUMNS if _is_ai else COLUMNS


func _write_csv(row: Dictionary) -> void:
	var columns := _active_columns()
	var path := AI_CSV_PATH if _is_ai else CSV_PATH
	_retire_old_csv(path, columns)
	var is_new := not FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if not is_new else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	if is_new:
		file.store_csv_line(PackedStringArray(columns))
	var line := PackedStringArray()
	for column in columns:
		line.append(str(row[column]))
	file.store_csv_line(line)
	file.close()


## A CSV started before its columns last changed has the old header, so new
## rows wouldn't line up: move it aside to <name>_old.csv (replacing an older
## one) and let _write_csv start a fresh file.
## path: the CSV to check. columns: the header it should have.
func _retire_old_csv(path: String, columns: Array) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var header := file.get_csv_line()
	file.close()
	if header == PackedStringArray(columns):
		return
	var old_path := path.get_basename() + "_old.csv"
	DirAccess.remove_absolute(old_path)
	DirAccess.rename_absolute(path, old_path)


## Post every queued row in one request (one at a time; the next waits).
func _send() -> void:
	if _is_sending or _queue.is_empty():
		return
	# AI rows never post until the redeployed script answered the check
	if _is_ai and ai_sheet_status != "ready":
		return
	var columns := _active_columns()
	var rows := []
	for row in _queue:
		var values := []
		for column in columns:
			values.append(row[column])
		rows.append(values)
	var payload := {"token": TOKEN, "columns": columns, "rows": rows}
	if _is_ai:
		payload["sheet"] = "ai"
	var body := JSON.stringify(payload)
	# text/plain keeps a web build's request "simple" (no CORS preflight)
	var error := _http.request(SHEET_URL, ["Content-Type: text/plain;charset=utf-8"], HTTPClient.METHOD_POST, body)
	if error == OK:
		_is_sending = true
		_sending_count = rows.size()
		if DEBUG:
			print("RunLogger: sending %d row(s) to the sheet" % rows.size())
	else:
		push_warning("RunLogger: couldn't start the request (error %d)" % error)


func _on_sent(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_sending = false
	var text := body.get_string_from_utf8()
	# only the script's own {"ok": true} counts: a Google sign-in or error
	# page also comes back as 200
	var answer = JSON.parse_string(text)
	var is_ok: bool = result == HTTPRequest.RESULT_SUCCESS and answer is Dictionary and answer.get("ok", false)
	if is_ok:
		if DEBUG:
			print("RunLogger: sheet got %s row(s)" % str(answer.get("added", "?")))
		_queue = _queue.slice(_sending_count)
		_send()
		return
	push_warning("RunLogger: send failed (result %d, HTTP %d). Google said: %s" % [result, code, text.substr(0, 300).strip_edges()])
