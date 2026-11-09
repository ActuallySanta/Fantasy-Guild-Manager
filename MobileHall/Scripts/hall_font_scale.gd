## Hall font scale: grows every font in the Mobile Hall at start-up so the
## smallest text reads at MIN_POINT_SIZE points on this screen, whatever its size.
##
## The hall is laid out on a 720x1280 canvas that the window shrinks to fit
## (stretch mode canvas_items, aspect expand). On a 390pt-wide phone one design
## pixel is drawn at about 0.54pt, so a 16px label shows at ~9pt. init() works
## out one factor for this screen and every font size is multiplied by it, so
## the sizes keep their ratios to each other. Only fonts change, not the layout.
##
## "pt" = a logical point: a CSS px on the web, a point on iOS, a dp on Android.
##
## How the sizes get scaled:
##   - hall_theme.tres: scale_theme() rewrites its sizes from the authored values.
##   - font-size overrides written in .tscn files: scale_authored_overrides(),
##     hooked to SceneTree.node_added by hall_main, scales each new Control's.
##   - sizes set from code: always set_size(control, name, base) (or px(base)),
##     never add_theme_font_size_override directly, so nothing is scaled twice.
##
## The factor lives in a static var. It's display info, not run state, so it
## should survive start_new_run's scene reload.
class_name HallFontScale
extends RefCounted


# ============================================================ TUNING

## Smallest text size wanted on screen, in points.
const MIN_POINT_SIZE := 16.0
## Smallest font size authored anywhere in the Mobile Hall, in design px
## (plan_row's number). Lower it if something smaller is ever added.
const SMALLEST_DESIGN_SIZE := 16.0
## Below this screen width (in points) the factor stops growing: on tinier
## screens text dips under MIN_POINT_SIZE rather than breaking the layout.
const FLOOR_SCREEN_WIDTH_POINTS := 360.0
## The design canvas (project.godot window/size/viewport_*), in px.
const DESIGN_WIDTH := 720.0
const DESIGN_HEIGHT := 1280.0
## Biggest factor, reached at FLOOR_SCREEN_WIDTH_POINTS (2.0 with the values above).
const MAX_SCALE := (MIN_POINT_SIZE / SMALLEST_DESIGN_SIZE) * DESIGN_WIDTH / FLOOR_SCREEN_WIDTH_POINTS
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
## Meta tag prefix marking an override as already scaled.
const SCALED_META_PREFIX := "_font_scaled_"


# ============================================================ STATE

## The factor every font size is multiplied by (1.0 = as authored).
static var scale := 1.0
## The theme's authored sizes, saved the first time it's scaled, so scaling
## again (after a scene reload) starts from them and never compounds.
## Keys: "<type>/<name>" (and "default" for default_font_size), values: int.
static var _theme_base_sizes := {}


# ============================================================ SETUP

## Work out the factor for the screen `window` is on, then scale `theme`.
## window = the game window (its size is in physical px).
## theme  = the hall's theme (hall_theme.tres), or null to skip it.
static func init(window: Window, theme: Theme) -> void:
	var forced := _cmdline_scale()
	if forced > 0.0:
		scale = forced
	else:
		scale = compute_scale(Vector2(window.size), pixels_per_point())
	if theme != null:
		scale_theme(theme)


## The font factor for a window of `window_pixels` physical px, on a screen
## with `pixels_per_point` physical px per point.
## Returns a factor in [1.0, MAX_SCALE]: never shrinks text, and stops growing
## once the screen is narrower than FLOOR_SCREEN_WIDTH_POINTS.
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


## Set `control`'s font-size override `name` to `base` scaled, and tag it so
## scale_authored_overrides leaves it alone. Use this instead of
## add_theme_font_size_override everywhere in the Mobile Hall.
static func set_size(control: Control, name: StringName, base: int) -> void:
	control.add_theme_font_size_override(name, px(base))
	control.set_meta(SCALED_META_PREFIX + String(name), true)


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
		var tag := SCALED_META_PREFIX + String(name)
		if control.has_meta(tag):
			continue
		control.add_theme_font_size_override(name, px(control.get_theme_font_size(name)))
		control.set_meta(tag, true)
