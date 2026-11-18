## The motion behind a film-style text crawl: the final credits
## (overlay_credits.gd) and the intro story (overlay_intro.gd).
##
## The roll waits START_DELAY, then scrolls itself at a steady speed. Any touch,
## drag, click or wheel hands it to the player for good. The footer (the
## overlay's leave button) stays hidden until the bottom is first reached,
## then stays, so the player can scroll back up and still leave.
## Reduced Motion (HallFx.reduce_motion): no auto-scroll and no blank space
## above the title, so the text shows straight away.
##
## No scene: the overlay makes one with CrawlRoll.new(), adds it as a child
## and calls setup() with its own nodes, then start() each time it opens.
class_name CrawlRoll
extends Node


## Seconds the roll holds still before it starts to move.
const START_DELAY := 1.2
## The bottom counts as reached within this many pixels of the end.
const BOTTOM_SLACK := 4.0
## Frames to wait after start() before checking whether the roll fits on one
## screen (the containers need a frame or two to lay out the new spacing).
const LAYOUT_FRAMES := 2

## The overlay's nodes (set in setup()).
var _scroll: ScrollContainer
var _top_space: Control
var _bottom_space: Control
var _footer: Control
## True while the roll moves by itself (until the player touches it or it ends).
var _is_auto_scrolling := false
## Seconds left before the roll starts to move.
var _start_wait := 0.0
## Where the roll is, in fractional pixels (scroll_vertical is an int).
var _scroll_position := 0.0
## How fast the roll moves this time (pixels per second, set by start()).
var _speed := 0.0


## Hook up the overlay's nodes.
## scroll: the ScrollContainer holding the roll.
## top_space / bottom_space: blank Controls at the roll's two ends.
## footer: shown once the bottom is first reached (the leave button).
func setup(scroll: ScrollContainer, top_space: Control, bottom_space: Control, footer: Control) -> void:
	_scroll = scroll
	_top_space = top_space
	_bottom_space = bottom_space
	_footer = footer
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scrolled)
	set_process(false)


## Back to the top with the footer hidden, then (motion allowed) wait and roll.
## speed: pixels per second.
## top_space_share: share of the screen's height left blank above the title,
##   so the roll starts from the bottom of the screen (0 under Reduced Motion).
## bottom_space: blank pixels under the last line, so it can scroll up past
##   the pinned footer instead of ending under it.
func start(speed: float, top_space_share: float, bottom_space: float) -> void:
	_speed = speed
	_footer.visible = false
	var overlay := get_parent() as Control
	var screen_height: float = overlay.size.y if overlay and overlay.size.y > 0.0 else get_viewport().get_visible_rect().size.y
	_top_space.custom_minimum_size.y = 0.0 if HallFx.reduce_motion else screen_height * top_space_share
	_bottom_space.custom_minimum_size.y = bottom_space
	_scroll_position = 0.0
	_scroll.scroll_vertical = 0
	_is_auto_scrolling = not HallFx.reduce_motion
	_start_wait = START_DELAY
	set_process(_is_auto_scrolling)
	# a roll short enough to fit on screen never scrolls, so value_changed
	# never fires: check once the new spacing has been laid out
	_check_fits()


func _process(delta: float) -> void:
	if not _is_auto_scrolling or not _is_shown():
		set_process(false)
		return
	if _start_wait > 0.0:
		_start_wait -= delta
		return
	_scroll_position += _speed * delta
	_scroll.scroll_vertical = int(_scroll_position)
	# the last line has passed: stop, the footer takes over
	if _is_at_bottom():
		_stop_auto_scroll()


## Any touch, drag or wheel while the roll moves gives it to the player.
func _input(event: InputEvent) -> void:
	if not _is_auto_scrolling or not _is_shown():
		return
	var is_touch: bool = event is InputEventScreenTouch or event is InputEventScreenDrag
	var is_click: bool = event is InputEventMouseButton and event.pressed
	if is_touch or is_click:
		_stop_auto_scroll()


func _stop_auto_scroll() -> void:
	_is_auto_scrolling = false
	set_process(false)


## The roll moved (by itself or by the player): the first time it reaches the
## bottom the footer appears, and it stays from then on.
func _on_scrolled(_value: float) -> void:
	if _footer and not _footer.visible and _is_at_bottom():
		_footer.visible = true
		HallFx.appear(_footer, 0.85)


## After start(): wait for the layout, then show the footer if the whole roll
## already fits (only possible under Reduced Motion, with no top space).
func _check_fits() -> void:
	for frame in LAYOUT_FRAMES:
		await get_tree().process_frame
	# an unlaid-out bar reads 0 / 0, which would count as the bottom
	if is_inside_tree() and _scroll.get_v_scroll_bar().max_value > 0.0:
		_on_scrolled(0.0)


## True when the roll is scrolled to (or within BOTTOM_SLACK of) its end.
func _is_at_bottom() -> bool:
	var bar := _scroll.get_v_scroll_bar()
	return bar.value + bar.page >= bar.max_value - BOTTOM_SLACK


## True while the overlay this roll belongs to is on screen.
func _is_shown() -> bool:
	var overlay := get_parent() as CanvasItem
	return overlay != null and overlay.is_visible_in_tree()
