extends TestCase
## Trouble test: HallLedger.trouble_reason ("failures", "injuries" or ""), old
## saves without failed_by_day, and the header showing the red strip over the
## gold one when both apply.
## Scene: tools/tests/trouble_test.tscn

## Day used for the header check.
const TEST_DAY := 11
## Frames to wait for refreshes to settle.
const SETTLE_FRAMES := 5


func _hero(injury: int = GuildCharacter.InjuryLevel.HEALTHY) -> GuildCharacter:
	var hero := GuildCharacter.new()
	hero.injury_level = injury as GuildCharacter.InjuryLevel
	return hero


func _ready() -> void:
	var healthy := [_hero(), _hero(), _hero(), _hero()]
	check(HallLedger.trouble_reason({"failed_by_day": {9: 1, 10: 1}}, healthy, 11) == "failures", "2 losses over days 9-10 on day 11")
	check(HallLedger.trouble_reason({"failed_by_day": {9: 1, 10: 1}}, healthy, 13) == "", "the losses are out of the window by day 13")
	check(HallLedger.trouble_reason({"failed_by_day": {10: 1}}, healthy, 11) == "", "one loss isn't trouble")
	var half_hurt := [_hero(), _hero(), _hero(GuildCharacter.InjuryLevel.LIGHTLY_INJURED), _hero(GuildCharacter.InjuryLevel.LIGHTLY_INJURED)]
	check(HallLedger.trouble_reason({}, half_hurt, 11) == "injuries", "half the roster Hurt")
	var sore := [_hero(), _hero(GuildCharacter.InjuryLevel.SORE), _hero(GuildCharacter.InjuryLevel.SORE)]
	check(HallLedger.trouble_reason({}, sore, 11) == "", "Sore heroes don't count")
	check(HallLedger.trouble_reason({"gold_earned": 0}, healthy, 11) == "", "an old save without failed_by_day: no trouble, no crash")

	await _header_check()
	finish()


func _header_check() -> void:
	GameState.day = TEST_DAY
	GuildUpgrades.reset()
	GuildUpgrades.gold = 0
	GuildUpgrades.standing = 60
	CharacterContainer.active_characters.clear()
	CharacterContainer.released_characters.clear()
	CharacterContainer.hireable_characters.clear()
	CharacterContainer.active_characters.append(GuildCharacter.new())
	var hall: Node = load("uid://dtw7iu2s1gibm").instantiate()  # Scenes/hall_main.tscn
	add_child(hall)
	hall.is_welcome_open = false
	if hall.tutorial and hall.tutorial.is_running():
		hall.tutorial.skip_tutorial()
	await _settle()
	var header: Node = hall.get_node("%Header")
	var title: Label = header.get_node("%DangerTitle")

	hall.run_stats["failed_by_day"] = {10: 2}
	hall.refresh()
	await _settle()
	check(hall.is_one_death_from_falling(), "setup: one hero left and short of gold")
	check(title.text == HallHeader.DANGER_TITLE, "both apply: the red strip wins (got '%s')" % title.text)

	# a second hero removes the danger, leaving the trouble strip
	CharacterContainer.active_characters.append(GuildCharacter.new())
	hall.refresh()
	await _settle()
	check(title.text == HallHeader.TROUBLE_TITLE, "trouble alone: the gold strip (got '%s')" % title.text)
	CharacterContainer.active_characters.clear()
	GuildUpgrades.reset()


func _settle() -> void:
	for i in SETTLE_FRAMES:
		await get_tree().process_frame
