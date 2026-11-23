extends TestCase
## Tapping a filled party seat on Assign Party takes that hero back out of the
## party (party_slot.gd -> HallMain.toggle_in_party). A quest left with nobody
## goes back to open. Run in a window (no --headless), the tap is a real mouse
## press and release on the seat; under run_test.sh (headless, where Godot
## routes no mouse input to the GUI) it checks the seat's tap wiring instead.
## Scene: tools/tests/seat_tap_test.tscn

## Day used for the test board (a normal day with 2-slot-or-larger quests likely).
const TEST_DAY := 11
## Heroes in the roster.
const ROSTER_SIZE := 4
## Frames to wait for refreshes to settle.
const SETTLE_FRAMES := 5
## How far below a seat's top edge the test taps (design px).
const TAP_INSET := 30.0


func _ready() -> void:
	await _run()
	finish()


func _run() -> void:
	GameState.day = TEST_DAY
	GuildUpgrades.reset()
	GuildUpgrades.gold = 5000
	GuildUpgrades.standing = 60
	CharacterContainer.active_characters.clear()
	CharacterContainer.released_characters.clear()
	for i in ROSTER_SIZE:
		CharacterContainer.active_characters.append(GuildCharacter.new())
	GuildUpgrades.sync_characters()
	var hall: Node = load("uid://dtw7iu2s1gibm").instantiate()  # Scenes/hall_main.tscn
	add_child(hall)
	hall.is_welcome_open = false
	if hall.tutorial and hall.tutorial.is_running():
		hall.tutorial.skip_tutorial()
	await _settle()

	hall.open_assign(0)
	await _settle()
	var hero: GuildCharacter = hall.roster()[0]
	hall.toggle_in_party(hero)
	await _settle()
	var entry: Dictionary = hall.quest_entries[0]
	check(entry.party.has(hero), "the hero was seated by toggle_in_party")
	check(entry.state == HallStyle.QUEST_STATE_SENT, "seating someone sent the quest")

	var seat := _filled_seat(hall)
	check(seat != null, "Assign Party shows a filled seat")
	if seat == null:
		hall.queue_free()
		return
	# the game stretches its 720x1280 canvas to the window, so map the seat's
	# canvas position to window pixels (where mouse events are given)
	# headless Godot delivers no mouse input to the GUI: there, check the
	# seat's wiring by emitting its tap signal (run this scene in a window,
	# without --headless, to check a real tap)
	if DisplayServer.get_name() == "headless":
		seat.emit_signal("pressed")
		await _settle()
		check(not entry.party.has(hero), "the filled seat's tap removed the hero")
		check(entry.state == HallStyle.QUEST_STATE_OPEN, "an emptied quest went back to open")
		hall.queue_free()
		return
	# the footer can cover the seat in a short window: scroll it into view
	var scroll := _scroll_parent(seat)
	if scroll != null:
		scroll.ensure_control_visible(seat)
		await _settle()
	var seat_rect := seat.get_global_rect()
	var tap_point := Vector2(seat_rect.get_center().x, seat_rect.position.y + TAP_INSET)
	# the game stretches its canvas to the window, so map canvas to window pixels
	var window_point: Vector2 = get_viewport().get_final_transform() * tap_point
	var hovered := await _hover(window_point)
	check(hovered == seat or (hovered != null and seat.is_ancestor_of(hovered)),
			"the tap point is on the seat (hovered %s)" % [hovered.get_path() if hovered else "nothing"])
	await _tap(window_point)
	await _settle()
	check(not entry.party.has(hero), "tapping the filled seat removed the hero")
	check(entry.state == HallStyle.QUEST_STATE_OPEN, "an emptied quest went back to open")
	check(_filled_seat(hall) == null, "no filled seat remains")
	hall.queue_free()


## Waits a few frames for queued refreshes and animations to settle.
func _settle() -> void:
	for i in SETTLE_FRAMES:
		await get_tree().process_frame


## The first visible party seat showing a hero (its portrait is visible), or null.
func _filled_seat(hall: Node) -> Control:
	for node in hall.find_children("*", "PanelContainer", true, false):
		var script: Script = node.get_script()
		if script == null or not script.resource_path.ends_with("party_slot.gd"):
			continue
		if node.is_visible_in_tree() and node.get_node("%Portrait").visible:
			return node
	return null


## The nearest ScrollContainer above `node`, or null.
func _scroll_parent(node: Node) -> ScrollContainer:
	var parent := node.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return parent
		parent = parent.get_parent()
	return null


## Moves the mouse to `position` (window pixels) and returns the control under it.
func _hover(position: Vector2) -> Control:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Input.parse_input_event(motion)
	await get_tree().process_frame
	await get_tree().process_frame
	return get_viewport().gui_get_hovered_control()


## A left press and release at `position` (window pixels), like a tap.
## Needs a window: headless Godot doesn't deliver mouse input to the GUI.
func _tap(position: Vector2) -> void:
	for is_pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = is_pressed
		event.position = position
		event.global_position = position
		Input.parse_input_event(event)
		await get_tree().process_frame
