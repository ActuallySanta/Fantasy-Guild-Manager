## Tutorial coach: Pip the guild clerk walks a new player through the real
## Mobile Hall UI on Days 1, 2, 3 and 5. Each step spotlights one control and
## waits for the player to use it (or press Next on explain-only steps), so
## the player learns by doing instead of reading an intro screen.
##   Day 1 - the core loop only: hiring, reading a quest, picking a party,
##           Send, End Day, the Day Report
##   Day 2 - a hero's page (stats, Pluck, gear), odds and what a win grows
##           (a trained stat or Pluck), Deny,
##           how the guild can fall (HallMain.is_run_over)
##   Day 3 - the Guild tab: upgrading a building, the Training Yard, the
##           Hospital, and why posted heroes can't quest
##   Day 5 - the Shop: role-locked items, buying, equipping from a hero's page
##   Freeplay - after the final battle is won (HallMain.start_freeplay): what
##           changes now the story is over (endless days, climbing quests,
##           the S++ rank). Runs even if the main tutorial was skipped.
##
## Built in code; hall_main._ready adds it on top of every overlay.
## UI only: it calls nothing but hall_main's own actions and queries.
##
## WHAT THE PLAYER SEES
##   - everything outside the spotlight is dimmed (a dark wash)
##     and swallows taps; every button outside the spotlight is disabled
##   - a gold ring and a bouncing arrow on the one thing to tap
##   - Pip's bubble docks at the top or bottom, whichever is clear of the
##     spotlight, and glides there when the spotlight moves. Tap Pip to swap
##     sides. If neither side is clear, Pip shrinks to a small chip (tap to
##     read the full line).
##
## HOW IT WORKS
##   hall_main emits tutorial_event(event, data) from its actions:
##     tab, hire, character, close, assign, pick, send, deny, end_check,
##     end_day, new_day, upgrade, training_picker, train, admit, buy, equip,
##     freeplay
##   A step is a Dictionary:
##     text    String or Callable -> String (BBCode)
##     do      short instruction under the text ("Tap Members")
##     target  Callable -> Control to spotlight (missing = no spotlight)
##     on      event that finishes the step (missing = Next button)
##     when    Callable(data) -> bool, must be true for `on` to count
##     reject  toast shown when `on` fires but `when` is false (the screen
##             it opened is closed again)
##     skip    Callable() -> bool, checked when the step comes up
##     tap     true = the spotlit control stays usable on a Next step
##     deny    node names inside the spotlight to keep disabled anyway
##             (e.g. a row's Info button that would leave the step)
##   If a step's target can't be found for a moment, Next appears so the
##   player can never get stuck.
##
## Tab pacing: while the tutorial is on, Guild (id "upgrades") unlocks on
## Day 3 and Shop on Day 5. Skipping the tutorial lifts both locks.
class_name OverlayTutorial
extends Control


## Off = no coach, no tab locks, and the old Welcome card shows instead.
const ENABLED := true
const TUTORIAL_DAYS := [1, 2, 3, 5]
## Script key for the freeplay walkthrough (not a day: it starts on the
## "freeplay" event, whatever day that is).
const FREEPLAY_SCRIPT := -1
const UNLOCK_DAY := {"upgrades": 3, "shop": 5}

## Draw order: above the hall's overlays (z 10: Day Report, End Day sheet,
## toast) and the raised art inside tabs (applicant letters, scroll rollers),
## so the dim, ring and Pip always sit on top of what they point at.
const TUTORIAL_Z_INDEX := 20
## The spotlight ring and the arrow are white art (Styles/stamp.tres, Art/Icons)
## tinted this gold.
const RING_COLOR := Color("#F6B93B")
const HOLE_PAD := 10.0
const BUBBLE_MARGIN := 16.0
## Gap kept between Pip's bubble and the spotlight.
const BUBBLE_CLEARANCE := 24.0
## Seconds a step's target may be missing before Next shows up.
const MISSING_GRACE := 0.6
## How often (seconds) buttons outside the spotlight are re-disabled,
## since the hall rebuilds rows on every refresh.
const LOCK_INTERVAL := 0.1

## Dim laid over everything outside the spotlight: a plain translucent wash.
## (Reading the screen back to grey it out rendered wrong on iPhone Safari:
## ghost copies of Pip and cropped slices.) Alpha = how dark it gets, 0..1.
const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.55)

# ---- coloured words (the stat inks in HallStyle.STATS, and HallStyle.GOLD_TEXT)
const POW := "[color=#8B2E2A]Power[/color]"
const DEF := "[color=#2F4A66]Defense[/color]"
const WIS := "[color=#5B4A7A]Wisdom[/color]"
const SLZ := "[color=#3D5A2A]Sleaziness[/color]"
const PLK := "[color=#7A4A1E]Pluck[/color]"
const GOLD := "[color=#6B5A1E]gold[/color]"

# ---- art reused from MobileHall/Art (swap the files to restyle the coach)
## Pip sits in the same round portrait frame as the heroes on the Board.
const PORTRAIT_MASK := preload("uid://buv1wa6etd3u3")  # MobileHall/Art/Textures/portrait_round_mask.png
const PORTRAIT_FRAME := preload("uid://cscfv0x0mk446")  # MobileHall/Art/Textures/portrait_round_frame.png
## The pointer is the pixel arrow icon (it points left; it's turned to point up / down).
const ARROW_ICON := preload("uid://c2nc04lk4jmw3")  # MobileHall/Art/Icons/arrow_left.tres
## Ground behind Pip inside the frame (a parchment tint).
const PIP_GROUND := Color("#E9DEC4")

