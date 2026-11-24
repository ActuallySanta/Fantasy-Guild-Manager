extends TestCase
## End Day opens the "Going on a quest" screen (HallMain.is_quest_travel_open)
## before the night's result. Its "View quest report" button only shows after
## the rolled 2-4 s wait; pressing it (twice in one frame, to check the double
## tap) runs the dusk curtain into the Day Report once. The skip_quest_travel
## flag goes straight to the curtain. Reduced Motion keeps the wait and the
## button. The final battle's credits also wait for the press. On Day 1, Pip's
## walkthrough stands aside (no lock, no dim) so the button can be pressed.
## Scene: tools/tests/quest_travel_test.tscn

## Longest wait for the dusk curtain's midpoint (seconds).
const NIGHT_WAIT_SECONDS := 8.0
## Longest wait for the button to appear (seconds; the trip lasts at most 4).
const BUTTON_WAIT_SECONDS := 5.0
## Heroes made for each hall, enough for any party the test sends.
const ROSTER_SIZE := 8
## requirement_multiplier that makes a quest a sure win.
const SURE_WIN := 0.001
## The trip's length range, from the overlay's tunables (seconds).
const TRIP_MIN := 2.0
const TRIP_MAX := 4.0
## Frames to let refreshes and deferred calls settle.
const SETTLE_FRAMES := 4


func _ready() -> void:
	await _run()
	finish()


func _run() -> void:
	# first, while the autoloads still hold a fresh Day 1 run (as report_roam_test)
	await _test_tutorial_day_one()
	await _test_normal_night(false)
	await _test_skip_flag()
	await _test_normal_night(true)
	await _test_final_battle()


## A fresh hall on `day` with a roster of healthy heroes (as in boss_crawl_test).
## It is a child of this node (not of the root), so it neither loads nor saves a run.
func _make_hall(day: int) -> Node:
	GameState.day = day
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
	await get_tree().process_frame
	return hall


## Sends a sure-win party on entry 0 and denies the rest, so End Day can run.
func _send_first(hall: Node) -> void:
	var entry: Dictionary = hall.quest_entries[0]
	entry.quest.requirement_multiplier = SURE_WIN
	var slots: int = QuestScoring.get_slot_count(entry.quest)
	entry.party = hall.roster().slice(0, slots)
	entry.state = HallStyle.QUEST_STATE_SENT
	for i in range(1, hall.quest_entries.size()):
		hall.quest_entries[i].state = HallStyle.QUEST_STATE_DENIED


## Waits for the dusk curtain to hand over (night no longer falling).
func _wait_for_night(hall: Node) -> void:
	var waited := 0.0
	while hall.is_night_falling and waited < NIGHT_WAIT_SECONDS:
		await get_tree().process_frame
		waited += get_process_delta_time()
	await get_tree().process_frame


## Waits until the travel screen's button shows (or BUTTON_WAIT_SECONDS pass).
func _wait_for_button(overlay: Node) -> void:
	var waited := 0.0
	while not overlay.is_button_shown() and waited < BUTTON_WAIT_SECONDS:
		await get_tree().process_frame
		waited += get_process_delta_time()


## Sets Reduced Motion without writing the player's settings file.
func _set_reduce_motion(hall: Node, is_on: bool) -> void:
	hall.reduce_motion = is_on
	HallFx.reduce_motion = is_on


