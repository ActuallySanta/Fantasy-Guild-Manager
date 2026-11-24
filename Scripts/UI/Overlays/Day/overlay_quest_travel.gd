## The "Going on a quest" screen: after End Day, while the party is out, a
## dusk-coloured screen with a walker (Santi's boots or swords art), cycling
## dots on the title and the quest_travel ambience. After a random
## TRAVEL_MIN_SECONDS..TRAVEL_MAX_SECONDS a "View quest report" button fades
## in. Nothing before it can be tapped, so the wait can't be skipped. Pressing
## it stops the sound and calls HallMain.close_quest_travel, which runs the
## dusk curtain into the Day Report, boss crawl or final credits.
##
## Art slots (empty until Santi drops art in; the screen still reads fine
## without them): %Backdrop's texture, and %Walker's SpriteFrames ("default"
## animation, loops). The sound is Sfx's drop-in "quest_travel".
## Reduced Motion: the screen and its wait stay, but there's no bob, the dots
## hold at "...", and the button appears without a fade. The walker's own
## animation still plays (it's art, not UI motion).
## Shown while HallMain.is_quest_travel_open is true. The night is rolled and
## saved before this shows, so a reload here opens straight on the result.
## Scene: Scenes/Overlays/Day/overlay_quest_travel.tscn
extends Control

# ---- MOTION
## Shortest and longest wait before the button appears (seconds). Each trip
## rolls a random length in between, so the player can't time it.
const TRAVEL_MIN_SECONDS := 2.0
const TRAVEL_MAX_SECONDS := 4.0
## How far the walker bobs up and down from its rest spot (pixels).
const BOB_PIXELS := 10.0
## How many bobs per second (Hz).
const BOB_HZ := 1.6
## Time per step of the title's dot cycle ("", ".", "..", "...") (seconds).
const DOT_SECONDS := 0.4
## Most dots shown after the title.
const MAX_DOTS := 3
## How long the button takes to fade in (seconds).
const BUTTON_FADE_SECONDS := 0.25

# ---- LOOK
## Font size of the View quest report button.
const BUTTON_FONT_SIZE := 46
## The walker's rest spot inside %WalkerHolder (pixels; the holder's centre).
const WALKER_REST := Vector2(130, 130)

# ---- TEXT
const TEXT_TITLE := "Going on a quest"
const TEXT_CONTINUE := "View quest report"
const TEXT_DOT := "."

# ---- NODES
@onready var _walker: AnimatedSprite2D = %Walker
@onready var _title: Label = %Title
@onready var _continue_button: Button = %ContinueButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## This trip's rolled wait before the button (seconds). Read by the tests.
var trip_seconds := 0.0
## True from the start of a trip until its button is pressed or the screen hides.
var _is_trip_running := false
## True once a trip started on this showing, until the screen hides. A refresh
## after the press (while the curtain falls) must not start a second trip.
var _has_trip_started := false
## Bumped each trip, so an older trip's timer can't show a later trip's button.
var _trip_number := 0
## Seconds since this trip started (drives the bob and the dots).
var _elapsed := 0.0
## The button's fade-in, killed when a trip starts again.
var _fade_tween: Tween


func setup(main: HallMain) -> void:
	hall = main
	_continue_button.text = TEXT_CONTINUE
	HallStyle.style_button(_continue_button, "gold", BUTTON_FONT_SIZE)
	_continue_button.pressed.connect(_on_continue_pressed)
	visibility_changed.connect(_on_visibility_changed)
	set_process(false)


## Starts a trip when the screen shows (once per showing).
func refresh() -> void:
	if not _has_trip_started:
		_start_trip()


## True once the trip's wait is over and the button can be pressed.
## @return: whether the button shows.
func is_button_shown() -> bool:
	return _continue_button.visible and not _continue_button.disabled


## Rolls the wait, hides the button, starts the sound, the walker and the timer.
func _start_trip() -> void:
	_is_trip_running = true
	_has_trip_started = true
	_trip_number += 1
	_elapsed = 0.0
	trip_seconds = randf_range(TRAVEL_MIN_SECONDS, TRAVEL_MAX_SECONDS)
	if _fade_tween:
		_fade_tween.kill()
	_continue_button.visible = false
	_continue_button.disabled = true
	_walker.position = WALKER_REST
	_update_title()
	Sfx.play(&"quest_travel")
	var frames := _walker.sprite_frames
	if frames and frames.has_animation(&"default") and frames.get_frame_count(&"default") > 0:
		_walker.play(&"default")
	set_process(true)
	var trip := _trip_number
	get_tree().create_timer(trip_seconds).timeout.connect(func() -> void:
		if trip == _trip_number and _is_trip_running:
			_show_button())


## The wait is over: the button shows (fading in unless Reduced Motion is on).
func _show_button() -> void:
	_continue_button.visible = true
	_continue_button.disabled = false
	if HallFx.reduce_motion:
		_continue_button.modulate.a = 1.0
		return
	_continue_button.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_continue_button, "modulate:a", 1.0, BUTTON_FADE_SECONDS)


## Bob the walker and cycle the title's dots while the trip runs.
func _process(delta: float) -> void:
	if not _is_trip_running or not is_visible_in_tree():
		return
	_elapsed += delta
	if HallFx.reduce_motion:
		_walker.position = WALKER_REST
	else:
		_walker.position.y = WALKER_REST.y + sin(_elapsed * TAU * BOB_HZ) * BOB_PIXELS
	_update_title()


## The title with 0..MAX_DOTS dots by elapsed time (fixed at MAX_DOTS with Reduced Motion).
func _update_title() -> void:
	var dots := MAX_DOTS
	if not HallFx.reduce_motion:
		dots = int(_elapsed / DOT_SECONDS) % (MAX_DOTS + 1)
	_title.text = TEXT_TITLE + TEXT_DOT.repeat(dots)


## The button: ends the trip once (a second press in the same frame does
## nothing) and hands back to HallMain for the curtain. It plays no sound of
## its own, so the usual ui_tap plays.
func _on_continue_pressed() -> void:
	if not _is_trip_running:
		return
	_end_trip()
	hall.close_quest_travel()


## Stops the trip's sound, walker and motion.
func _end_trip() -> void:
	_is_trip_running = false
	_continue_button.disabled = true
	_walker.stop()
	Sfx.stop(&"quest_travel")
	set_process(false)


## Hidden (after the curtain, or mid-trip on a new run): stop the sound and
## reset, so the next night starts a fresh trip.
func _on_visibility_changed() -> void:
	if visible:
		return
	if _is_trip_running:
		_end_trip()
	_has_trip_started = false
