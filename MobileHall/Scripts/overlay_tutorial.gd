## Tutorial coach: Pip the guild clerk walks a new player through the real
## Mobile Hall UI on Days 1, 3 and 5. Each step spotlights one control and
## waits for the player to use it (or press Next on explain-only steps), so
## the player learns by doing instead of reading an intro screen.
##   Day 1 - hiring, a hero's page (stats, gear), reading a quest, picking a
##           party, odds, Deny vs Send, End Day, the Day Report
##   Day 3 - the Guild tab: upgrading a building, the Training Yard, the
##           Hospital, and why posted heroes can't quest
##   Day 5 - the Shop: role-locked items, buying, equipping from a hero's page
##
## Built in code; hall_main._ready adds it on top of every overlay.
## UI only: it calls nothing but hall_main's own actions and queries.
##
## WHAT THE PLAYER SEES
##   - everything outside the spotlight is greyed out (desaturated + dimmed)
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
##     end_day, new_day, upgrade, training_picker, train, admit, buy, equip
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
extends Control

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

## Off = no coach, no tab locks, and the old Welcome card shows instead.
const ENABLED := true
const TUTORIAL_DAYS := [1, 3, 5]
const UNLOCK_DAY := {"upgrades": 3, "shop": 5}

const RING_COLOR := Color("#F6B93B")
const INK := Color("#2A1A10")
const HOLE_PAD := 10.0
const BUBBLE_MARGIN := 16.0
## Gap kept between Pip's bubble and the spotlight.
const BUBBLE_CLEARANCE := 24.0
## Seconds a step's target may be missing before Next shows up.
const MISSING_GRACE := 0.6
## How often (seconds) buttons outside the spotlight are re-disabled,
## since the hall rebuilds rows on every refresh.
const LOCK_INTERVAL := 0.1