func _test_normal_night(is_reduced: bool) -> void:
	var label := "reduced motion: " if is_reduced else ""
	var hall := await _make_hall(3)
	_set_reduce_motion(hall, is_reduced)
	_send_first(hall)
	hall.end_day()
	await get_tree().process_frame
	var overlay: Node = hall.get_node_or_null("%OverlayQuestTravel")
	check(overlay != null, label + "travel overlay exists")
	if overlay == null:
		hall.queue_free()
		return
	check(hall.is_quest_travel_open, label + "travel screen open after End Day")
	check(hall.shown_report.is_empty(), label + "no report yet")
	check(overlay.visible, label + "travel overlay visible")
	check(not hall.get_node("%OverlayEndDay").visible, label + "End Day sheet hidden under travel")
	check(overlay.trip_seconds >= TRIP_MIN and overlay.trip_seconds <= TRIP_MAX, label + "trip length in range")
	await get_tree().process_frame
	check(not overlay.is_button_shown(), label + "button hidden at first")

	await _wait_for_button(overlay)
	check(overlay.is_button_shown(), label + "button shows after the wait")
	var button: Button = overlay.get_node("%ContinueButton")
	if is_reduced:
		check(button.modulate.a == 1.0, label + "button appears without a fade")
	# a double tap in one frame
	button.pressed.emit()
	button.pressed.emit()
	await get_tree().process_frame
	await _wait_for_night(hall)
	check(not hall.shown_report.is_empty(), label + "report opens after the press")
	check(not hall.is_quest_travel_open, label + "travel closed")
	check(not hall.is_night_falling, label + "night settled")
	check(not overlay.visible, label + "travel overlay hidden")
	_set_reduce_motion(hall, false)
	hall.queue_free()
	await get_tree().process_frame


func _test_skip_flag() -> void:
	var hall := await _make_hall(3)
	hall.skip_quest_travel = true
	_send_first(hall)
	hall.end_day()
	await get_tree().process_frame
	check(not hall.is_quest_travel_open, "skip flag: travel screen never opens")
	await _wait_for_night(hall)
	check(not hall.shown_report.is_empty(), "skip flag: report opens")
	hall.queue_free()
	await get_tree().process_frame


func _test_final_battle() -> void:
	var hall := await _make_hall(HallMain.FINAL_DAY)
	check(hall.quest_entries[0].final, "final day's first entry is the final")
	_send_first(hall)
	hall.end_day()
	await get_tree().process_frame
	check(hall.is_quest_travel_open, "final: travel screen open")
	check(hall.shown_credits.is_empty(), "final: no credits yet")
	var overlay: Node = hall.get_node("%OverlayQuestTravel")
	await _wait_for_button(overlay)
	check(overlay.is_button_shown(), "final: button shows")
	overlay.get_node("%ContinueButton").pressed.emit()
	await _wait_for_night(hall)
	check(not hall.shown_credits.is_empty(), "final: credits open after the press")
	check(not hall.is_quest_travel_open, "final: travel closed")
	hall.queue_free()
	await get_tree().process_frame


func _settle() -> void:
	for i in SETTLE_FRAMES:
		await get_tree().process_frame


## Day 1 with Pip's walkthrough running: the travel screen's button stays
## usable (the tutorial neither dims over it nor disables it), and after the
## press Pip picks up on the Day Report.
func _test_tutorial_day_one() -> void:
	var hall: Node = load("uid://dtw7iu2s1gibm").instantiate()  # Scenes/hall_main.tscn
	add_child(hall)
	await _settle()
	var tutorial: Node = hall.tutorial
	check(tutorial != null and tutorial.is_running(), "tutorial: Pip's walkthrough started")
	if tutorial == null or not tutorial.is_running():
		hall.queue_free()
		return
	hall.open_assign(0)
	await _settle()
	hall.toggle_in_party(hall.roster()[0])
	await _settle()
	hall.close_screen()
	await _settle()
	hall.open_end_check()
	await _settle()
	hall.end_day()
	await _settle()
	var overlay: Node = hall.get_node("%OverlayQuestTravel")
	check(hall.is_quest_travel_open, "tutorial: travel screen open")
	check(not tutorial.visible, "tutorial: Pip stands aside during travel")
	await _wait_for_button(overlay)
	await _settle()
	var button: Button = overlay.get_node("%ContinueButton")
	check(overlay.is_button_shown(), "tutorial: button shows and is not locked")
	button.pressed.emit()
	await _wait_for_night(hall)
	await _settle()
	check(not hall.shown_report.is_empty(), "tutorial: report opens after the press")
	check(tutorial.is_running() and tutorial.visible, "tutorial: Pip is back on the report")
	hall.queue_free()
	await get_tree().process_frame