## The main hall script (untyped: hall_main preloads this file).
var hall: Control
## True once the player taps Skip tutorial (also lifts the tab locks).
var is_skipped := false
## Tutorial scripts already finished or skipped (a day, or FREEPLAY_SCRIPT).
var done := {}

## The day shown on Pip's counter.
var _day := 0
## Which script is running: a day from TUTORIAL_DAYS, or FREEPLAY_SCRIPT.
var _script := 0
var _steps: Array = []
var _index := -1
## Events seen during the current day's script (for skip checks).
var _seen := {}
## The item bought on Day 5 (to point at the hero who can use it).
var _bought_item: StandardItem
var _missing_for := 0.0
var _last_target: Control
var _time := 0.0
var _shake_until := 0.0
var _shown_text := ""
## Buttons this coach disabled -> their own disabled value, to put back.
var _locked := {}
var _lock_timer := 0.0
## Pip's dock: true = bottom of the screen. Tapping Pip flips it.
var _dock_bottom := true
## The player tapped Pip to force their preferred side this step.
var _dock_forced := false
## Compact chip opened up by tapping it.
var _expanded := false
var _bubble_goal := Vector2.ZERO
## Steps shown so far this script (for Back), newest last.
var _history: Array[int] = []
## Furthest step the player has reached. Steps before it are being reviewed:
## read-only, with Next (their action was already done).
var _reached := -1
## Steps left behind by Back, so Next retraces exactly what was shown.
var _forward: Array[int] = []

# ---- nodes (built in _build)
var _blockers: Array[ColorRect] = []
var _cover: Control
var _ring: Panel
var _pointer: Pointer
var _bubble: PanelContainer
## Pip's framed portrait (tap it to move Pip or open the chip).
var _face: Control
var _counter: Label
var _text: RichTextLabel
var _do_label: Label
var _hint: Label
var _next_button: Button
var _back_button: Button
var _skip_button: Button


# ============================================================ SETUP

func setup(main: Control) -> void:
	hall = main
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = TUTORIAL_Z_INDEX
	_build()
	visible = false
	set_process(false)
	hall.tutorial_event.connect(_on_event)
	# a run brought back from the save file picks up through resume_today() instead
	if ENABLED and GameState.day == 1 and not hall.is_resumed_run:
		hall.is_welcome_open = false
		start.call_deferred(1)


## A saved run was just loaded (HallSave.load_run restored is_skipped and done):
## if today has a tutorial script that wasn't finished, run it again from its
## first step. Not while the night's report, the credits or Game Over is up.
func resume_today() -> void:
	var day := GameState.day
	if not ENABLED or is_skipped or not TUTORIAL_DAYS.has(day) or done.get(day, false):
		return
	if not (hall.shown_report.is_empty() and hall.shown_credits.is_empty() and hall.run_over_stats.is_empty()):
		return
	start.call_deferred(day)


## Tabs held back until the tutorial gets to them.
func is_tab_locked(tab_id: String) -> bool:
	if not ENABLED or is_skipped or not UNLOCK_DAY.has(tab_id):
		return false
	return GameState.day < UNLOCK_DAY[tab_id]


func unlock_day(tab_id: String) -> int:
	return UNLOCK_DAY.get(tab_id, 0)


func is_running() -> bool:
	return _index >= 0

# ============================================================ FLOW

## Run a script on `day` (the counter shows it). script = which steps to run;
## by default the day's own (TUTORIAL_DAYS), or FREEPLAY_SCRIPT.
func start(day: int, script: int = day) -> void:
	_day = day
	_script = script
	_steps = _steps_for(script)
	_seen = {}
	_index = -1
	_history = []
	_forward = []
	_reached = -1
	visible = true
	set_process(true)
	_bubble.position = Vector2(BUBBLE_MARGIN, size.y)
	_advance()


func _advance() -> void:
	if _index >= 0:
		_history.append(_index)
	if not _forward.is_empty():
		# retracing after Back: the next step that was actually shown
		_index = _forward.pop_back()
		_reset_step()
		return
	_index += 1
	while _index < _steps.size() and _steps[_index].has("skip") and _steps[_index]["skip"].call():
		_index += 1
	_reached = maxi(_reached, _index)
	_reset_step()
	if _index >= _steps.size():
		_finish()


## Back: show the previous step again, read-only.
func _go_back() -> void:
	if _history.is_empty():
		return
	_forward.append(_index)
	_index = _history.pop_back()
	_reset_step()


## A step before the furthest one reached: its action is already done.
func _is_reviewing() -> bool:
	return _index < _reached


func _reset_step() -> void:
	_missing_for = 0.0
	_last_target = null
	_shown_text = ""
	_dock_forced = false
	_expanded = false
	_lock_timer = 0.0


func _finish() -> void:
	done[_script] = true
	_index = -1
	_steps = []
	visible = false
	set_process(false)
	_release_locks()
	hall.queue_refresh()


func skip_tutorial() -> void:
	is_skipped = true
	_finish()


