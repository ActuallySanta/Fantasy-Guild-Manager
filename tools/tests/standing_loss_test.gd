extends TestCase
## A failed quest costs half a win's standing (rounded up), clamped at the floor.
## Scene: tools/tests/standing_loss_test.tscn

## Most attempts made to roll a loss before giving up.
const MAX_TRIES := 50
## Rank of the quest used to force a loss (S).
const LOSS_RANK := 5


func _ready() -> void:
	_test_loss_values()
	_test_loss_costs_standing()
	_test_loss_clamped_at_floor()
	finish()


## A rank-5 quest and a hopeless 1-stat hero: loses nearly always.
func _loss_entry() -> Dictionary:
	var quest := CreatedQuest.new(LOSS_RANK, 3)
	var hero := GuildCharacter.new()
	for stat_index in hero.stats.size():
		hero.stats[stat_index] = 1
	hero.reset_temp_stats()
	var entry := HallRules.new_entry(quest, false)
	entry.party = [hero]
	return entry


func _test_loss_values() -> void:
	var expected := {-1: 1, 0: 1, 1: 1, 2: 2, 3: 2, 4: 3, 5: 3}
	for rank: int in expected:
		var quest := CreatedQuest.new(rank, 3)
		check(HallRules.standing_for_loss(quest) == expected[rank], "standing_for_loss(rank %d) == %d" % [rank, expected[rank]])
	check(HallRules.standing_for_win(CreatedQuest.new(5, 3)) == 6, "rank 5 win pays 6")


## Plays until a loss. Returns that result, or {} when nothing lost in MAX_TRIES.
func _play_until_loss(start_standing: int) -> Dictionary:
	for attempt in MAX_TRIES:
		GuildUpgrades.standing = start_standing
		var result := HallRules.play_quest(_loss_entry(), 3)
		if not result.succeeded:
			return result
	return {}


func _test_loss_costs_standing() -> void:
	var result := _play_until_loss(50)
	check(not result.is_empty(), "forced a loss")
	if result.is_empty():
		return
	check(result.standing == -3, "result standing is -3")
	check(GuildUpgrades.standing == 47, "standing dropped by 3")


func _test_loss_clamped_at_floor() -> void:
	var result := _play_until_loss(GuildUpgrades.MINIMUM_STANDING + 1)
	check(not result.is_empty(), "forced a loss at the floor")
	if result.is_empty():
		return
	check(GuildUpgrades.standing == GuildUpgrades.MINIMUM_STANDING, "standing stops at the floor")
	check(result.standing == -1, "only the standing actually lost is reported")
