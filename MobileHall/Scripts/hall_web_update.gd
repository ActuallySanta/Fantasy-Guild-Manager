## Gets new web deploys onto phones without the player clearing caches.
##
## Why: the web export is a PWA. Godot's service worker
## (index.service.worker.js) serves index.pck / index.wasm cache-first. A new
## deploy installs a new worker, but it waits until every tab with the game is
## closed, so an ordinary reload keeps running the old build. JavaScriptBridge
## can tell when a new worker is waiting (pwa_needs_update) and switch to it,
## which reloads the page (pwa_update).
##
## hall_main._ready calls:
##   - apply_waiting_update() first: an update that was already waiting is
##     applied before anything else happens (the run is saved, HallSave loads
##     it back after the reload);
##   - watch(hall) after setup: an update found while playing is applied if the
##     game only just opened (APPLY_WINDOW_SECONDS), otherwise a toast says it
##     loads next time.
## Menu > Debug tools > Check for update asks on demand: check_latest() fetches
## the live site's build stamp (HallBuildInfo.LATEST_WEB_FILE) and compares it
## with this build's; the confirm popup's Update button calls update_now().
## Everything here does nothing off the web (editor, desktop builds).
class_name HallWebUpdate
extends RefCounted

## What check_latest() found.
enum CheckResult {
	UP_TO_DATE, ## the site's stamp matches this build's
	UPDATE_AVAILABLE, ## the site has a different (newer) build
	NOT_WEB, ## not running in a browser, so there's nothing to check
	FAILED, ## the stamp couldn't be fetched (offline, 404 on a local export, ...)
}

## An update found this soon after start-up (seconds) is applied at once: the
## browser usually finds a new deploy right after the page loads, before the
## player has done anything worth interrupting.
const APPLY_WINDOW_SECONDS := 10.0
## How long update_now() waits (seconds) for the service worker to download
## the new deploy before it falls back to a plain page reload (e.g. a page
## that has no service worker, so a reload is all it takes).
const UPDATE_TIMEOUT_SECONDS := 15.0
## How long check_latest() waits for the site's stamp (seconds) before it
## gives up and reports FAILED.
const CHECK_TIMEOUT_SECONDS := 10.0

# ---- TEXT
const TOAST_UPDATING := "Updating to the newest version…"
const TOAST_UPDATE_READY := "Update ready · it loads next time you open the game"
const TOAST_DOWNLOADING := "Downloading the update…"

## True once the player tapped Update (update_now): the next new worker is
## applied straight away instead of waiting for the next launch. This is page
## state, not run state: the reload it leads to clears it.
static var _is_update_requested := false


## If a newer deploy is already waiting, switch to it now (the page reloads).
## Returns true when an update was started, so the caller can stop setting up.
static func apply_waiting_update() -> bool:
	if not OS.has_feature("web"):
		return false
	if not JavaScriptBridge.pwa_needs_update():
		return false
	return JavaScriptBridge.pwa_update() == OK


## Listen for a newer deploy turning up while the game is open.
## hall: the hall, for the toast and the save before an early reload.
static func watch(hall: HallMain) -> void:
	if not OS.has_feature("web"):
		return
	# JavaScriptBridge is an engine singleton, so the connection can outlive
	# this hall (start_new_run reloads the scene): it fires once at most, and
	# _on_update_available ignores a hall that's gone
	var started_msec := Time.get_ticks_msec()
	JavaScriptBridge.pwa_update_available.connect(
		func() -> void: _on_update_available(hall, started_msec),
		CONNECT_ONE_SHOT)
	# a worker that finished installing while the game was loading
	if JavaScriptBridge.pwa_needs_update():
		_on_update_available(hall, started_msec)