func _on_event(event: String, data: Variant = null) -> void:
	_seen[event] = true
	if event == "buy" and data is StandardItem:
		_bought_item = data
	# Day 3 and Day 5 begin when their morning starts
	if event == "new_day" and ENABLED and not is_skipped and TUTORIAL_DAYS.has(int(data)) and not done.get(int(data), false):
		if is_running():
			_finish()
		start(int(data))
		return
	# freeplay explains a new mode, so it runs even after Skip tutorial
	if event == "freeplay" and ENABLED and not done.get(FREEPLAY_SCRIPT, false):
		if is_running():
			_finish()
		start(int(data), FREEPLAY_SCRIPT)
		return
	if not is_running() or _is_reviewing():
		return
	var step: Dictionary = _steps[_index]
	if step.get("on", "") != event:
		return
	var when = step.get("when")
	if when is Callable and not when.call(data):
		if step.has("reject"):
			hall.show_toast(step["reject"].call() if step["reject"] is Callable else step["reject"])
			hall.close_screen.call_deferred()
		return
	_advance()

# ============================================================ FRAME

func _process(delta: float) -> void:
	if not is_running():
		return
	_time += delta
	var step: Dictionary = _steps[_index]

	var target: Control = null
	var getter = step.get("target")
	if getter is Callable:
		var found = getter.call()
		if found is Control and is_instance_valid(found) and found.is_visible_in_tree():
			target = found
	if target != null and target != _last_target:
		_last_target = target
		_scroll_into_view(target)
		_lock_timer = 0.0
	_missing_for = 0.0 if (target != null or getter == null) else _missing_for + delta

	_lock_timer -= delta
	if _lock_timer <= 0.0:
		_lock_timer = LOCK_INTERVAL
		_apply_locks(step, target)
	_layout(step, target, delta)


## Is the spotlit control meant to be used on this step?
func _is_live(step: Dictionary) -> bool:
	if _is_reviewing():
		return false
	return step.has("on") or step.get("tap", false)

# ============================================================ BUTTON LOCKS

## Disable every button in the hall except the ones inside a live spotlight.
## (Rows that are tap panels, not Buttons, are stopped by the dim blockers.)
func _apply_locks(step: Dictionary, target: Control) -> void:
	var live_root: Control = target if (target != null and _is_live(step)) else null
	var denied: Array = step.get("deny", [])
	var buttons: Array = []
	_collect_buttons(hall, buttons)
	for button in buttons:
		var is_allowed: bool = live_root != null and (button == live_root or live_root.is_ancestor_of(button)) and not denied.has(String(button.name))
		if is_allowed:
			if _locked.has(button):
				button.disabled = _locked[button]
				_locked.erase(button)
			continue
		if not _locked.has(button):
			_locked[button] = button.disabled
		elif not button.disabled:
			# the hall re-enabled it in a refresh: that's its real state now
			_locked[button] = false
		button.disabled = true
	for button in _locked.keys():
		if not is_instance_valid(button):
			_locked.erase(button)


