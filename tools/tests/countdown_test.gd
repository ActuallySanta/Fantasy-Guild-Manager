extends TestCase
## Test: the header countdown helpers on HallMain count to the next boss day.
## The HallMain here is built with new() and never added to the tree: the
## countdown queries only read GameState.day and HallRules, no nodes.
## Scene: tools/tests/countdown_test.tscn


func _ready() -> void:
	var hall := HallMain.new()
	var start_day: int = GameState.day

	GameState.day = 11
	check(hall.days_until_next_boss() == 9, "day 11: 9 days to day 20")
	check(not hall.next_boss_is_final(), "day 11: next boss is not the final")
	check(hall.days_until_drake() == 9, "day 11: days_until_drake wrapper agrees")
	GameState.day = 12
	check(hall.days_until_next_boss() == 8, "day 12: 8 days to day 20")
	GameState.day = 20
	check(hall.days_until_next_boss() == 0, "day 20: boss is today")
	GameState.day = 41
	check(hall.days_until_next_boss() == 9, "day 41: 9 days to day 50")
	check(hall.next_boss_is_final(), "day 41: next boss is the final")
	GameState.day = 51
	check(hall.days_until_next_boss() == -1, "day 51: no boss left")
	check(not hall.next_boss_is_final(), "day 51: no final left")

	GameState.day = start_day
	hall.free()
	finish()
