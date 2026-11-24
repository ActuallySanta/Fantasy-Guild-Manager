extends TestCase
## Day 1's last tutorial step (Open the Doors) is a "free" step: Pip steps back
## so the player can scroll the whole Day Report before starting Day 2. Plays
## Day 1 with the tutorial on (send Uncle John on a quest, End Day), opens the
## report's letter, walks Pip to that last step, then checks: no dim, no cover,
## no button locks, Pip's bubble hidden, the ring on Open the Doors, and the
## report's scroll area moves and stays where the player put it.
## Run in a window (no --headless), it also scrolls with a real mouse wheel.
## Scene: tools/tests/report_roam_test.tscn

## Frames to wait for refreshes to settle.
const SETTLE_FRAMES := 5
## Frames to wait for the dusk before the report shows (about 10 s at 60 fps).
const REPORT_WAIT_FRAMES := 600
## Wheel ticks sent in the windowed check.
const WHEEL_TICKS := 6


func _ready() -> void:
	await _run()
	finish()


func _run() -> void:
	var hall: Node = load("uid://dtw7iu2s1gibm").instantiate()  # Scenes/hall_main.tscn
	add_child(hall)
	hall.skip_quest_travel = true  # no "Going on a quest" wait (quest_travel_test covers it)
	await _settle()
	var tutorial: OverlayTutorial = hall.tutorial
	check(tutorial != null and tutorial.is_running(), "Pip's Day 1 walkthrough started")
	if tutorial == null or not tutorial.is_running():
		return

	# play Day 1 through the hall's own actions (Pip waits on its welcome card)
	hall.open_assign(0)
	await _settle()
	hall.toggle_in_party(hall.roster()[0])
	await _settle()
	hall.close_screen()
	await _settle()
	hall.open_end_check()
	await _settle()
	hall.end_day()
	var report: Control = hall.get_node("%OverlayReport")
	for frame in REPORT_WAIT_FRAMES:
		if report.is_visible_in_tree() and not hall.is_night_falling:
			break
		await get_tree().process_frame
	await _settle()
	check(report.is_visible_in_tree(), "the Day Report is showing")
	if not report.is_visible_in_tree():
		return

	# open the letter (what the read_letter step asks for), then walk Pip to
	# the last step, the one waiting on Open the Doors
	var letter: Node = _first_letter(report)
	if letter != null and letter.is_folded:
		letter.toggle_folded()
	await _settle()
	tutorial.start(1)
	while tutorial.is_running() and not tutorial._steps[tutorial._index].get("free", false):
		tutorial._advance()
	check(tutorial.is_running(), "Pip reached the Open the Doors step")
	if not tutorial.is_running():
		return
	for frame in 30:
		await get_tree().process_frame

	var step: Dictionary = tutorial._steps[tutorial._index]
	var action_button: Button = report.get_node("%ActionButton")
	check(step.get("on", "") == "new_day", "the free step waits for the new day")
	check(tutorial._is_free(step), "the Open the Doors step is free")
	check(tutorial._blockers.all(func(blocker): return not blocker.visible), "nothing is dimmed")
	check(not tutorial._cover.visible, "nothing covers the spotlight")
	check(not tutorial._bubble.visible, "Pip's bubble is hidden")
	check(tutorial._locked.is_empty(), "Pip locks no buttons")
	check(not action_button.disabled, "Open the Doors is usable")
	check(tutorial._ring.visible, "the ring is showing")
	var ring_rect := Rect2(tutorial._ring.global_position, tutorial._ring.size)
	check(ring_rect.encloses(action_button.get_global_rect()), "the ring sits on Open the Doors")

	# the report scrolls, and Pip doesn't pull it back
	var scroll: ScrollContainer = report.get_node("%Scroll")
	var bar := scroll.get_v_scroll_bar()
	var scroll_room: float = bar.max_value - bar.page
	print("TEST INFO report scroll room %.0f px (content %.0f, page %.0f)" % [scroll_room, bar.max_value, bar.page])
	if scroll_room <= 1.0:
		print("TEST INFO the report fits on screen tonight, so there was nothing to scroll")
		return
	scroll.scroll_vertical = 0
	await _settle()
	if DisplayServer.get_name() == "headless":
		# headless Godot routes no mouse input to the GUI: set the scroll instead
		scroll.scroll_vertical = int(scroll_room)
	else:
		var center: Vector2 = get_viewport().get_final_transform() * scroll.get_global_rect().get_center()
		for tick in WHEEL_TICKS:
			await _wheel(center)
	for frame in 30:
		await get_tree().process_frame
	print("TEST INFO scrolled to %d" % scroll.scroll_vertical)
	check(scroll.scroll_vertical > 0, "the report scrolled down")
	check(tutorial.is_running() and tutorial._steps[tutorial._index] == step, "Pip still waits on Open the Doors")

	# Open the Doors still finishes the walkthrough
	hall.close_report()
	for frame in REPORT_WAIT_FRAMES:
		if tutorial.done.get(1, false):
			break
		await get_tree().process_frame
	# (Day 2's walkthrough starts straight after, so Pip is running again)
	check(tutorial.done.get(1, false), "Open the Doors finished Day 1's walkthrough")
	check(GameState.day == 2, "Day 2 started")


## Waits a few frames for queued refreshes and animations to settle.
func _settle() -> void:
	for i in SETTLE_FRAMES:
		await get_tree().process_frame


## The first Day Report letter (report_entry.gd) under `root`, or null.
func _first_letter(root: Node) -> Node:
	for node in root.find_children("*", "", true, false):
		var script: Script = node.get_script()
		if script != null and script.resource_path.ends_with("report_entry.gd"):
			return node
	return null


## One mouse-wheel tick down at `position` (window pixels).
func _wheel(position: Vector2) -> void:
	for is_pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_WHEEL_DOWN
		event.pressed = is_pressed
		event.factor = 1.0
		event.position = position
		event.global_position = position
		Input.parse_input_event(event)
		await get_tree().process_frame