func _collect_buttons(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child == self or child is CanvasLayer:
			continue
		if child is BaseButton:
			out.append(child)
		_collect_buttons(child, out)


## A button's own enabled state, ignoring this coach's locks.
func _is_enabled(button: BaseButton) -> bool:
	return not _locked[button] if _locked.has(button) else not button.disabled


func _release_locks() -> void:
	for button in _locked:
		if is_instance_valid(button):
			button.disabled = _locked[button]
	_locked.clear()

# ============================================================ LAYOUT

func _layout(step: Dictionary, target: Control, delta: float) -> void:
	var full: Vector2 = size
	var waits: bool = step.has("on") and not _is_reviewing()
	var is_lost: bool = step.get("target") != null and target == null and _missing_for > MISSING_GRACE
	var show_next: bool = not waits or is_lost

	# ---- the spotlight hole and the dim around it
	var hole := Rect2()
	if target != null:
		var xf: Transform2D = get_global_transform().affine_inverse() * target.get_global_transform()
		hole = Rect2(xf.origin, target.size * xf.get_scale()).grow(HOLE_PAD).intersection(Rect2(Vector2.ZERO, full))
	if hole.has_area():
		_set_rect(_blockers[0], Rect2(0, 0, full.x, hole.position.y))
		_set_rect(_blockers[1], Rect2(0, hole.end.y, full.x, full.y - hole.end.y))
		_set_rect(_blockers[2], Rect2(0, hole.position.y, hole.position.x, hole.size.y))
		_set_rect(_blockers[3], Rect2(hole.end.x, hole.position.y, full.x - hole.end.x, hole.size.y))
	else:
		_set_rect(_blockers[0], Rect2(Vector2.ZERO, full))
		for blocker_index in range(1, 4):
			_set_rect(_blockers[blocker_index], Rect2())
	# explain-only steps cover the hole too (no dim, just no taps)
	_set_rect(_cover, hole if (hole.has_area() and not _is_live(step)) else Rect2())

	_ring.visible = hole.has_area()
	if _ring.visible:
		_ring.position = hole.position
		_ring.size = hole.size
		_ring.modulate.a = 0.65 + 0.35 * sin(_time * 6.0)

	# ---- bubble text
	var text: String = step["text"].call() if step["text"] is Callable else step["text"]
	if text != _shown_text:
		_shown_text = text
		_text.text = text
	_counter.text = "Day %d · %d/%d" % [_day, _index + 1, _steps.size()]
	var do_text: String = step.get("do", "")
	if is_lost or _is_reviewing():
		do_text = ""
	elif do_text == "" and waits:
		do_text = "Tap the glowing spot"
	elif do_text == "" and step.get("tap", false):
		do_text = "Try it, then tap Next"
	_do_label.text = ("▶  " + do_text.to_upper()) if do_text != "" else ""
	_do_label.visible = do_text != ""
	_next_button.visible = show_next
	_back_button.visible = not _history.is_empty()
	_next_button.text = "Got it" if _index == _steps.size() - 1 else "Next"
	_hint.text = "Tap me to move"

	# ---- where Pip goes: the dock (top / bottom) that's clear of the hole
	var width := full.x - BUBBLE_MARGIN * 2
	_bubble.custom_minimum_size.x = width
	_set_compact(false)
	var full_height: float = _measure_bubble(width)
	var top_rect := Rect2(BUBBLE_MARGIN, BUBBLE_MARGIN, width, full_height)
	var bottom_rect := Rect2(BUBBLE_MARGIN, full.y - full_height - BUBBLE_MARGIN, width, full_height)
	var keep_clear := hole.grow(BUBBLE_CLEARANCE)
	var top_ok := not hole.has_area() or not top_rect.intersects(keep_clear)
	var bottom_ok := not hole.has_area() or not bottom_rect.intersects(keep_clear)
	if not _dock_forced:
		if top_ok and not bottom_ok:
			_dock_bottom = false
		elif bottom_ok and not top_ok:
			_dock_bottom = true
		elif top_ok and bottom_ok and hole.has_area():
			# both clear: sit on the far side from the spotlight
			_dock_bottom = hole.get_center().y < full.y * 0.5
	var fits: bool = bottom_ok if _dock_bottom else top_ok
	var goal: Vector2
	if not hole.has_area():
		goal = Vector2(BUBBLE_MARGIN, (full.y - full_height) * 0.42)
	elif fits or _expanded:
		goal = Vector2(BUBBLE_MARGIN, bottom_rect.position.y if _dock_bottom else top_rect.position.y)
	else:
		# no room either side: shrink to a chip in the corner farthest from the spotlight
		_set_compact(true)
		var chip_height: float = _measure_bubble(width)
		var chip_top := Rect2(BUBBLE_MARGIN, BUBBLE_MARGIN, width, chip_height)
		var chip_bottom := Rect2(BUBBLE_MARGIN, full.y - chip_height - BUBBLE_MARGIN, width, chip_height)
		var top_overlap := chip_top.intersection(hole).get_area()
		var bottom_overlap := chip_bottom.intersection(hole).get_area()
		if not _dock_forced:
			_dock_bottom = bottom_overlap <= top_overlap
		goal = chip_bottom.position if _dock_bottom else chip_top.position
	var shake := 0.0
	if _time < _shake_until:
		shake = sin(_time * 60.0) * 10.0
	_bubble_goal = goal
	_bubble.position = _bubble.position.lerp(goal, clampf(delta * 10.0, 0.0, 1.0)) + Vector2(shake, 0)

	# ---- the arrow: just outside the hole, on the side facing Pip if there's room
	_pointer.visible = hole.has_area() and _is_live(step) and not is_lost
	if _pointer.visible:
		var arrow_size := _pointer.custom_minimum_size
		var bob := 6.0 * sin(_time * 5.0)
		var above_room := hole.position.y > arrow_size.y + 8
		var below_room := full.y - hole.end.y > arrow_size.y + 8
		var point_down := above_room and (not _dock_bottom or not below_room)
		_pointer.points_down = point_down
		var arrow_x := clampf(hole.get_center().x - arrow_size.x * 0.5, 8, full.x - arrow_size.x - 8)
		var arrow_y := hole.position.y - arrow_size.y - 2 + bob if point_down else hole.end.y + 2 - bob
		if not above_room and not below_room:
			arrow_y = hole.position.y + 6
		_pointer.position = Vector2(arrow_x, arrow_y)
		_pointer.size = arrow_size
		_pointer.queue_redraw()


## Full bubble, or just Pip + the instruction (tap to open).
func _set_compact(is_compact: bool) -> void:
	_text.visible = not is_compact
	_counter.visible = not is_compact
	_hint.text = "Tap me to read" if is_compact else "Tap me to move"


func _measure_bubble(width: float) -> float:
	_bubble.size = Vector2(width, 0)
	return _bubble.get_combined_minimum_size().y


func _set_rect(control: Control, rect: Rect2) -> void:
	control.visible = rect.has_area()
	control.position = rect.position
	control.size = rect.size


## Bring the target to the middle of its scroll area.
func _scroll_into_view(target: Control) -> void:
	var node := target.get_parent()
	while node != null and node != hall:
		if node is ScrollContainer:
			_center_in_scroll.call_deferred(node, target)
			return
		node = node.get_parent()


func _center_in_scroll(scroll: ScrollContainer, target: Control) -> void:
	if not is_instance_valid(target) or not is_instance_valid(scroll):
		return
	var offset: float = target.global_position.y - scroll.global_position.y
	scroll.scroll_vertical = int(scroll.scroll_vertical + offset - (scroll.size.y - target.size.y) * 0.5)


func _on_blocked_input(event: InputEvent) -> void:
	if _is_press(event):
		_shake_until = _time + 0.35


## Tap Pip: open the chip if it's shrunk, otherwise swap top / bottom.
func _on_face_input(event: InputEvent) -> void:
	if not _is_press(event):
		return
	var is_compact := not _text.visible
	if is_compact and not _expanded:
		_expanded = true
	else:
		_expanded = false
		_dock_forced = true
		_dock_bottom = not _dock_bottom


func _is_press(event: InputEvent) -> bool:
	return (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)

# ============================================================ BUILD

func _build() -> void:
	for blocker_index in 4:
		var blocker := ColorRect.new()
		blocker.color = DIM_COLOR
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		blocker.gui_input.connect(_on_blocked_input)
		add_child(blocker)
		_blockers.append(blocker)

	_cover = Control.new()
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_cover.gui_input.connect(_on_blocked_input)
	add_child(_cover)

	# the spotlight ring: the stamp's double border (white art) inked gold
	_ring = Panel.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.add_theme_stylebox_override("panel", load("uid://cov6qnc1bx421"))  # MobileHall/Styles/stamp.tres
	HallStyle.tint_art(_ring, RING_COLOR)
	add_child(_ring)

	_pointer = Pointer.new()
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.custom_minimum_size = Vector2(72, 72)
	_pointer.arrow = ARROW_ICON
	_pointer.tint = RING_COLOR
	add_child(_pointer)

	# Pip's bubble is a parchment card, like every other card in the hall
	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	HallStyle.set_look(_bubble, &"PaperCard")
	add_child(_bubble)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_bubble.add_child(row)

	var face_col := VBoxContainer.new()
	face_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face_col.add_theme_constant_override("separation", 2)
	row.add_child(face_col)
	_face = _build_portrait()
	_face.gui_input.connect(_on_face_input)
	face_col.add_child(_face)
	_hint = Label.new()
	_hint.theme_type_variation = &"ItalicLabel"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint.custom_minimum_size.x = 84
	_hint.add_theme_font_size_override("font_size", 19)
	face_col.add_child(_hint)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var name_label := Label.new()
	name_label.text = "Pip · Guild Clerk"
	name_label.theme_type_variation = &"TitleLabel"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 32)
	head.add_child(name_label)
	_counter = Label.new()
	_counter.theme_type_variation = &"CapsLabel"
	_counter.uppercase = true
	_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_counter.add_theme_font_size_override("font_size", 20)
	head.add_child(_counter)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 25)
	_text.add_theme_font_size_override("bold_font_size", 25)
	_text.add_theme_color_override("default_color", HallStyle.TEXT_MAIN)
	col.add_child(_text)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	col.add_child(foot)
	_do_label = Label.new()
	_do_label.theme_type_variation = &"CapsLabel"
	_do_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_do_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_do_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_do_label.add_theme_font_size_override("font_size", 22)
	HallStyle.set_font_color(_do_label, HallStyle.BLUE_TEXT)
	# the instruction takes all the room left of Skip / Next, so it doesn't wrap early
	foot.add_child(_do_label)
	_skip_button = Button.new()
	_skip_button.text = "Skip tutorial"
	_skip_button.flat = true
	_skip_button.add_theme_font_override("font", load("uid://dvhjw1533s75"))  # MobileHall/Art/Fonts/font_italic.tres
	_skip_button.add_theme_font_size_override("font_size", 22)
	_skip_button.add_theme_color_override("font_color", HallStyle.TEXT_SOFT)
	_skip_button.pressed.connect(skip_tutorial)
	foot.add_child(_skip_button)
	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.custom_minimum_size = Vector2(110, 64)
	HallStyle.style_button(_back_button, "paper", 28)
	_back_button.pressed.connect(_go_back)
	foot.add_child(_back_button)
	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.custom_minimum_size = Vector2(120, 64)
	HallStyle.style_button(_next_button, "gold", 28)
	_next_button.pressed.connect(_advance)
	foot.add_child(_next_button)


