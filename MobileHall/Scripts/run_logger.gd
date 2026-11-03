## Run logger: one row per day (gold, standing, heroes, quest tallies) for
## balancing. Every row goes to a local CSV (user://run_log.csv) and, when
## SHEET_URL is set, to a Google Sheet through a small Apps Script web app
## (MobileHall/Playtest/run_log_apps_script.gs has the script and setup).
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
## Seconds before a send gives up (it retries with the next row).
const TIMEOUT := 10.0
## Print each send and Google's answer to the Output panel.
const DEBUG := false
## Post one "test" row when the hall opens, to check the sheet without
## playing a day. Turn off once rows show up.
const SEND_TEST_ROW_ON_START := false
## Most rows held while offline; the oldest are dropped past this.
const MAX_QUEUE := 200

## Column order for the CSV and the sheet.
const COLUMNS := [
	"run_id", "logged_at", "platform", "event", "day",
	"gold", "standing", "standing_change",
	"heroes_alive", "heroes_hurt", "heroes_dead",
	"quests_sent_today", "quests_won_today", "gold_earned_today",
	"gold_earned_total", "gold_spent_total", "quests_sent_total", "quests_won_total",
	"heroes_hired_total", "items_found_total", "avg_pluck",
	"freeplay", "tutorial_skipped",
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
	for character in hall.roster():
		if HallStyle.is_dead(character):
			dead += 1
			continue
		alive += 1
		pluck_total += character.pluck
		if character.injury_level != GuildCharacter.InjuryLevel.HEALTHY:
			hurt += 1
	var won_today := 0
	var gold_today := 0
	for result in results:
		gold_today += int(result.get("gold", 0))
		if result.get("succeeded", false):
			won_today += 1
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
	}
	_last_standing = GuildUpgrades.standing
	_write_csv(row)
	if _http != null:
		_queue.append(row)
		while _queue.size() > MAX_QUEUE:
			_queue.pop_front()
		_send()


func _write_csv(row: Dictionary) -> void:
	var is_new := not FileAccess.file_exists(CSV_PATH)
	var file := FileAccess.open(CSV_PATH, FileAccess.READ_WRITE if not is_new else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	if is_new:
		file.store_csv_line(PackedStringArray(COLUMNS))
	var line := PackedStringArray()
	for column in COLUMNS:
		line.append(str(row[column]))
	file.store_csv_line(line)
	file.close()


## Post every queued row in one request (one at a time; the next waits).
func _send() -> void:
	if _is_sending or _queue.is_empty():
		return
	var rows := []
	for row in _queue:
		var values := []
		for column in COLUMNS:
			values.append(row[column])
		rows.append(values)
	var body := JSON.stringify({"token": TOKEN, "columns": COLUMNS, "rows": rows})
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
