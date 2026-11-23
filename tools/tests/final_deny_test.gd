extends TestCase
## The day-50 final battle can never be denied (it would leave the run without
## an ending); every other quest, bosses included, still can. Covers the rule
## (HallRules.can_deny), the hall action and the AI bridge's deny.
## Scene: tools/tests/final_deny_test.tscn

## Heroes made for each hall.
const ROSTER_SIZE := 8


func _ready() -> void:
	await _run()
	finish()


func _run() -> void:
	_test_rule()
	await _test_hall_action(HallMain.FINAL_DAY, true)
	await _test_hall_action(49, false)
	await _test_hall_action(10, false)


## A fresh hall on `day` (a child of this node, so it neither loads nor saves).
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


## The pure rule: only the final entry is refused.
func _test_rule() -> void:
	var normal := HallRules.new_entry(null, false)
	var boss := HallRules.new_entry(null, true)
	var final := HallRules.new_entry(null, true)
	final.final = true
	check(HallRules.can_deny(normal), "a normal quest can be denied")
	check(HallRules.can_deny(boss), "a boss quest can be denied")
	check(not HallRules.can_deny(final), "the final cannot be denied")


## Denies board quest 0 on `day` through the hall action and the bridge.
## expect_refused: true on the final day.
func _test_hall_action(day: int, expect_refused: bool) -> void:
	var hall := await _make_hall(day)
	var label := "day %d" % day
	check(not hall.quest_entries.is_empty(), "%s has a board" % label)
	if hall.quest_entries.is_empty():
		hall.queue_free()
		return
	check(hall.quest_entries[0].final == expect_refused, "%s final flag is %s" % [label, expect_refused])
	var standing_before: int = GuildUpgrades.standing

	# the hall action
	hall.open_assign(0)
	hall.deny_quest()
	var denied: bool = hall.quest_entries[0].state == HallStyle.QUEST_STATE_DENIED
	check(denied != expect_refused, "%s hall deny %s" % [label, "refused" if expect_refused else "works"])
	if expect_refused:
		check(GuildUpgrades.standing == standing_before, "%s refused deny costs no standing" % label)
		check(hall.undecided_count() >= 1, "%s final still undecided" % label)
	# undo it directly (the hall moves on to the next quest after a deny)
	hall.quest_entries[0].state = HallStyle.QUEST_STATE_OPEN

	# the AI bridge
	var reason: String = AgentBridgeActions._deny(hall, 0)
	check((reason != "") == expect_refused, "%s bridge deny %s (reason: '%s')" % [label, "refused" if expect_refused else "works", reason])
	if expect_refused:
		check(reason.contains("cannot be denied"), "%s bridge says why" % label)
		check(hall.quest_entries[0].state == HallStyle.QUEST_STATE_OPEN, "%s final still open after bridge deny" % label)
	hall.queue_free()
	await get_tree().process_frame