## Ask the live site which build it serves and compare it with this one.
## host: a node in the tree; a temporary HTTPRequest is added under it.
## on_done: called once as on_done(result: CheckResult, latest_stamp: String);
## latest_stamp is "" unless the fetch worked.
static func check_latest(host: Node, on_done: Callable) -> void:
	if not OS.has_feature("web"):
		on_done.call(CheckResult.NOT_WEB, "")
		return
	var request := HTTPRequest.new()
	request.timeout = CHECK_TIMEOUT_SECONDS
	host.add_child(request)
	request.request_completed.connect(_on_check_completed.bind(request, on_done), CONNECT_ONE_SHOT)
	# no-cache + a throwaway query: GitHub Pages lets browsers cache files for
	# 10 minutes, and this must be the stamp that's live right now
	if request.request(_latest_stamp_url(), ["Cache-Control: no-cache"]) != OK:
		request.queue_free()
		on_done.call(CheckResult.FAILED, "")


## check_latest's HTTPRequest finished: compare the stamps and report.
## result/code/body: from request_completed. request: the temporary node (freed
## here). on_done: check_latest's callback.
static func _on_check_completed(result: int, code: int, _headers: PackedStringArray,
		body: PackedByteArray, request: HTTPRequest, on_done: Callable) -> void:
	request.queue_free()
	var latest := HallBuildInfo.parse_stamp(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or latest == "":
		on_done.call(CheckResult.FAILED, "")
	elif latest == HallBuildInfo.stamp():
		on_done.call(CheckResult.UP_TO_DATE, latest)
	else:
		on_done.call(CheckResult.UPDATE_AVAILABLE, latest)


## The confirm popup's Update button: save the run, then switch to the newest
## deploy (the page reloads and HallSave loads the run back).
## hall: the hall, for the save and the toasts.
static func update_now(hall: HallMain) -> void:
	if not OS.has_feature("web"):
		return
	# does nothing while saving is off or in a debug run (the popup warns)
	hall.save_now()
	if JavaScriptBridge.pwa_needs_update():
		hall.show_toast(TOAST_UPDATING)
		JavaScriptBridge.pwa_update()
		return
	# the worker hasn't seen the new deploy yet: ask it to look. When it has
	# installed it, pwa_update_available fires and _on_update_available applies
	# it at once (because of this flag)
	_is_update_requested = true
	hall.show_toast(TOAST_DOWNLOADING)
	JavaScriptBridge.eval(
		"navigator.serviceWorker && navigator.serviceWorker.getRegistration()"
		+ ".then((r) => r && r.update())")
	# no worker took over in time: a plain reload (the lambda holds no hall,
	# so it's safe after start_new_run; nothing is left to do if the page
	# already reloaded)
	hall.get_tree().create_timer(UPDATE_TIMEOUT_SECONDS).timeout.connect(
		func() -> void: JavaScriptBridge.eval("location.reload()"))


## A newer deploy is waiting: apply it if the game only just opened or the
## player asked for it (update_now), else say it loads next time.
## hall: the hall that was watching (may be gone after start_new_run).
## started_msec: Time.get_ticks_msec() when watch() was called.
static func _on_update_available(hall: HallMain, started_msec: int) -> void:
	if _is_update_requested:
		# update_now already saved the run and said so
		JavaScriptBridge.pwa_update()
		return
	if not is_instance_valid(hall) or not hall.is_inside_tree():
		return
	var seconds_open := (Time.get_ticks_msec() - started_msec) / 1000.0
	if seconds_open <= APPLY_WINDOW_SECONDS:
		hall.show_toast(TOAST_UPDATING)
		hall.save_now()
		JavaScriptBridge.pwa_update()
	else:
		hall.show_toast(TOAST_UPDATE_READY)


## Web: the site's build stamp next to this page, with a throwaway query so no
## cache answers for it, e.g. ".../Fantasy-Guild-Manager/build_info.txt?t=123".
static func _latest_stamp_url() -> String:
	return str(JavaScriptBridge.eval(
		"new URL('%s?t=' + Date.now(), window.location.href).href" % HallBuildInfo.LATEST_WEB_FILE))
