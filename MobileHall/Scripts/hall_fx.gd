## Mobile Hall motion: small, bouncy animations that tie what the player did to
## what it changed (a counter rolling, a stamp landing, a card flying off).
##
## Every helper is static and makes its tween on the node it animates, so the
## tween dies with the node when a refresh rebuilds that row. Helpers that
## need the node's laid-out size wait one frame first (containers size their
## children at the end of the frame).
##
## Things that must outlive a refresh (flying icons, floating numbers, stamps,
## curtains) are built on the hall's FX layer (HallMain.fx_layer), a
## full-screen Control above the overlays and below Pip and the colorblind filter.
##
## Reduced Motion (Menu, saved with the settings) makes every helper a no-op
## that leaves the node in its final state, and runs any callback right away.
##
## Look: bouncy overshoot (TRANS_BACK), squash and stretch, stamps. No glows,
## no blurs (see the UI style guide).
class_name HallFx
extends RefCounted


## Set from the Menu's Reduced Motion button (HallMain.set_reduce_motion).
static var reduce_motion := false

## Ink outline on floating numbers so they read on wood and on paper.
const FLOAT_OUTLINE := Color("#FFF6E4")
const FLOAT_OUTLINE_SIZE := 10
## How far a floating number rises, and how long it lives.
const FLOAT_RISE := 64.0
const FLOAT_SECONDS := 0.9
## Pressing a stamp onto something (stamp_onto): how big it starts above the
## page, how far it squashes on impact (1 = none), the seconds it falls and
## then settles, and how far the page dips under the press.
const STAMP_DROP_SCALE := 2.6
const STAMP_IMPACT_SCALE := 0.9
const STAMP_FALL_SECONDS := 0.16
const STAMP_SETTLE_SECONDS := 0.22
const STAMP_PAGE_DIP := 0.96
## Hanging something on a nail (swing_in): the angle it starts swung out to
## (radians), how many times it swings back across the middle before it
## settles, the seconds that takes, and the seconds it takes to fade in.
const SWING_START_ANGLE := 0.26
const SWING_CROSSINGS := 3
const SWING_SECONDS := 1.0
const SWING_FADE_SECONDS := 0.12


# ============================================================ BASICS

## Wait for layout. Returns false if the node went away meanwhile.
static func _wait_for_layout(node: Control) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return false
	await node.get_tree().process_frame
	return is_instance_valid(node) and node.is_inside_tree()


## A fresh tween for one kind of motion on a node (scale, alpha, ...),
## killing the last one of that kind so they don't fight.
static func _tween(node: Node, key: StringName) -> Tween:
	if node.has_meta(key):
		var old_tween = node.get_meta(key)
		if old_tween is Tween and old_tween.is_valid():
			old_tween.kill()
	var tween := node.create_tween()
	node.set_meta(key, tween)
	return tween


static func _center_pivot(node: Control) -> void:
	node.pivot_offset = node.size / 2.0


## The alpha a node fades in to: its own alpha the first time it fades, then
## remembered for the node's life. A fade that starts while another is still
## running (tapping quickly between quests or tabs) would otherwise take the
## half-faded alpha as where to stop, and the node would stay see-through.
## (Every faded node here keeps one resting alpha: rows are rebuilt on refresh.)
static func _resting_alpha(node: CanvasItem) -> float:
	if not node.has_meta(&"fx_resting_alpha"):
		node.set_meta(&"fx_resting_alpha", node.modulate.a)
	return node.get_meta(&"fx_resting_alpha")


# ============================================================ ON A NODE