## Pip's portrait: the round portrait mask (parchment ground; its shape clips
## Pip through HallStyle.mask_to) and
## the round portrait frame on top, the same art as the heroes' portraits.
func _build_portrait() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(84, 84)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var mask := TextureRect.new()
	mask.texture = PORTRAIT_MASK
	mask.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	HallStyle.tint_art(mask, PIP_GROUND)
	holder.add_child(mask)
	var pip := PipFace.new()
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mask.add_child(pip)
	# clipped by the portrait mask shader, not clip_children (broken on iPhone
	# Safari); Pip fills the mask, so the mask's rect is Pip's own rect
	pip.resized.connect(func() -> void: HallStyle.mask_to(pip, PORTRAIT_MASK, Rect2(Vector2.ZERO, pip.size)))
	HallStyle.mask_to(pip, PORTRAIT_MASK, Rect2(Vector2.ZERO, pip.size))
	var frame := TextureRect.new()
	frame.texture = PORTRAIT_FRAME
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(frame)
	return holder


## The pixel arrow icon (it points left in the art), turned to point down or
## up at the spotlight and tinted gold.
class Pointer extends Control:
	var points_down := true
	## The arrow art and its tint (set by _build).
	var arrow: Texture2D
	var tint := Color.WHITE

	func _draw() -> void:
		if arrow == null:
			return
		# rotate about the centre: left -> down is -90 degrees, left -> up is +90
		var angle := -PI / 2.0 if points_down else PI / 2.0
		draw_set_transform(size / 2.0, angle, Vector2.ONE)
		draw_texture_rect(arrow, Rect2(-size / 2.0, size), false, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Pip: a goblin clerk with round glasses, drawn with shapes (no art asset yet;
## the round portrait mask and frame around it are the project's art).
class PipFace extends Control:
	func _draw() -> void:
		var s := size.x / 50.0
		var ink := Color("#2A1A10")
		var skin := Color("#7BC47F")
		var body := StyleBoxFlat.new()
		body.bg_color = Color("#9B72CF")
		body.set_border_width_all(int(2.5 * s))
		body.border_color = ink
		body.set_corner_radius_all(int(9 * s))
		draw_style_box(body, Rect2(Vector2(11, 38) * s, Vector2(28, 11) * s))
		for side in [-1, 1]:
			var ear := PackedVector2Array([Vector2(25 + 11 * side, 25) * s, Vector2(25 + 23 * side, 16) * s, Vector2(25 + 12 * side, 33) * s])
			draw_colored_polygon(ear, skin)
			ear.append(ear[0])
			draw_polyline(ear, ink, 2.5 * s)
		var head := Vector2(25, 28) * s
		draw_circle(head, 12 * s, skin)
		draw_arc(head, 12 * s, 0, TAU, 40, ink, 2.5 * s)
		for side in [-1, 1]:
			var lens := Vector2(25 + 4.5 * side, 27) * s
			draw_circle(lens, 4.2 * s, Color("#FFFBF0"))
			draw_arc(lens, 4.2 * s, 0, TAU, 24, ink, 2 * s)
			draw_circle(lens, 1.5 * s, ink)
		draw_arc(Vector2(25, 32.5) * s, 3 * s, 0.3, PI - 0.3, 12, ink, 2 * s)

# ============================================================ FINDING TARGETS

func _tab(tab_id: String) -> Node:
	return hall._tabs[tab_id]


func _screen(kind: String) -> Node:
	return hall._screens[kind]


func _nav(tab_id: String) -> Control:
	return hall.nav_button(tab_id)


## A scene-unique node (%Name) inside `node`'s scene.
func _u(node: Node, unique_name: String) -> Control:
	if node == null:
		return null
	return node.get_node_or_null("%" + unique_name) as Control


## First visible row under `root` built from `script_file` (e.g. "hire_card.gd"),
## or its %`unique_child`, that passes `filter`.
func _row(root: Node, script_file: String, unique_child := "", filter := Callable()) -> Control:
	if root == null:
		return null
	var queue: Array = [root]
	while not queue.is_empty():
		var node: Node = queue.pop_front()
		var script = node.get_script()
		if script is Script and (script as Script).resource_path.get_file() == script_file and node is Control and (node as Control).is_visible_in_tree():
			var hit: Control = node if unique_child == "" else _u(node, unique_child)
			if hit != null and hit.is_visible_in_tree() and (not filter.is_valid() or filter.call(hit)):
				return hit
		queue.append_array(node.get_children())
	return null


## The report's Quests won / Gold / Hurt chips row.
func _report_totals() -> Control:
	var chip := _u(hall.get_node("%OverlayReport"), "WinsChip")
	return chip.get_parent() as Control if chip != null else null


func _training_section() -> Node:
	return _u(_tab("upgrades"), "TrainingSection")


func _hospital_section() -> Node:
	return _u(_tab("upgrades"), "HospitalSection")

# ============================================================ CONDITIONS

## Day 1's party is "ready" with two heroes, or fewer if the quest or roster is smaller.
func _party_ready(entry: Dictionary) -> bool:
	var wanted: int = mini(mini(2, hall.party_size_limit(entry)), hall.roster().size())
	return entry.party.size() >= maxi(wanted, 1)


func _pick_text() -> String:
	var entry: Dictionary = hall.current_quest_entry()
	if not entry.is_empty() and hall.party_size_limit(entry) == 1:
		return "One hero only. Each row's number is the chance they add."
	return "Tap heroes to add them. Each row's number is the chance they add."


## The Assign Party odds step: risk vs. reward. A win at good odds trains the
## quest's or region's stat; a riskier win grows Pluck instead. The threshold is
## the open quest's (HallRules.train_odds_for, an F quest's if none is open),
## and the Pluck numbers and odds word come from HallRules.PLUCK_GAIN_BY_ODDS
## and HallStyle.ODDS_BANDS, so the text follows the tuning.
func _odds_text() -> String:
	var entry: Dictionary = hall.current_quest_entry()
	var rank: int = entry.quest.difficulty if not entry.is_empty() else 0
	var riskiest: Dictionary = HallRules.PLUCK_GAIN_BY_ODDS[-1]
	var riskiest_word: String = HallStyle.odds_look(riskiest.min).word
	return "Win at %d%%+ to train the quest's or region's stat. Riskier wins grow %s instead, up to +%d on a %s." \
			% [HallRules.train_odds_for(rank), PLK, riskiest.gain, riskiest_word]


func _anyone_can_train() -> bool:
	return hall.roster().any(func(character):
		return not GuildUpgrades.is_training(character) and GuildUpgrades.can_train(character))


func _any_affordable() -> bool:
	for index in ItemShop.stock.size():
		if ItemShop.can_buy(index):
			return true
	return false


func _bought_role() -> String:
	return HallStyle.item_role_name(_bought_item) if _bought_item != null else ""


func _bought_name() -> String:
	return HallStyle.item_look(_bought_item).name if _bought_item != null else "item"


func _fits_bought(character: Variant) -> bool:
	return character is GuildCharacter and _bought_item != null and HallStyle.role_name(character) == _bought_role()


func _someone_fits_bought() -> bool:
	return hall.roster().any(func(character): return _fits_bought(character) and not HallStyle.is_dead(character))

# ============================================================ THE SCRIPT

func _steps_for(script: int) -> Array:
	match script:
		1:
			return _day_one()
		2:
			return _day_two()
		3:
			return _day_three()
		5:
			return _day_five()
		FREEPLAY_SCRIPT:
			return _freeplay()
	return []


func _day_one() -> Array:
	return [
		{"text": "Welcome, Guildmaster! I'm [b]Pip[/b], your clerk. Tap whatever glows."},
		{"target": func(): return _nav("guild"), "on": "tab", "when": func(d): return d.tab == "guild",
			"do": "Tap Members", "text": "First, heroes. Open [b]Members[/b]."},
		{"target": func(): return _u(_tab("guild"), "SegHire"), "on": "tab", "when": func(d): return d.guild == "hire",
			"skip": func(): return hall.guild_section == "hire",
			"do": "Tap Applicants", "text": "Open [b]Applicants[/b]."},
		{"target": func(): return _row(_tab("guild"), "hire_card.gd"),
			"text": "Recruits have four stats: %s, %s, %s and %s." % [POW, DEF, WIS, SLZ]},
		{"target": func(): return _row(_tab("guild"), "hire_card.gd", "HireButton"), "on": "hire",
			"do": "Tap Hire", "deny": ["DetailsButton"], "text": "Hiring is free for two days. Hire one."},
		# the applicants are a stack of letters (%Stack): the next one is on top now
		{"target": func(): return _row(_tab("guild"), "hire_card.gd", "HireButton"), "on": "hire",
			"skip": func(): return not hall.can_hire_anyone(),
			"do": "Tap Hire", "deny": ["DetailsButton"], "text": "And one more. Two heroes beat one."},
		{"target": func(): return _nav("board"), "on": "tab", "when": func(d): return d.tab == "board",
			"do": "Tap Board", "text": "Now find them work. Open the [b]Board[/b]."},
		{"target": func(): return _row(_tab("board"), "quest_row.gd"), "on": "assign",
			"do": "Tap the quest card", "text": "A quest: its rank, %s, party size and favoured stat. Tap it." % GOLD},
		{"target": func(): return _u(_screen("assign"), "PickList"), "on": "pick", "when": func(d): return _party_ready(d),
			"do": "Tap a hero row to add them", "deny": ["InfoButton"], "text": func(): return _pick_text()},
		{"target": func(): return _u(_screen("assign"), "PartyBox"),
			"text": "Your odds. Low odds risk failure and injuries."},
		{"target": func(): return _u(_screen("assign"), "RightButton"), "on": "send",
			"do": "Tap Seal & send", "text": "Send them. They leave tonight."},
		{"target": func(): return hall.action_button(), "on": "end_check",
			"do": "Tap End Day", "text": "This bar always shows your next step. Tap [b]End Day[/b]."},
		{"target": func(): return _u(hall.get_node("%OverlayEndDay"), "EndButton"), "on": "end_day",
			"do": "Tap End Day", "text": "Confirm tonight's plan."},
		{"target": func(): return _u(hall.get_node("%OverlayReport"), "Entries"),
			"text": "Morning! Here's how each party did."},
		{"target": func(): return _report_totals(),
			"text": "Wins, %s earned, and who got hurt." % GOLD},
		{"target": func(): return _u(hall.get_node("%OverlayReport"), "ActionButton"), "on": "new_day",
			"do": "Tap to start Day 2", "text": "On to Day 2."},
	]


func _day_two() -> Array:
	return [
		{"target": func(): return _nav("guild"), "on": "tab", "when": func(d): return d.tab == "guild",
			"do": "Tap Members", "text": "Day 2! Let's meet your heroes. Open [b]Members[/b]."},
		{"target": func(): return _u(_tab("guild"), "SegRoster"), "on": "tab", "when": func(d): return d.guild == "roster",
			"skip": func(): return hall.guild_section == "roster",
			"do": "Tap Your Guild", "text": "Open [b]Your Guild[/b]."},
		{"target": func(): return _row(_tab("guild"), "member_card.gd"), "on": "character",
			"do": "Tap a hero", "text": "Tap a hero to open their page."},
		{"target": func(): return _u(_screen("character"), "StatLines"),
			"text": "Quests lean on the favoured stat. Safe wins train a stat; risky wins grow %s, which boosts every other stat." % PLK},
		{"target": func(): return _u(_screen("character"), "GearLines"),
			"text": "Gear slots. Items are role-locked. The Shop opens on Day 5."},
		{"target": func(): return _u(_screen("character"), "BackButton"), "on": "close",
			"do": "Tap Back", "text": "Head back."},
		{"target": func(): return _nav("board"), "on": "tab", "when": func(d): return d.tab == "board",
			"do": "Tap Board", "text": "Open the [b]Board[/b]."},
		{"target": func(): return _row(_tab("board"), "quest_row.gd"), "on": "assign",
			"do": "Tap a quest card", "text": "Open a quest."},
		{"target": func(): return _u(_screen("assign"), "PartyBox"),
			"text": func(): return _odds_text()},
		{"target": func(): return _u(_screen("assign"), "LeftButton"),
			"text": "[b]Deny[/b] skips a quest for a little standing. You can Reconsider later today."},
		{"text": "Heroes can [b]die[/b]. Lose them all with no gold to hire, and the guild falls. The rest of today is yours. See you on Day 3!"},
	]


func _day_three() -> Array:
	return [
		{"target": func(): return _nav("upgrades"), "on": "tab", "when": func(d): return d.tab == "upgrades",
			"do": "Tap Guild", "text": "Day 3! The [b]Guild[/b] tab is open. Take a look."},
		{"target": func(): return _u(_tab("upgrades"), "SegBuild"), "on": "tab", "when": func(d): return d.upgrades == "build",
			"skip": func(): return hall.upgrades_section == "build",
			"do": "Tap Build", "text": "Open [b]Build[/b]."},
		{"target": func(): return _row(_tab("upgrades"), "upgrade_card.gd"),
			"text": "Buildings have five levels. Upgrades cost %s and standing." % GOLD},
		{"target": func(): return _row(_tab("upgrades"), "upgrade_card.gd", "UpgradeButton", func(b): return _is_enabled(b)), "on": "upgrade",
			"skip": func(): return hall.affordable_buildings().is_empty(),
			"do": "Tap Build", "text": "You can afford this one. Build it."},
		{"target": func(): return _u(_tab("upgrades"), "Wallet"),
			"skip": func(): return _seen.get("upgrade", false),
			"text": "Not enough yet. A badge on the tab shows when you can."},
		{"target": func(): return _u(_tab("upgrades"), "SegTonight"), "on": "tab", "when": func(d): return d.upgrades == "tonight",
			"do": "Tap Tonight", "text": "Now [b]Tonight[/b]: who stays home."},
		{"target": func(): return _training_section(),
			"text": "[b]Training Yard[/b]: a hero drills one stat overnight."},
		{"target": func(): return _u(_training_section(), "AddButton"), "on": "training_picker",
			"skip": func(): return not GuildUpgrades.has_free_training_slot() or not _anyone_can_train(),
			"do": "Tap Add a hero", "text": "Pick a trainee."},
		{"target": func(): return _row(_training_section(), "home_row.gd", "MainButton", func(b): return _is_enabled(b)), "on": "train",
			"skip": func(): return not hall.training_picker_open,
			"do": "Tap Add next to a hero", "deny": ["SideButton"], "text": "Choose someone free today."},
		{"target": func(): return _row(_training_section(), "home_row.gd", "StatPicker"), "tap": true,
			"skip": func(): return not _seen.get("train", false),
			"do": "Tap a stat, then Next", "text": "Pick the stat to drill."},
		{"target": func(): return _hospital_section(),
			"text": "[b]Hospital[/b]: hurt heroes heal faster in a bed than at home."},
		{"target": func(): return _row(_hospital_section(), "home_row.gd", "MainButton", func(b): return b.text.contains("dmit")), "on": "admit",
			"skip": func(): return hall.hurt_waiting_count() == 0,
			"do": "Tap Admit", "text": "Someone's hurt. [b]Admit[/b] them."},
		{"text": "Heroes training or in bed [b]can't quest[/b]. Choose who works, rests and goes out. Back on Day 5!"},
	]


func _day_five() -> Array:
	return [
		{"target": func(): return _nav("shop"), "on": "tab", "when": func(d): return d.tab == "shop",
			"do": "Tap Shop", "text": "Day 5. A merchant's in town! Open the [b]Shop[/b]."},
		{"target": func(): return _tab("shop").get_node_or_null("Keeper"),
			"text": "Stock changes every morning. Unbought items are gone."},
		{"target": func(): return _u(_tab("shop"), "Grid"), "tap": true,
			"skip": func(): return not _any_affordable(),
			"do": "Tap items to compare, then Next", "text": "Items are role-locked. Tap one to see what it does and who can use it."},
		{"target": func(): return _u(_tab("shop"), "BuyButton"), "on": "buy",
			"skip": func(): return not _any_affordable(),
			"do": "Tap Buy", "text": "Buy it."},
		{"target": func(): return _u(_tab("shop"), "Grid"),
			"skip": func(): return _seen.get("buy", false),
			"text": "Nothing affordable yet. Earn %s and check back tomorrow." % GOLD},
		{"target": func(): return _nav("guild"), "on": "tab", "when": func(d): return d.tab == "guild",
			"skip": func(): return not _seen.get("buy", false) or not _someone_fits_bought(),
			"do": "Tap Members", "text": "Gear goes on from a hero's page. Open [b]Members[/b]."},
		{"target": func(): return _u(_tab("guild"), "SegRoster"), "on": "tab", "when": func(d): return d.guild == "roster",
			"skip": func(): return not _seen.get("buy", false) or not _someone_fits_bought() or hall.guild_section == "roster",
			"do": "Tap Your Guild", "text": "Open [b]Your Guild[/b]."},
		{"target": func(): return _u(_tab("guild"), "List"), "tap": true, "on": "character", "when": func(d): return _fits_bought(d),
			"reject": func(): return "Only %ss can use the %s." % [_bought_role(), _bought_name()],
			"skip": func(): return not _seen.get("buy", false) or not _someone_fits_bought(),
			"do": "Tap a hero with the right role", "text": func(): return "Open a [b]%s[/b]." % _bought_role()},
		{"target": func(): return _u(_screen("character"), "GearLines"), "tap": true, "on": "equip",
			"skip": func(): return not _seen.get("buy", false) or not _someone_fits_bought(),
			"do": "Tap Equip, then the item", "deny": ["SideButton"], "text": func(): return "Tap [b]Equip[/b], then the %s." % _bought_name()},
		{"target": func(): return _u(_screen("character"), "StatLines"),
			"skip": func(): return not _seen.get("equip", false),
			"text": "Its bonus now counts on every quest."},
		{"text": func(): return ("Hire a %s to use that gear." % _bought_role()) if (_seen.get("buy", false) and not _someone_fits_bought()) else "That's everything! More help is under Menu > How to play. Good luck, Guildmaster."},
	]


## After the final battle is won: what freeplay changes.
func _freeplay() -> Array:
	return [
		{"text": "You did it, Guildmaster! The story's done, but the guild stays open: welcome to [b]freeplay[/b]."},
		{"text": "Days never end now. Quests get harder each day, and pay more %s." % GOLD},
		{"target": func(): return _row(_tab("board"), "quest_row.gd", "RankChip"),
			"text": "Quests can now pass S rank, up to [b]S++[/b]."},
		{"text": "Lose every hero with no gold to hire, and the guild still falls. How long can you last?"},
	]
