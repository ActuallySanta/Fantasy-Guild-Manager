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
## Everything here does nothing off the web (editor, desktop builds).
class_name HallWebUpdate
extends RefCounted

## An update found this soon after start-up (seconds) is applied at once: the
## browser usually finds a new deploy right after the page loads, before the
## player has done anything worth interrupting.
const APPLY_WINDOW_SECONDS := 10.0

# ---- TEXT
const TOAST_UPDATING := "Updating to the newest version…"
const TOAST_UPDATE_READY := "Update ready · it loads next time you open the game"


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


## A newer deploy is waiting: apply it if the game only just opened, else say so.
## hall: the hall that was watching (may be gone after start_new_run).
## started_msec: Time.get_ticks_msec() when watch() was called.
static func _on_update_available(hall: HallMain, started_msec: int) -> void:
	if not is_instance_valid(hall) or not hall.is_inside_tree():
		return
	var seconds_open := (Time.get_ticks_msec() - started_msec) / 1000.0
	if seconds_open <= APPLY_WINDOW_SECONDS:
		hall.show_toast(TOAST_UPDATING)
		hall.save_now()
		JavaScriptBridge.pwa_update()
	else:
		hall.show_toast(TOAST_UPDATE_READY)
