extends TestCase
## Smoke test: the harness runs and the autoloads and static rules are reachable.
## Scene: tools/tests/smoke_test.tscn


func _ready() -> void:
	check(GuildUpgrades.MAX_LEVEL == 5, "GuildUpgrades.MAX_LEVEL is 5")
	check(HallRules.quests_per_day(11) == 5, "quests_per_day(11) is 5")
	finish()
