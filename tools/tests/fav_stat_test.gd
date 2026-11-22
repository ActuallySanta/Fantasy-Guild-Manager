extends TestCase
## Favored-stat combos (incl. Pluck) never index a missing stat.
## Scene: tools/tests/fav_stat_test.tscn

## Every favStat value the content uses.
const FAV_VALUES := [0, 1, 2, 3, 4, 10, 12, 13, 20, 23, 30, 40]
const BOARD_DAYS := [32, 33, 39, 40, 50]
## How many times to replay a quest looking for a good-odds win.
const MAX_TRIES := 200


func _party(size: int) -> Array[GuildCharacter]:
	var party: Array[GuildCharacter] = []
	for i in size:
		var hero := GuildCharacter.new()
		hero.injury_level = GuildCharacter.InjuryLevel.HEALTHY
		for s in 4:
			hero.stats[s] = 500
		hero.pluck = 5
		party.append(hero)
	return party


func _ready() -> void:
	var saved_day := GameState.day
	var party := _party(3)
	for value: int in FAV_VALUES:
		var quest := CreatedQuest.new(1, 5)
		quest.favStat = value
		var chance: float = quest.calcSuccessChance(party)
		check(chance > 0.0, "favStat %d odds computed" % value)
		for opt in quest.trained_stat_options():
			check(opt >= 0 and opt <= 3, "favStat %d option %d trainable" % [value, opt])
		for i in 30:
			var rolled := quest.roll_trained_stat()
			check(rolled >= 0 and rolled <= 3, "favStat %d rolled %d trainable" % [value, rolled])
	# Pluck alone falls back to the region stat
	var pluck_quest := CreatedQuest.new(1, 5)
	pluck_quest.favStat = 4
	check(pluck_quest.trained_stat_options() == [pluck_quest.region_favored_stat()], "pluck falls back to region")

	for day: int in BOARD_DAYS:
		GameState.day = day
		for entry in HallRules.build_day_quests(day, 60, false):
			var won := false
			for attempt in MAX_TRIES:
				entry.party = _party(mini(entry.quest.maxAdventurers, 8))
				entry.quest.found_items.clear()
				var result: Dictionary = HallRules.play_quest(entry, day)
				var trained: int = result.trained_stat
				check(trained >= -1 and trained <= 3, "day %d trained_stat %d valid" % [day, trained])
				if result.succeeded and trained != -1:
					won = true
					break
			check(won, "day %d %s reached a good-odds win" % [day, entry.quest.questTitle])
	GameState.day = saved_day
	finish()