## Quick grow-and-settle: "this just changed".
static func pop(node: Control, peak := 1.15, delay := 0.0, duration := 0.3) -> void:
	if reduce_motion or not await _wait_for_layout(node):
		return
	_center_pivot(node)
	var tween := _tween(node, &"fx_scale")
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "scale", Vector2.ONE * peak, duration * 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.65) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Pop a few times in a row (a warning that wants to be noticed).
static func pulse(node: Control, times := 3, peak := 1.12, delay := 0.0) -> void:
	if reduce_motion or not await _wait_for_layout(node):
		return
	_center_pivot(node)
	var tween := _tween(node, &"fx_scale")
	if delay > 0.0:
		tween.tween_interval(delay)
	for pulse_index in times:
		tween.tween_property(node, "scale", Vector2.ONE * peak, 0.14) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "scale", Vector2.ONE, 0.22) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Arrive from nothing: fades in while settling from from_scale (big = slams
## down like a stamp, small = grows in). Hidden right away until its delay is up.
static func appear(node: Control, from_scale := 0.85, delay := 0.0, duration := 0.28) -> void:
	if reduce_motion or not is_instance_valid(node):
		return
	var target_alpha := _resting_alpha(node)
	node.modulate.a = 0.0
	if not await _wait_for_layout(node):
		return
	_center_pivot(node)
	node.scale = Vector2.ONE * from_scale
	var tween := _tween(node, &"fx_scale")
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", target_alpha, duration * 0.4)
	tween.parallel().tween_property(node, "scale", Vector2.ONE, duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Slam down like a rubber stamp (starts big, lands with a bounce).
static func stamp_in(node: Control, from_scale := 1.8, delay := 0.0) -> void:
	appear(node, from_scale, delay, 0.24)


## Fade in from clear (keeps the node's own faded look, e.g. a denied row).
static func fade_in(node: Control, delay := 0.0, duration := 0.22) -> void:
	if reduce_motion or not is_instance_valid(node):
		return
	var target_alpha := _resting_alpha(node)
	node.modulate.a = 0.0
	var tween := _tween(node, &"fx_alpha")
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", target_alpha, duration)


## Slide into place from `offset` away (and fade in). Works in containers too:
## if the container re-sorts mid-slide, the node just lands early.
static func slide_in(node: Control, offset: Vector2, delay := 0.0, duration := 0.3) -> void:
	if reduce_motion or not is_instance_valid(node):
		return
	var target_alpha := _resting_alpha(node)
	node.modulate.a = 0.0
	if not await _wait_for_layout(node):
		return
	var resting := node.position
	node.position = resting + offset
	var tween := _tween(node, &"fx_move")
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", target_alpha, duration * 0.5)
	tween.parallel().tween_property(node, "position", resting, duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Hang like a sign on a nail: it fades in swung out to one side, then swings
## back and forth about the nail, each swing smaller, and settles straight.
## The nail is at the top middle of the node, `nail_y` pixels down.
## Hidden right away until its delay is up.
static func swing_in(node: Control, nail_y := 0.0, delay := 0.0) -> void:
	if reduce_motion or not is_instance_valid(node):
		return
	var target_alpha := _resting_alpha(node)
	node.modulate.a = 0.0
	if not await _wait_for_layout(node):
		return
	node.pivot_offset = Vector2(node.size.x / 2.0, nail_y)
	node.rotation = SWING_START_ANGLE
	var tween := _tween(node, &"fx_swing")
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", target_alpha, SWING_FADE_SECONDS)
	# a damped pendulum: crosses the middle SWING_CROSSINGS times, dying away
	var sway := func(progress: float) -> void:
		node.rotation = SWING_START_ANGLE * pow(1.0 - progress, 2.0) * cos(progress * PI * SWING_CROSSINGS)
	tween.parallel().tween_method(sway, 0.0, 1.0, SWING_SECONDS)
	tween.tween_callback(func() -> void: node.rotation = 0.0)


## Side-to-side shake that settles (a refusal, a loss, a death).
static func shake(node: Control, strength := 10.0, delay := 0.0, duration := 0.35) -> void:
	if reduce_motion or not await _wait_for_layout(node):
		return
	var resting_x := node.position.x
	var tween := _tween(node, &"fx_move")
	if delay > 0.0:
		tween.tween_interval(delay)
	var wobble := func(progress: float) -> void:
		node.position.x = resting_x + sin(progress * PI * 7.0) * strength * (1.0 - progress)
	tween.tween_method(wobble, 0.0, 1.0, duration)
	tween.tween_callback(func() -> void: node.position.x = resting_x)


## Squash, stretch, settle: something just got built.
static func squash(node: Control, delay := 0.0) -> void:
	if reduce_motion or not await _wait_for_layout(node):
		return
	node.pivot_offset = Vector2(node.size.x / 2.0, node.size.y)
	var tween := _tween(node, &"fx_scale")
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "scale", Vector2(1.3, 0.7), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(0.85, 1.2), 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Flip over on its horizontal axis, like a page or a calendar card turning.
## `on_hidden` runs at the edge-on moment (swap the text there).
static func flip(node: Control, delay := 0.0, on_hidden := Callable()) -> void:
	if reduce_motion or not await _wait_for_layout(node):
		if on_hidden.is_valid():
			on_hidden.call()
		return
	_center_pivot(node)
	var tween := _tween(node, &"fx_scale")
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(node, "scale:y", 0.0, 0.13).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if on_hidden.is_valid():
		tween.tween_callback(on_hidden)
	tween.tween_property(node, "scale:y", 1.0, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## Roll a label's number from `from` to `to`. fmt gets one int ("%d", "+%d gold").
static func count(label: Label, from: int, to: int, duration := 0.45, fmt := "%d", delay := 0.0) -> void:
	if reduce_motion or from == to or not is_instance_valid(label):
		if is_instance_valid(label):
			label.text = fmt % to
		return
	label.text = fmt % from
	var tween := _tween(label, &"fx_count")
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(func(value: float) -> void: label.text = fmt % roundi(value),
			float(from), float(to), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Tint a label's text with `color`, then ease back to its own colour.
static func flash_text(label: Control, color: Color, duration := 0.6) -> void:
	if reduce_motion or not is_instance_valid(label):
		return
	# remember the label's real colour once, so a flash cut short doesn't stick
	if not label.has_meta(&"fx_flash_base"):
		label.set_meta(&"fx_flash_base", {
			"color": label.get_theme_color("font_color"),
			"overridden": label.has_theme_color_override("font_color"),
		})
	var base: Dictionary = label.get_meta(&"fx_flash_base")
	var tween := _tween(label, &"fx_flash")
	tween.tween_method(func(ink: Color) -> void: label.add_theme_color_override("font_color", ink),
			color, base.color, duration).set_ease(Tween.EASE_IN)
	var restore := func() -> void:
		if not base.overridden:
			label.remove_theme_color_override("font_color")
		label.remove_meta(&"fx_flash_base")
	tween.tween_callback(restore)


# ============================================================ ON THE FX LAYER

## A number (or short word) that rises off `at` and fades: "+40", "-2", "+12%".
static func float_text(layer: Control, at: Vector2, text: String, color: Color, font_size := 34, delay := 0.0) -> void:
	if reduce_motion or not is_instance_valid(layer):
		return
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.theme_type_variation = &"TitleLabel"
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", FLOAT_OUTLINE)
	label.add_theme_constant_override("outline_size", FLOAT_OUTLINE_SIZE)
	layer.add_child(label)
	label.size = label.get_combined_minimum_size()
	label.global_position = at - label.size / 2.0
	label.pivot_offset = label.size / 2.0
	label.modulate.a = 0.0
	label.scale = Vector2.ONE * 0.6

	var tween := label.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(label, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:y", label.position.y - FLOAT_RISE, FLOAT_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(FLOAT_SECONDS - 0.3)
	tween.tween_callback(label.queue_free)


## An icon that arcs from `from` to `to` (global points), shrinking a little,
## then runs `on_land`. Used for coins and standing shields.
static func fly(layer: Control, texture: Texture2D, from: Vector2, to: Vector2, icon_size := 44.0,
		delay := 0.0, duration := 0.5, on_land := Callable()) -> void:
	if reduce_motion or not is_instance_valid(layer) or texture == null:
		if on_land.is_valid():
			on_land.call()
		return
	var icon := TextureRect.new()
	icon.texture = texture
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2.ONE * icon_size
	icon.pivot_offset = icon.size / 2.0
	layer.add_child(icon)
	icon.global_position = from - icon.size / 2.0
	icon.visible = delay <= 0.0

	# the arc bends up and toward the side it's heading
	var bend := (from + to) / 2.0 + Vector2(0, -minf(160.0, 60.0 + from.distance_to(to) * 0.25))
	var half := icon.size / 2.0
	var tween := icon.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(icon.show)
	var move_along_arc := func(progress: float) -> void:
		var along_start := from.lerp(bend, progress)
		var along_end := bend.lerp(to, progress)
		icon.global_position = along_start.lerp(along_end, progress) - half
		icon.rotation = sin(progress * PI) * 0.6
	tween.tween_method(move_along_arc, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(icon, "scale", Vector2.ONE * 0.7, duration)
	if on_land.is_valid():
		tween.tween_callback(on_land)
	tween.tween_callback(icon.queue_free)


## Lift a node out of its list onto the FX layer (same spot on screen), so a
## refresh can't free it while it animates away. Taps pass through it.
static func detach(node: Control, layer: Control) -> void:
	_ignore_mouse(node)
	if node.get_parent() == layer:
		return
	var rect := node.get_global_rect()
	node.get_parent().remove_child(node)
	layer.add_child(node)
	node.global_position = rect.position
	node.size = rect.size


static func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


## Send a node off to `to` (a global point): it lifts, then shrinks into it.
## The node is freed at the end.
static func fly_away(node: Control, layer: Control, to: Vector2, duration := 0.5) -> void:
	if reduce_motion or not is_instance_valid(node):
		return
	detach(node, layer)
	_center_pivot(node)
	var end := to - node.size / 2.0
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * 1.05, 0.08)
	tween.tween_property(node, "global_position", end, duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(node, "scale", Vector2.ONE * 0.12, duration).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(node, "rotation", -0.25, duration)
	tween.parallel().tween_property(node, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.tween_callback(node.queue_free)


## An ink stamp box with `text` (same Stamp look as the Day Report's result
## stamp). Taps pass through it.
static func _make_stamp(text: String, ink: Color, font_size: int) -> PanelContainer:
	var stamp := PanelContainer.new()
	stamp.name = "Stamp"
	stamp.theme_type_variation = &"Stamp"
	stamp.self_modulate = ink
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# stamps keep the blackletter heading font; a single short word reads fine
	label.theme_type_variation = &"HeadingLabel"
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ink)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp.add_child(label)
	return stamp


## Press a rubber stamp onto `target` and leave the ink there: the stamp
## drops from above, squashes on impact while the page dips under it, then
## settles. `target` should be a PanelContainer (a card, a row): the stamp
## sits on its own layer that fills the target, drawn over its content.
##   at:        where the stamp's centre sits, as a fraction of the target's size
##   tilt:      rotation in radians (stamps never land straight)
##   animate:   false = just leave the ink (a quest that was sent earlier)
## Returns the stamp's layer, so the caller can free it to lift the ink off.
static func stamp_onto(target: Control, text: String, ink: Color, at := Vector2(0.72, 0.45),
		font_size := 52, tilt := -0.16, animate := true) -> Control:
	var ink_layer := Control.new()
	ink_layer.name = "StampInk"
	ink_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(ink_layer)

	var stamp := _make_stamp(text, ink, font_size)
	ink_layer.add_child(stamp)
	var stamp_size := stamp.get_combined_minimum_size()
	# anchored at `at`, so it stays put however the target is sized later
	stamp.anchor_left = at.x
	stamp.anchor_right = at.x
	stamp.anchor_top = at.y
	stamp.anchor_bottom = at.y
	stamp.offset_left = -stamp_size.x / 2.0
	stamp.offset_right = stamp_size.x / 2.0
	stamp.offset_top = -stamp_size.y / 2.0
	stamp.offset_bottom = stamp_size.y / 2.0
	stamp.pivot_offset = stamp_size / 2.0
	stamp.rotation = tilt
	if not animate or reduce_motion:
		return ink_layer

	stamp.modulate.a = 0.0
	stamp.scale = Vector2.ONE * STAMP_DROP_SCALE
	var tween := stamp.create_tween()
	# falling: it speeds up as it comes down
	tween.tween_property(stamp, "modulate:a", 1.0, STAMP_FALL_SECONDS * 0.5)
	tween.parallel().tween_property(stamp, "scale", Vector2.ONE * STAMP_IMPACT_SCALE, STAMP_FALL_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# impact: the page dips under the press
	tween.tween_callback(_press_page.bind(target))
	# the stamp lifts off its squash and the ink settles
	tween.tween_property(stamp, "scale", Vector2.ONE, STAMP_SETTLE_SECONDS) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return ink_layer


## The page under a stamp dips and springs back.
static func _press_page(page: Control) -> void:
	if not is_instance_valid(page):
		return
	_center_pivot(page)
	var tween := _tween(page, &"fx_scale")
	tween.tween_property(page, "scale", Vector2.ONE * STAMP_PAGE_DIP, 0.05).set_ease(Tween.EASE_OUT)
	tween.tween_property(page, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A big ink stamp ("DENIED") that slams down at `at` on the FX layer, holds,
## then fades (nothing stays inked).
static func stamp_mark(layer: Control, at: Vector2, text: String, ink: Color, hold := 0.45) -> void:
	if reduce_motion or not is_instance_valid(layer):
		return
	var stamp := _make_stamp(text, ink, 64)
	layer.add_child(stamp)
	stamp.size = stamp.get_combined_minimum_size()
	stamp.global_position = at - stamp.size / 2.0
	stamp.pivot_offset = stamp.size / 2.0
	stamp.rotation = -0.16
	stamp.scale = Vector2.ONE * 2.4
	stamp.modulate.a = 0.0

	var tween := stamp.create_tween()
	tween.tween_property(stamp, "modulate:a", 1.0, 0.07)
	tween.parallel().tween_property(stamp, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold)
	tween.tween_property(stamp, "modulate:a", 0.0, 0.18)
	tween.tween_callback(stamp.queue_free)


## Swallow taps for a moment (while a stamp lands, before the screen moves on).
static func block_input(layer: Control, seconds: float) -> void:
	if reduce_motion or not is_instance_valid(layer):
		return
	var blocker := Control.new()
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(blocker)
	blocker.create_tween().tween_interval(seconds).finished.connect(blocker.queue_free)


## A full-screen wash of `color` that fades in, runs `at_peak` while the
## screen is covered (swap what's underneath there), then fades out.
## Taps are blocked the whole time.
static func curtain(layer: Control, color: Color, at_peak: Callable, peak_alpha := 0.92,
		fade_in_seconds := 0.3, fade_out_seconds := 0.4) -> void:
	if reduce_motion or not is_instance_valid(layer):
		at_peak.call()
		return
	var wash := ColorRect.new()
	wash.color = color
	wash.mouse_filter = Control.MOUSE_FILTER_STOP
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.modulate.a = 0.0
	layer.add_child(wash)
	var tween := wash.create_tween()
	tween.tween_property(wash, "modulate:a", peak_alpha, fade_in_seconds).set_ease(Tween.EASE_IN)
	tween.tween_callback(at_peak)
	tween.tween_interval(0.08)
	tween.tween_property(wash, "modulate:a", 0.0, fade_out_seconds).set_ease(Tween.EASE_OUT)
	tween.tween_callback(wash.queue_free)
