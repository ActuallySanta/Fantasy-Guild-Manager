## Eyes-mode helpers for the AI playtest bridge: screenshots, taps and waits.
## Used by agent_bridge.gd (Scenes/Playtest/agent_bridge.tscn). All static;
## the counters they need are passed in, since run state lives on the bridge.
## Excluded from exports like the rest of the bridge (export_presets.cfg).
class_name AgentBridgeEyes
extends RefCounted

# ---- TUNING
## Seconds to wait after a tap before the screenshot, so the hall's reaction
## (refresh, tween starts, toasts) is on screen. Seconds.
const TAP_SETTLE_SECONDS := 0.6
## The longest a `wait` command may sleep. Seconds.
const MAX_WAIT_SECONDS := 10.0
## The game's size in viewport coordinates, and the size of every screenshot. Pixels.
const GAME_SIZE := Vector2(720, 1280)
## Room left for the window frame and the taskbar when fitting the window. Pixels.
const WINDOW_MARGIN_PIXELS := 80
## Folder inside the bridge directory that screenshots go to.
const SHOTS_FOLDER := "shots/"
## Commands an eyes-mode persona may use. Everything else is refused, so the
## persona sees only what a player sees.
const ALLOWED_COMMANDS: Array[String] = ["ping", "status", "screenshot", "tap", "wait", "quit"]
## Text of the refusal for any other command.
const NOT_ALLOWED_ERROR := "not allowed in eyes mode"


## Makes the game window show the whole 720x1280 game on any desktop: scales
## the content to fit (aspect kept) and sizes the window to a 9:16 shape that
## fits the screen's usable height, so there are no black bars and nothing is
## cut off. The screenshot is then resized to GAME_SIZE (see screenshot).
## window: the root window.
static func fit_window(window: Window) -> void:
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_size = Vector2i(GAME_SIZE)
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var height := mini(int(GAME_SIZE.y), usable.size.y - WINDOW_MARGIN_PIXELS)
	window.size = Vector2i(roundi(height * GAME_SIZE.x / GAME_SIZE.y), height)
	window.position = usable.position


## True when eyes mode may run this command. (debug_rect, a --test-hooks
## command, is let through by the caller.) command: the command name.
static func is_allowed(command: String) -> bool:
	return command in ALLOWED_COMMANDS


## Saves the viewport's current image to <bridge_dir>/shots/<day>-<n>.png.
## viewport: the bridge's viewport. bridge_dir: with trailing slash. shot_number:
## the running shot counter (already incremented by the caller).
## Waits for the frame to finish drawing first (the very first frame is blank).
## Returns {ok, path, width, height, day}, or {ok: false, error}.
static func screenshot(viewport: Viewport, bridge_dir: String, shot_number: int) -> Dictionary:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image.get_size() != Vector2i(GAME_SIZE):
		image.resize(int(GAME_SIZE.x), int(GAME_SIZE.y), Image.INTERPOLATE_LANCZOS)
	var folder := bridge_dir + SHOTS_FOLDER
	DirAccess.make_dir_recursive_absolute(folder)
	var path := "%s%d-%d.png" % [folder, GameState.day, shot_number]
	var error := image.save_png(path)
	if error != OK:
		return {"ok": false, "error": "could not save screenshot (%d)" % error}
	return {"ok": true, "path": path, "width": image.get_width(), "height": image.get_height(), "day": GameState.day}


## Taps at a point in viewport coordinates (the 720x1280 game space, whatever the window's size): a mouse
## press, then the release a frame later, pushed straight into the viewport.
## Waits TAP_SETTLE_SECONDS afterwards. viewport: the bridge's viewport.
## tree: for frame and timer waits. tap_args: {x, y}.
## Returns {ok} or {ok: false, error}; the caller adds the screenshot.
static func tap(viewport: Viewport, tree: SceneTree, tap_args: Dictionary) -> Dictionary:
	var x: Variant = tap_args.get("x")
	var y: Variant = tap_args.get("y")
	if not (x is float or x is int) or not (y is float or y is int):
		return {"ok": false, "error": "tap needs numeric x and y"}
	var point := Vector2(float(x), float(y))
	if not Rect2(Vector2.ZERO, viewport.get_visible_rect().size).has_point(point):
		return {"ok": false, "error": "tap outside the screen"}
	# a motion first, so hover states and the focus logic see the pointer arrive
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.position = point
	press.global_position = point
	viewport.push_input(press, true)
	await tree.process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = point
	release.global_position = point
	viewport.push_input(release, true)
	await tree.create_timer(TAP_SETTLE_SECONDS).timeout
	return {"ok": true}


## Sleeps for the asked seconds (clamped to 0..MAX_WAIT_SECONDS).
## tree: for the timer. wait_args: {seconds}. Returns {ok, waited}.
static func wait(tree: SceneTree, wait_args: Dictionary) -> Dictionary:
	var seconds := clampf(float(wait_args.get("seconds", 1.0)), 0.0, MAX_WAIT_SECONDS)
	await tree.create_timer(seconds).timeout
	return {"ok": true, "waited": seconds}


## Test hook (--test-hooks only): the global rect of a node in the hall, so a
## test can tap its center. The node is named by its unique name ("BeginButton",
## found anywhere under the hall) or a NodePath relative to the hall
## ("Overlays/OverlayIntro/..."). hall: the running hall. debug_args: {node}.
## Returns {ok, x, y, w, h, cx, cy, visible} (visible = shown in the tree).
static func debug_rect(hall: Node, debug_args: Dictionary) -> Dictionary:
	var node_name := str(debug_args.get("node", "")).trim_prefix("%")
	if node_name.is_empty():
		return {"ok": false, "error": "debug_rect needs node"}
	var node: Node = hall.get_node_or_null(node_name) if "/" in node_name else hall.find_child(node_name, true, false)
	if not node is Control:
		return {"ok": false, "error": "no Control named %s" % node_name}
	var rect: Rect2 = node.get_global_rect()
	var center := rect.get_center()
	return {"ok": true, "x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y, "cx": center.x, "cy": center.y, "visible": node.is_visible_in_tree()}
