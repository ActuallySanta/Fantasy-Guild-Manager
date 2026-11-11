## Hall font scale: grows every font in the Mobile Hall at start-up so the
## smallest text reads at MIN_POINT_SIZE points on this screen, whatever its size,
## then by the player's Text size setting (Menu > Accessibility).
##
## The hall is laid out on a 720x1280 canvas that the window shrinks to fit
## (stretch mode canvas_items, aspect expand). On a 390pt-wide phone one design
## pixel is drawn at about 0.54pt, so a 16px label shows at ~9pt. init() works
## out one factor for this screen and every font size is multiplied by it, so
## the sizes keep their ratios to each other. Only fonts change, not the layout,
## so the factor is capped at MAX_SCALE (phones hit the cap) and the scenes are
## built to wrap, ellipsize or grow when their text is up to that much bigger.
##
## "pt" = a logical point: a CSS px on the web, a point on iOS, a dp on Android.
##
## How the sizes get scaled:
##   - hall_theme.tres: scale_theme() rewrites its sizes from the authored values.
##   - font-size overrides written in .tscn files: scale_authored_overrides(),
##     hooked to SceneTree.node_added by hall_main, scales each new Control's.
##   - sizes set from code: always set_size(control, name, base) (or px(base)),
##     never add_theme_font_size_override directly, so nothing is scaled twice.
## Every scaled override keeps its authored size in a meta tag, so when the
## Text size setting changes, set_text_factor() re-applies the new factor to
## the theme and to every Control already on screen (no reload needed).
## Boxes sized with px()/px_vec() are set again on their view's next refresh.
##
## The factors live in static vars. They're display info, not run state, so
## they should survive start_new_run's scene reload.
class_name HallFontScale
extends RefCounted


# ============================================================ TUNING

## Smallest text size wanted on screen, in points.
const MIN_POINT_SIZE := 16.0
## Smallest font size authored anywhere in the Mobile Hall, in design px
## (plan_row's number). Lower it if something smaller is ever added.
const SMALLEST_DESIGN_SIZE := 16.0
## The design canvas (project.godot window/size/viewport_*), in px.
const DESIGN_WIDTH := 720.0
const DESIGN_HEIGHT := 1280.0
## Biggest screen factor. The layout (min sizes, margins, fixed boxes) isn't
## scaled, so past this the text no longer fits it. With the values above it's
## reached on screens under ~480pt wide (every phone), where the smallest text
## then shows at ~13pt on a 390pt phone instead of MIN_POINT_SIZE.
const MAX_SCALE := 1.5
## Range of the final factor (screen factor x Text size setting). The scenes
## are checked to hold their text up to MAX_TOTAL_SCALE (a phone on the
## largest Text size: 1.5 x HallSettings.TEXT_SIZE_FACTORS' last entry).
const MIN_TOTAL_SCALE := 0.75
const MAX_TOTAL_SCALE := 2.0
## Physical pixels per point on Android (dp are defined at 160 dpi) and on
## Windows / Linux (100% display scaling is 96 dpi).
const ANDROID_BASE_DPI := 160.0
const DESKTOP_BASE_DPI := 96.0
## Dev override: run with `-- --font-scale=2.0` to force the factor (layout checks).
const CMDLINE_PREFIX := "--font-scale="
## Font-size theme items a Control can override (Label/Button use font_size,
## RichTextLabel the rest).
const FONT_SIZE_NAMES: Array[StringName] = [
	&"font_size", &"normal_font_size", &"bold_font_size", &"italics_font_size",
	&"bold_italics_font_size", &"mono_font_size",
]
## Meta tag prefix holding an override's authored size (design px), which also
## marks it as already scaled.
const BASE_META_PREFIX := "_font_base_"
## Meta key capping how much a Control's text may grow (a float factor, e.g.
## 1.5). Set it in a scene (metadata/font_max_factor) or through set_size's
## max_factor, on short labels in rows that can't wrap (counters, one-word
## buttons, the nav tabs), so a big Text size doesn't push the row off screen.
const MAX_FACTOR_META := &"font_max_factor"