## Grey-out for everything outside the spotlight.
const GREY_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float darken = 0.35;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(g) * (1.0 - darken), 1.0);
}
"""

# ---- coloured words (match Style.STATS)
const POW := "[color=#A3262A]Power[/color]"
const DEF := "[color=#2F5F8A]Defense[/color]"
const WIS := "[color=#5B3F8C]Wisdom[/color]"
const SLZ := "[color=#3E6B35]Sleaziness[/color]"
const PLK := "[color=#94500F]Pluck[/color]"
const GOLD := "[color=#7A5A12]gold[/color]"

## The main hall script (untyped: hall_main preloads this file).
var hall: Control
## True once the player taps Skip tutorial (also lifts the tab locks).
var is_skipped := false
## Tutorial days already finished or skipped.
var done := {}

var _day := 0
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

# ---- nodes (built in _build)
var _blockers: Array[ColorRect] = []
var _cover: Control
var _ring: Panel
var _pointer: Pointer
var _bubble: PanelContainer
var _face: PipFace
var _counter: Label
var _text: RichTextLabel
var _do_label: Label
var _hint: Label
var _next_button: Button
var _skip_button: Button


# ============================================================ SETUP

func setup(main: Control) -> void:
	hall = main
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false
	set_process(false)
	hall.tutorial_event.connect(_on_event)
	if ENABLED and GameState.day == 1:
		hall.is_welcome_open = false
		start.call_deferred(1)


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

func start(day: int) -> void:
	_day = day
	_steps = _steps_for(day)
	_seen = {}
	_index = -1
	visible = true
	set_process(true)
	_bubble.position = Vector2(BUBBLE_MARGIN, size.y)
	_advance()


func _advance() -> void:
	_index += 1
	while _index < _steps.size() and _steps[_index].has("skip") and _steps[_index]["skip"].call():
		_index += 1
	_missing_for = 0.0
	_last_target = null
	_shown_text = ""
	_dock_forced = false
	_expanded = false
	_lock_timer = 0.0
	if _index >= _steps.size():
		_finish()


func _finish() -> void:
	done[_day] = true
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
	if not is_running():
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
	return step.has("on") or step.get("tap", false)

# ============================================================ BUTTON LOCKS

## Disable every button in the hall except the ones inside a live spotlight.
## (Rows that are tap panels, not Buttons, are stopped by the grey blockers.)
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
	var waits: bool = step.has("on")
	var is_lost: bool = step.get("target") != null and target == null and _missing_for > MISSING_GRACE
	var show_next: bool = not waits or is_lost

	# ---- the spotlight hole and the grey-out around it
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
	# explain-only steps cover the hole too (no grey, just no taps)
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
	if is_lost:
		do_text = ""
	elif do_text == "" and waits:
		do_text = "Tap the glowing spot"
	elif do_text == "" and step.get("tap", false):
		do_text = "Try it, then tap Next"
	_do_label.text = ("▶  " + do_text.to_upper()) if do_text != "" else ""
	_do_label.visible = do_text != ""
	_next_button.visible = show_next
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
	var grey := ShaderMaterial.new()
	grey.shader = Shader.new()
	grey.shader.code = GREY_SHADER
	for blocker_index in 4:
		var blocker := ColorRect.new()
		blocker.material = grey
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		blocker.gui_input.connect(_on_blocked_input)
		add_child(blocker)
		_blockers.append(blocker)

	_cover = Control.new()
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_cover.gui_input.connect(_on_blocked_input)
	add_child(_cover)

	_ring = Panel.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring_box := StyleBoxFlat.new()
	ring_box.draw_center = false
	ring_box.set_border_width_all(6)
	ring_box.border_color = RING_COLOR
	ring_box.set_corner_radius_all(18)
	_ring.add_theme_stylebox_override("panel", ring_box)
	add_child(_ring)

	_pointer = Pointer.new()
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.custom_minimum_size = Vector2(84, 70)
	add_child(_pointer)

	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	Style.style_panel(_bubble, Style.CARD_BG, INK, 4, 22, Vector4(16, 14, 16, 14))
	add_child(_bubble)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_bubble.add_child(row)

	var face_col := VBoxContainer.new()
	face_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face_col.add_theme_constant_override("separation", 2)
	row.add_child(face_col)
	_face = PipFace.new()
	_face.custom_minimum_size = Vector2(84, 84)
	_face.mouse_filter = Control.MOUSE_FILTER_STOP
	_face.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_face.gui_input.connect(_on_face_input)
	face_col.add_child(_face)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint.custom_minimum_size.x = 84
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Style.TEXT_SOFT)
	face_col.add_child(_hint)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var name_label := Label.new()
	name_label.text = "Pip · Guild Clerk"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Style.TEXT_MAIN)
	head.add_child(name_label)
	_counter = Label.new()
	_counter.add_theme_font_size_override("font_size", 19)
	_counter.add_theme_color_override("font_color", Style.TEXT_SOFT)
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
	_text.add_theme_color_override("default_color", Style.TEXT_MAIN)
	col.add_child(_text)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	col.add_child(foot)
	_do_label = Label.new()
	_do_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_do_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_do_label.add_theme_font_size_override("font_size", 22)
	_do_label.add_theme_color_override("font_color", Style.BLUE_TEXT)
	foot.add_child(_do_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(spacer)
	_skip_button = Button.new()
	_skip_button.text = "Skip tutorial"
	_skip_button.flat = true
	_skip_button.add_theme_font_size_override("font_size", 19)
	_skip_button.add_theme_color_override("font_color", Style.TEXT_SOFT)
	_skip_button.pressed.connect(skip_tutorial)
	foot.add_child(_skip_button)
	_next_button = Button.new()
	_next_button.text = "Next"
	Style.style_button(_next_button, "green", 26)
	_next_button.pressed.connect(_advance)
	foot.add_child(_next_button)


## Gold arrow with "TAP" on it, pointing at the spotlight.
class Pointer extends Control:
	var points_down := true

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var ink := Color("#2A1A10")
		var gold := Color("#F6B93B")
		var shaft_w := w * 0.42
		var head_h := h * 0.45
		var pts: PackedVector2Array
		if points_down:
			pts = PackedVector2Array([Vector2((w - shaft_w) / 2, 0), Vector2((w + shaft_w) / 2, 0), Vector2((w + shaft_w) / 2, h - head_h), Vector2(w, h - head_h), Vector2(w / 2, h), Vector2(0, h - head_h), Vector2((w - shaft_w) / 2, h - head_h)])
		else:
			pts = PackedVector2Array([Vector2((w - shaft_w) / 2, h), Vector2((w + shaft_w) / 2, h), Vector2((w + shaft_w) / 2, head_h), Vector2(w, head_h), Vector2(w / 2, 0), Vector2(0, head_h), Vector2((w - shaft_w) / 2, head_h)])
		draw_colored_polygon(pts, gold)
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, ink, 4.0)


## Pip: a goblin clerk with round glasses, drawn with shapes (no art asset).
class PipFace extends Control:
	func _draw() -> void:
		var s := size.x / 50.0
		var ink := Color("#2A1A10")
		var skin := Color("#7BC47F")
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("#FCE6B0")
		bg.set_corner_radius_all(int(10 * s))
		draw_style_box(bg, Rect2(Vector2.ZERO, size))
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
		var border := StyleBoxFlat.new()
		border.draw_center = false
		border.set_border_width_all(int(3 * s))
		border.border_color = ink
		border.set_corner_radius_all(int(10 * s))
		draw_style_box(border, Rect2(Vector2.ZERO, size))

# ============================================================ FINDING TARGETS

func _tab(tab_id: String) -> Node:
	return hall._tabs[tab_id]


func _screen(kind: String) -> Node:
	return hall._screens[kind]


func _nav(tab_id: String) -> Control:
	return hall._nav_button(tab_id)


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
		return "This quest takes one hero. The number on each row is how much chance they add, so tap the best fit."
	return "Tap heroes to put them in the party. The number on each row is how much chance that hero adds."


func _anyone_can_train() -> bool:
	return hall.roster().any(func(character):
		return not GuildUpgrades.is_training(character) and GuildUpgrades.can_train(character))


func _any_affordable() -> bool:
	for index in ItemShop.stock.size():
		if ItemShop.can_buy(index):
			return true
	return false


func _bought_role() -> String:
	return Style.item_role_name(_bought_item) if _bought_item != null else ""


func _bought_name() -> String:
	return Style.item_look(_bought_item).name if _bought_item != null else "item"


func _fits_bought(character: Variant) -> bool:
	return character is GuildCharacter and _bought_item != null and Style.role_name(character) == _bought_role()


func _someone_fits_bought() -> bool:
	return hall.roster().any(func(character): return _fits_bought(character) and not Style.is_dead(character))

# ============================================================ THE SCRIPT

func _steps_for(day: int) -> Array:
	match day:
		1:
			return _day_one()
		3:
			return _day_three()
		5:
			return _day_five()
	return []


func _day_one() -> Array:
	return [
		{"text": "Welcome to your new guild, Guildmaster! I'm [b]Pip[/b], your clerk. Let's run your first day together. Tap each glowing spot as I point it out."},
		{"target": func(): return _nav("guild"), "on": "tab", "when": func(d): return d.tab == "guild",
			"do": "Tap Members", "text": "A guild is only as good as its adventurers. Open [b]Members[/b]."},
		{"target": func(): return _u(_tab("guild"), "SegHire"), "on": "tab", "when": func(d): return d.guild == "hire",
			"skip": func(): return hall.guild_section == "hire",
			"do": "Tap For Hire", "text": "Nobody works here yet. Open [b]For Hire[/b] to see today's recruits."},
		{"target": func(): return _row(_tab("guild"), "hire_card.gd"),
			"text": "Each recruit has a role and four stats: %s, %s, %s and %s. Every quest favours one of them." % [POW, DEF, WIS, SLZ]},
		{"target": func(): return _row(_tab("guild"), "hire_card.gd", "HireButton"), "on": "hire",
			"do": "Tap Hire", "deny": ["DetailsButton"], "text": "Hiring is free for your first two days. Hire this one."},
		{"target": func(): return _u(_tab("guild"), "List"), "on": "hire", "tap": true,
			"skip": func(): return not hall.can_hire_anyone(),
			"do": "Tap Hire on another recruit", "deny": ["DetailsButton"], "text": "Hire one more. Two heroes means better odds, and a backup when someone gets hurt."},
		{"target": func(): return _u(_tab("guild"), "SegRoster"), "on": "tab", "when": func(d): return d.guild == "roster",
			"do": "Tap Your Guild", "text": "Now meet your people. Open [b]Your Guild[/b]."},
		{"target": func(): return _row(_tab("guild"), "member_card.gd"), "on": "character",
			"do": "Tap the hero card", "text": "Tap a hero to open their page."},
		{"target": func(): return _u(_screen("character"), "StatLines"),
			"text": "Their stats. Quests lean hardest on the favoured stat. %s goes up by one every time they finish a quest." % PLK},
		{"target": func(): return _u(_screen("character"), "GearLines"),
			"text": "Gear slots. Items are role-locked, so only some gear fits each hero. The Shop opens on Day 5."},
		{"target": func(): return _u(_screen("character"), "BackButton"), "on": "close",
			"do": "Tap Back", "text": "Head back."},
		{"target": func(): return _nav("board"), "on": "tab", "when": func(d): return d.tab == "board",
			"do": "Tap Board", "text": "Time to find them work. Open the [b]Board[/b]."},
		{"target": func(): return _row(_tab("board"), "quest_row.gd"),
			"text": "Each card is a job: its rank, the %s it pays, how many heroes it takes, and the stat it favours." % GOLD},
		{"target": func(): return _row(_tab("board"), "quest_row.gd"), "on": "assign",
			"do": "Tap the quest card", "text": "Tap the quest to plan a party."},
		{"target": func(): return _u(_screen("assign"), "QuestCard"),
			"text": "The full posting. Check the favoured stat before you pick anyone."},
		{"target": func(): return _u(_screen("assign"), "PickList"), "on": "pick", "when": func(d): return _party_ready(d),
			"do": "Tap a hero row to add them", "deny": ["InfoButton"], "text": func(): return _pick_text()},
		{"target": func(): return _u(_screen("assign"), "PartyBox"),
			"text": "Your party and its success chance. Low odds mean failure and injuries. Swap heroes in and out until it looks right."},
		{"target": func(): return _u(_screen("assign"), "LeftButton"),
			"text": "[b]Deny[/b] turns a quest down. It costs a little standing, and you can Reconsider later the same day. This one's worth taking."},
		{"target": func(): return _u(_screen("assign"), "RightButton"), "on": "send",
			"do": "Tap Send Party", "text": "Send the party. They head out tonight."},
		{"target": func(): return hall.get_node("%ActionButton"), "on": "end_check",
			"do": "Tap End Day", "text": "Every quest is decided. This bar always shows your next step. Tap [b]End Day[/b]."},
		{"target": func(): return _u(hall.get_node("%OverlayEndDay"), "EndButton"), "on": "end_day",
			"do": "Tap End Day", "text": "A last look at tonight's plan. End the day."},
		{"target": func(): return _u(hall.get_node("%OverlayReport"), "Entries"),
			"text": "Morning! Each party tells you what happened out there."},
		{"target": func(): return _report_totals(),
			"text": "The tally: quests won, %s earned, and who came back hurt. Hurt heroes heal at home, or faster in the Hospital." % GOLD},
		{"target": func(): return _u(hall.get_node("%OverlayReport"), "ActionButton"), "on": "new_day",
			"do": "Tap the button to start Day 2", "text": "Start Day 2. New recruits and quests show up every morning."},
		{"text": "Day 2 is yours: hire, plan, send, end the day. I'll be back on Day 3 to show you the guild's buildings."},
	]


func _day_three() -> Array:
	return [
		{"text": "Day 3! Time to work on the guild itself. The [b]Guild[/b] tab is open now."},
		{"target": func(): return _nav("upgrades"), "on": "tab", "when": func(d): return d.tab == "upgrades",
			"do": "Tap Guild", "text": "Open [b]Guild[/b]."},
		{"target": func(): return _u(_tab("upgrades"), "SegBuild"), "on": "tab", "when": func(d): return d.upgrades == "build",
			"skip": func(): return hall.upgrades_section == "build",
			"do": "Tap Build", "text": "Start with [b]Build[/b]."},
		{"target": func(): return _row(_tab("upgrades"), "upgrade_card.gd"),
			"text": "Each building has five levels. Upgrades cost %s and need enough standing. A card shows what you have now and what the next level adds." % GOLD},
		{"target": func(): return _row(_tab("upgrades"), "upgrade_card.gd", "UpgradeButton", func(b): return _is_enabled(b)), "on": "upgrade",
			"skip": func(): return hall.affordable_buildings().is_empty(),
			"do": "Tap Upgrade", "text": "You can afford this one. Upgrade it."},
		{"target": func(): return _u(_tab("upgrades"), "Wallet"),
			"skip": func(): return _seen.get("upgrade", false),
			"text": "Not enough yet. When you can afford an upgrade, a number shows up on the Guild tab."},
		{"target": func(): return _u(_tab("upgrades"), "SegTonight"), "on": "tab", "when": func(d): return d.upgrades == "tonight",
			"do": "Tap Tonight", "text": "Now [b]Tonight[/b]. This is where heroes stay home and work."},
		{"target": func(): return _training_section(),
			"text": "The [b]Training Yard[/b]: a hero who stays home drills one stat overnight."},
		{"target": func(): return _u(_training_section(), "AddButton"), "on": "training_picker",
			"skip": func(): return not GuildUpgrades.has_free_training_slot() or not _anyone_can_train(),
			"do": "Tap Add a hero", "text": "Tap the button to pick a trainee."},
		{"target": func(): return _row(_training_section(), "home_row.gd", "MainButton", func(b): return _is_enabled(b)), "on": "train",
			"skip": func(): return not hall.training_picker_open,
			"do": "Tap Add next to a hero", "deny": ["SideButton"], "text": "Pick someone who's free today."},
		{"target": func(): return _row(_training_section(), "home_row.gd", "StatPicker"), "tap": true,
			"skip": func(): return not _seen.get("train", false),
			"do": "Tap a stat, then Next", "text": "Choose which stat they drill: %s, %s, %s or %s." % [POW, DEF, WIS, SLZ]},
		{"target": func(): return _hospital_section(),
			"text": "The [b]Hospital[/b]: a hurt hero in a bed heals faster than at home. Each card shows nights at home against nights in bed."},
		{"target": func(): return _row(_hospital_section(), "home_row.gd", "MainButton", func(b): return b.text.contains("dmit")), "on": "admit",
			"skip": func(): return hall.hurt_waiting_count() == 0,
			"do": "Tap Admit", "text": "Someone's hurt. Tap [b]Admit[/b] to give them a bed."},
		{"text": "One rule to remember: heroes who are training or in a bed [b]can't go on quests[/b]. Each day, choose who works, who rests and who goes out."},
		{"target": func(): return _nav("board"),
			"text": "That's the guild. Plan today's quests on the Board and end the day as usual. On Day 5 a merchant comes to town."},
	]


func _day_five() -> Array:
	return [
		{"text": "Day 5. A travelling merchant has set up in the guild. The [b]Shop[/b] tab is open."},
		{"target": func(): return _nav("shop"), "on": "tab", "when": func(d): return d.tab == "shop",
			"do": "Tap Shop", "text": "Open the [b]Shop[/b]."},
		{"target": func(): return _tab("shop").get_node_or_null("Keeper"),
			"text": "Fresh stock every morning. Whatever you don't buy today is gone tomorrow."},
		{"target": func(): return _u(_tab("shop"), "Grid"), "tap": true,
			"skip": func(): return not _any_affordable(),
			"do": "Tap items to compare, then Next", "text": "Every item is role-locked: its tag says which role can use it. Tap items to compare them, and pick one for a role you have."},
		{"target": func(): return _u(_tab("shop"), "BuyButton"), "on": "buy",
			"skip": func(): return not _any_affordable(),
			"do": "Tap Buy", "text": "The bar shows the picked item and what it does. Buy it."},
		{"target": func(): return _u(_tab("shop"), "Grid"),
			"skip": func(): return _seen.get("buy", false),
			"text": "Nothing here you can afford yet. Quests pay in %s, and the stock changes tomorrow. Gear goes on from a hero's page." % GOLD},
		{"target": func(): return _nav("guild"), "on": "tab", "when": func(d): return d.tab == "guild",
			"skip": func(): return not _seen.get("buy", false) or not _someone_fits_bought(),
			"do": "Tap Members", "text": "Gear goes on from a hero's page. Open [b]Members[/b]."},
		{"target": func(): return _u(_tab("guild"), "SegRoster"), "on": "tab", "when": func(d): return d.guild == "roster",
			"skip": func(): return not _seen.get("buy", false) or not _someone_fits_bought() or hall.guild_section == "roster",
			"do": "Tap Your Guild", "text": "Open [b]Your Guild[/b]."},
		{"target": func(): return _u(_tab("guild"), "List"), "tap": true, "on": "character", "when": func(d): return _fits_bought(d),
			"reject": func(): return "Only %ss can use the %s." % [_bought_role(), _bought_name()],
			"skip": func(): return not _seen.get("buy", false) or not _someone_fits_bought(),
			"do": "Tap a hero with the right role", "text": func(): return "Open a [b]%s[/b]. Only they can use the %s." % [_bought_role(), _bought_name()]},
		{"target": func(): return _u(_screen("character"), "GearLines"), "tap": true, "on": "equip",
			"skip": func(): return not _seen.get("buy", false) or not _someone_fits_bought(),
			"do": "Tap Equip, then the item", "deny": ["SideButton"], "text": func(): return "Tap [b]Equip[/b] on an empty slot, then pick the %s." % _bought_name()},
		{"target": func(): return _u(_screen("character"), "StatLines"),
			"skip": func(): return not _seen.get("equip", false),
			"text": "The gear's bonus is added to their stats and counts on every quest."},
		{"text": func(): return ("You bought gear nobody can use yet. Hire a %s and equip it from their page." % _bought_role()) if (_seen.get("buy", false) and not _someone_fits_bought()) else "That's everything I can teach. Keep your heroes alive, watch the Bone Drake countdown, and good luck, Guildmaster."},
	]
