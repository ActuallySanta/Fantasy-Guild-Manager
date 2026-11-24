extends TestCase
## Boss days (not the final) show the boss crawl after End Day, and its
## Continue button (HallMain.close_boss_crawl) opens the Day Report. A normal
## day goes straight to the report. The final keeps its credits (not tested here).
## Scene: tools/tests/boss_crawl_test.tscn

## Longest wait for the dusk curtain's midpoint (seconds).
const NIGHT_WAIT_SECONDS := 8.0
## Heroes made for each hall, enough for any party the test sends.
const ROSTER_SIZE := 8
## requirement_multiplier that makes a quest a sure win / a sure loss.
const SURE_WIN := 0.001
const SURE_LOSS := 1000.0


func _ready() -> void:
	await _run()
	finish()


func _run() -> void:
	await _test_boss_day()
	await _test_normal_day()


## A fresh hall on `day` with a roster of healthy heroes. It is a child of this
## node (not of the root), so it neither loads nor saves a run.
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
	hall.skip_quest_travel = true  # no "Going on a quest" wait (quest_travel_test covers it)
	hall.is_welcome_open = false
	if hall.tutorial and hall.tutorial.is_running():
		hall.tutorial.skip_tutorial()
	await get_tree().process_frame
	return hall


## Sends heroes on entry `index`, taking from `first_hero` on.
func _send(hall: Node, index: int, first_hero: int) -> void:
	var entry: Dictionary = hall.quest_entries[index]
	var slots: int = QuestScoring.get_slot_count(entry.quest)
	entry.party = hall.roster().slice(first_hero, first_hero + slots)
	entry.state = HallStyle.QUEST_STATE_SENT


## Waits for the dusk curtain to hand over (night no longer falling).
func _wait_for_night(hall: Node) -> void:
	var waited := 0.0
	while hall.is_night_falling and waited < NIGHT_WAIT_SECONDS:
		await get_tree().process_frame
		waited += get_process_delta_time()
	await get_tree().process_frame


func _crawl_of(hall: Node) -> Dictionary:
	var crawl: Variant = hall.get(&"shown_boss_crawl")
	return crawl if crawl is Dictionary else {}


func _test_boss_day() -> void:
	var hall := await _make_hall(20)
	check(hall.quest_entries.size() == 2, "day 20 has two boss entries")
	if hall.quest_entries.size() != 2:
		hall.queue_free()
		return
	hall.quest_entries[0].quest.requirement_multiplier = SURE_WIN
	hall.quest_entries[1].quest.requirement_multiplier = SURE_LOSS
	_send(hall, 0, 0)
	_send(hall, 1, 3)
	hall.end_day()
	await _wait_for_night(hall)

	var crawl := _crawl_of(hall)
	check(crawl.get("day", 0) == 20, "crawl is for day 20")
	check(crawl.get("results", []).size() == 2, "crawl holds both fights")
	check(hall.shown_report.is_empty(), "no Day Report while the crawl shows")
	var results: Array = crawl.get("results", [])
	if results.size() == 2:
		check(results[0].succeeded and not results[1].succeeded, "one fight won, one lost")
	check(not hall.night_save.is_empty(), "the night stays saved as the report during the crawl")
	check(hall.get_node("%OverlayBossCrawl").visible, "crawl overlay shows")
	check(not hall.get_node("%OverlayReport").visible, "report overlay hidden during the crawl")

	check(hall.has_method("close_boss_crawl"), "close_boss_crawl exists")
	if hall.has_method("close_boss_crawl"):
		hall.close_boss_crawl()
	await get_tree().process_frame
	check(_crawl_of(hall).is_empty(), "crawl cleared by Continue")
	check(hall.shown_report.get("results", []).size() == 2, "Continue opens the report with both fights")
	check(hall.night_save.is_empty(), "night save cleared by Continue")
	check(hall.get_node("%OverlayReport").visible, "report overlay shows after Continue")
	check(not hall.get_node("%OverlayBossCrawl").visible, "crawl overlay hidden after Continue")
	hall.queue_free()
	await get_tree().process_frame


func _test_normal_day() -> void:
	var hall := await _make_hall(11)
	_send(hall, 0, 0)
	# End Day waits for every quest to be sent or denied
	for i in range(1, hall.quest_entries.size()):
		hall.quest_entries[i].state = HallStyle.QUEST_STATE_DENIED
	hall.end_day()
	await _wait_for_night(hall)
	check(not hall.shown_report.is_empty(), "day 11 shows the Day Report directly")
	check(_crawl_of(hall).is_empty(), "day 11 has no crawl")
	hall.queue_free()
	await get_tree().process_frame