# ============================================================ STATE

## The factor every font size is multiplied by (1.0 = as authored):
## screen_factor x text_factor, kept inside [MIN_TOTAL_SCALE, MAX_TOTAL_SCALE].
static var scale := 1.0
## The part that comes from this screen's size (compute_scale), and the part
## from the player's Text size setting (HallSettings.TEXT_SIZE_FACTORS).
static var screen_factor := 1.0
static var text_factor := 1.0
## The theme's authored sizes, saved the first time it's scaled, so scaling
## again (after a scene reload) starts from them and never compounds.
## Keys: "<type>/<name>" (and "default" for default_font_size), values: int.
static var _theme_base_sizes := {}


# ============================================================ SETUP

## Work out the factor for the screen `window` is on, then scale `theme`.
## window      = the game window (its size is in physical px).
## theme       = the hall's theme (hall_theme.tres), or null to skip it.
## text_factor = the player's Text size multiplier (1.0 = Normal).
static func init(window: Window, theme: Theme, player_text_factor: float = 1.0) -> void:
	var forced := _cmdline_scale()
	if forced > 0.0:
		screen_factor = forced
	else:
		screen_factor = compute_scale(Vector2(window.size), pixels_per_point())
	text_factor = player_text_factor
	_update_scale()
	if theme != null:
		scale_theme(theme)


## Change the Text size setting's multiplier and re-apply every font size:
## the theme's, and the overrides of every Control under `root`.
## factor = the new multiplier (1.0 = Normal). theme / root may be null.
static func set_text_factor(factor: float, theme: Theme, root: Node) -> void:
	text_factor = factor
	_update_scale()
	if theme != null:
		scale_theme(theme)
	if root != null:
		rescale_tree(root)


## scale = screen_factor x text_factor, kept in range. The command-line
## override is a layout check, so it isn't capped.
static func _update_scale() -> void:
	scale = screen_factor * text_factor
	if _cmdline_scale() <= 0.0:
		scale = clampf(scale, MIN_TOTAL_SCALE, MAX_TOTAL_SCALE)


## The font factor for a window of `window_pixels` physical px, on a screen
## with `pixels_per_point` physical px per point.
## Returns a factor in [1.0, MAX_SCALE]: never shrinks text, and stops growing
## at MAX_SCALE so the unscaled layout still holds it.
static func compute_scale(window_pixels: Vector2, pixels_per_point: float) -> float:
	if window_pixels.x <= 0.0 or window_pixels.y <= 0.0 or pixels_per_point <= 0.0:
		return 1.0
	# aspect "expand": the canvas grows to fit the window's tighter side
	var canvas_scale := minf(window_pixels.x / DESIGN_WIDTH, window_pixels.y / DESIGN_HEIGHT)
	var points_per_design_px := canvas_scale / pixels_per_point
	var wanted := MIN_POINT_SIZE / (SMALLEST_DESIGN_SIZE * points_per_design_px)
	return clampf(wanted, 1.0, MAX_SCALE)


## Physical pixels per point on this device (1.0 when it can't tell).
static func pixels_per_point() -> float:
	var screen := DisplayServer.window_get_current_screen()
	var ratio := 1.0
	if OS.has_feature("web") or OS.has_feature("ios") or OS.has_feature("macos"):
		# devicePixelRatio on the web, the native scale on Apple screens
		ratio = DisplayServer.screen_get_scale(screen)
	elif OS.has_feature("android"):
		ratio = DisplayServer.screen_get_dpi(screen) / ANDROID_BASE_DPI
	else:
		ratio = DisplayServer.screen_get_dpi(screen) / DESKTOP_BASE_DPI
	return ratio if ratio > 0.0 else 1.0


