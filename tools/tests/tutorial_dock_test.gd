extends TestCase
## Tutorial dock test: Pip's bubble must settle on one side (top or bottom)
## and one shape (full or chip) while the spotlight wobbles a few px (the
## player scrolling inside it), wherever it sits and whatever the phone's
## height, instead of flipping every frame. Sweeps a stand-in target down the
## screen at several sizes.
## Scene: tools/tests/tutorial_dock_test.tscn

## Screen heights (design px at width 720): 3:2 up to 21:9 phones.
const HEIGHTS := [1080, 1280, 1440, 1560, 1680]
## Spotlight heights to try (design px).
const TARGET_HEIGHTS := [80, 240, 420, 600, 800]
## Step between spotlight positions (design px).
const SWEEP_STEP := 12
## Frames to let a position settle (the bubble glides) before watching it.
const SETTLE_FRAMES := 4
## Frames watched per position for flips.
const WATCH_FRAMES := 8
## How far (design px) the spotlight wobbles up and down while watched, like
## a scroll held under a finger. Pip must not swap sides over that.
const WOBBLE := 3
## Pip's lines to try: a long one (Day 1's story step) and a short one.
const TEXTS := [
	"Here's the story, one line per moment. The stamp up top says whether the quest succeeded, and the last line says what they brought home. Tap a letter again to fold it.",
	"Open [b]Your Guild[/b].",
]


func _ready() -> void:
	for height in HEIGHTS:
		await _sweep(height)
	finish()


## Sweeps the stand-in spotlight down a screen of one height.
func _sweep(height: int) -> void:
	get_tree().root.content_scale_size = Vector2i(720, height)
	get_window().size = Vector2i(720, height)
	GameState.day = 1
	var hall: Node = load("uid://dtw7iu2s1gibm").instantiate()  # Scenes/hall_main.tscn
	add_child(hall)
	hall.is_welcome_open = false
	await _frames(5)
	var tutorial = hall.tutorial
	var target := Control.new()
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hall.add_child(target)
	tutorial.start(1)
	var bad := 0
	var covered := 0
	for text in TEXTS:
		tutorial._steps = [{"text": text, "target": func(): return target}]
		tutorial._index = 0
		for target_height in TARGET_HEIGHTS:
			var y := 0
			while y + target_height <= height:
				target.position = Vector2(40, y)
				target.size = Vector2(640, target_height)
				await _frames(SETTLE_FRAMES)
				var states := {}
				var flips := 0
				var last := _state(tutorial)
				for i in WATCH_FRAMES:
					# a finger resting mid-scroll: the spotlight wobbles a few px
					target.position.y = y + (WOBBLE if i % 2 == 0 else -WOBBLE)
					await get_tree().process_frame
					var now := _state(tutorial)
					# staying put must never mean covering the spotlight
					if tutorial._text.visible and tutorial._ring.visible:
						var bubble := Rect2(tutorial._bubble_goal, tutorial._bubble.size)
						var ring := Rect2(tutorial._ring.position, tutorial._ring.size)
						if bubble.intersects(ring):
							covered += 1
					if now != last:
						flips += 1
					states[now] = true
					last = now
				# one move is fine (the wobble pushed it past a cut-off); a second is flicker
				if flips > 1:
					bad += 1
					if bad <= 12:
						check(false, "screen %d, target y=%d h=%d, %d-char line: %d flips between %s" % [height, y, target_height, text.length(), flips, states.keys()])
				y += SWEEP_STEP
	print("TEST INFO screen %d: %d flickering spots" % [height, bad])
	check(bad == 0, "screen %d: %d flickering spotlight positions" % [height, bad])
	check(covered == 0, "screen %d: Pip's full bubble covered the spotlight on %d frames" % [height, covered])
	tutorial.skip_tutorial()
	hall.queue_free()
	await _frames(2)


## Dock side and shape of Pip's bubble this frame.
func _state(tutorial) -> String:
	var side := "bottom" if tutorial._dock_bottom else "top"
	var shape := "full" if tutorial._text.visible else "chip"
	return "%s/%s" % [side, shape]


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