## The factor from `--font-scale=<x>` after `--` on the command line, or 0.0.
static func _cmdline_scale() -> float:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(CMDLINE_PREFIX):
			return maxf(argument.trim_prefix(CMDLINE_PREFIX).to_float(), 0.0)
	return 0.0


# ============================================================ SIZES

## `base` design px scaled by the current factor.
static func px(base: int) -> int:
	return maxi(roundi(base * scale), 1)


## A design-px size scaled by the current factor, for boxes that have to grow
## with the text they hold (seals, odds circles, badges). Leave art-only boxes
## (portraits, icons) at their authored size.
## base       = the authored size, in design px.
## max_factor = the most it may grow (0 = no cap; match the text it holds).
## Returns the scaled size, rounded.
static func px_vec(base: Vector2, max_factor: float = 0.0) -> Vector2:
	var factor := minf(scale, max_factor) if max_factor > 0.0 else scale
	return Vector2(roundf(base.x * factor), roundf(base.y * factor))


## `base` design px scaled by the current factor, but never by more than
## `max_factor` (0 = no cap).
static func px_capped(base: int, max_factor: float) -> int:
	var factor := minf(scale, max_factor) if max_factor > 0.0 else scale
	return maxi(roundi(base * factor), 1)


## Set `control`'s font-size override `name` to `base` scaled, and tag it so
## scale_authored_overrides leaves it alone. Use this instead of
## add_theme_font_size_override everywhere in the Mobile Hall.
## max_factor = the most this control's text may grow (stored as its
## MAX_FACTOR_META; 0 = keep whatever cap it already has, or none).
static func set_size(control: Control, name: StringName, base: int, max_factor: float = 0.0) -> void:
	if max_factor > 0.0:
		control.set_meta(MAX_FACTOR_META, max_factor)
	control.add_theme_font_size_override(name, px_capped(base, _max_factor_of(control)))
	control.set_meta(BASE_META_PREFIX + String(name), base)


## The control's growth cap (MAX_FACTOR_META), or 0.0 for none.
static func _max_factor_of(control: Control) -> float:
	return float(control.get_meta(MAX_FACTOR_META, 0.0))


## Rewrite every font size in `theme` as its authored size times the factor.
## Safe to call again: it always starts from the sizes saved the first time.
static func scale_theme(theme: Theme) -> void:
	if _theme_base_sizes.is_empty():
		if theme.has_default_font_size():
			_theme_base_sizes["default"] = theme.default_font_size
		for type in theme.get_font_size_type_list():
			for name in theme.get_font_size_list(type):
				_theme_base_sizes["%s/%s" % [type, name]] = theme.get_font_size(name, type)
	for key: String in _theme_base_sizes:
		var size := px(_theme_base_sizes[key])
		if key == "default":
			theme.default_font_size = size
		else:
			theme.set_font_size(key.get_slice("/", 1), key.get_slice("/", 0), size)


## SceneTree.node_added hook: scale the font-size overrides `node` came with
## (the ones written in its .tscn). Each is tagged, so it's scaled only once.
static func scale_authored_overrides(node: Node) -> void:
	var control := node as Control
	if control == null:
		return
	for name in FONT_SIZE_NAMES:
		if not control.has_theme_font_size_override(name):
			continue
		var tag := BASE_META_PREFIX + String(name)
		if control.has_meta(tag):
			continue
		var base := control.get_theme_font_size(name)
		control.add_theme_font_size_override(name, px_capped(base, _max_factor_of(control)))
		control.set_meta(tag, base)


## Re-apply the current factor to every scaled override under `root` (itself
## included), from the authored sizes kept in their meta tags.
static func rescale_tree(root: Node) -> void:
	var control := root as Control
	if control != null:
		for name in FONT_SIZE_NAMES:
			var tag := BASE_META_PREFIX + String(name)
			if control.has_meta(tag):
				control.add_theme_font_size_override(name, px_capped(int(control.get_meta(tag)), _max_factor_of(control)))
	for child in root.get_children():
		rescale_tree(child)
