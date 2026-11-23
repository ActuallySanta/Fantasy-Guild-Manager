extends TestCase
## Injuries follow the odds (QuestInjuries), a failed quest adds a retreat
## injury, and heroes who set out Healthy or Sore can't die on a won quest.
## Scene: tools/tests/injuries_test.tscn

## Quests per calibration combination at odds under 100%.
const RUNS_NORMAL := 3000
## Quests per combination at odds of 100% or more, where the target is small
## (0.1-0.2 injuries per hero) so a bigger sample keeps the check sound.
const RUNS_LOW_TARGET := 12000
## Allowed relative error of the measured mean against the target table.
const TOLERANCE := 0.15
## Won quests played for each death-rule check.
const DEATH_RULE_WINS := 2000
## Odds used for the death-rule checks (percent).
const DEATH_RULE_ODDS := 60.0
## Rank used for the death-rule and retreat checks (S).
const DEATH_RULE_RANK := 5


func _ready() -> void:
	_test_targets()
	_test_calibration()
	_test_death_rule()
	_test_injure_character()
	finish()


## A typed party of this many fresh Healthy heroes.
func _fresh_party(size: int) -> Array[GuildCharacter]:
	var party: Array[GuildCharacter] = []
	for i in size:
		party.append(GuildCharacter.new())
	return party


func _test_targets() -> void:
	var cases := {130.0: 0.1, 100.0: 0.2, 85.0: 0.425, 50.0: 1.2, 20.0: 1.2, 160.0: 0.1}
	for odds: float in cases:
		check_near(QuestInjuries.target_injuries_per_hero(odds), cases[odds], 0.0001, "target at %d" % odds)


## Mean fight injuries per hero within TOLERANCE of the table, plus the retreat
## and the story/hit agreement, over many simulated quests.
func _test_calibration() -> void:
	for rank in [0, 3, 5]:
		for odds in [60.0, 80.0, 100.0, 130.0]:
			for party_size in [1, 3]:
				_calibrate(rank, odds, party_size)


func _calibrate(rank: int, odds: float, party_size: int) -> void:
	var runs := RUNS_LOW_TARGET if odds >= 100.0 else RUNS_NORMAL
	var fight_hits := 0
	var story_mismatches := 0
	var retreat_mismatches := 0
	var no_hit_story_with_injury := 0
	for run in runs:
		var quest := CreatedQuest.new(rank, 3)
		var party := _fresh_party(party_size)
		var story := quest.generateResults(party, odds)
		var failed := not QuestScoring.did_succeed(story)
		# each INJURED in the story is one hit, plus the one retreat line on a loss
		var injured_words := story.count("INJURED")
		var hits := injured_words - (1 if failed else 0)
		var level_gain := 0
		var anyone_dead := false
		for hero in party:
			level_gain += hero.injury_level
			anyone_dead = anyone_dead or hero.injury_level >= GuildCharacter.InjuryLevel.DEAD
			# every hero takes the retreat injury: at least 1 level on a loss
			if failed and hero.injury_level < GuildCharacter.InjuryLevel.DEAD and hero.injury_level < 1:
				retreat_mismatches += 1
		fight_hits += hits
		if hits == 0 and not failed and level_gain != 0:
			no_hit_story_with_injury += 1
		# without deaths capping a hero, levels must equal hits plus the retreat
		if not anyone_dead and level_gain != hits + (party_size if failed else 0):
			story_mismatches += 1
	var measured := float(fight_hits) / runs / party_size
	var target := QuestInjuries.target_injuries_per_hero(odds)
	print("TEST MEASURE rank %d odds %d party %d: %.4f injuries/hero (target %.4f, %+.1f%%)" % [
		rank, odds, party_size, measured, target, (measured / target - 1.0) * 100.0])
	check_near(measured, target, target * TOLERANCE, "fight injuries per hero (rank %d odds %d party %d)" % [rank, odds, party_size])
	check(story_mismatches == 0, "levels match story hits plus retreat (rank %d odds %d party %d): %d off" % [rank, odds, party_size, story_mismatches])
	check(retreat_mismatches == 0, "every hero took the retreat injury (rank %d odds %d party %d): %d off" % [rank, odds, party_size, retreat_mismatches])
	check(no_hit_story_with_injury == 0, "no injury without an INJURED line (rank %d odds %d party %d)" % [rank, odds, party_size])


## Plays quests until DEATH_RULE_WINS were won, with one hero who set out at the
## given level. Returns {deaths, listed_wrong, retreat_line_on_win}.
func _won_quests_with(start_level: int) -> Dictionary:
	var deaths := 0
	var listed_wrong := 0
	var retreat_on_win := 0
	var wins := 0
	var guard := 0
	while wins < DEATH_RULE_WINS and guard < DEATH_RULE_WINS * 20:
		guard += 1
		var quest := CreatedQuest.new(DEATH_RULE_RANK, 3)
		var party := _fresh_party(2)
		party[0].injury_level = start_level
		var story := quest.generateResults(party, DEATH_RULE_ODDS)
		if not QuestScoring.did_succeed(story):
			continue
		wins += 1
		if story.contains("beaten back"):
			retreat_on_win += 1
		for hero in party:
			var is_dead := hero.injury_level >= GuildCharacter.InjuryLevel.DEAD
			if hero == party[0] and is_dead:
				deaths += 1
			if is_dead != quest.dead_adventurers.has(hero):
				listed_wrong += 1
			# two heroes can roll the same name, which makes the death line ambiguous
			var name_is_unique: bool = party[0].name != party[1].name
			if name_is_unique and is_dead != story.contains("[b]%s[/b] succumbed" % hero.name):
				listed_wrong += 1
	return {"deaths": deaths, "listed_wrong": listed_wrong, "retreat_on_win": retreat_on_win, "wins": wins}


func _test_death_rule() -> void:
	var sore := _won_quests_with(GuildCharacter.InjuryLevel.SORE)
	print("TEST MEASURE won quests, hero started Sore: %d deaths in %d wins" % [sore.deaths, sore.wins])
	check(sore.wins == DEATH_RULE_WINS, "played enough won quests (Sore)")
	check(sore.deaths == 0, "a hero who set out Sore never dies on a win: %d deaths" % sore.deaths)
	check(sore.listed_wrong == 0, "dead_adventurers and death lines match who died (Sore): %d off" % sore.listed_wrong)
	check(sore.retreat_on_win == 0, "no retreat line on a win")

	var hurt := _won_quests_with(GuildCharacter.InjuryLevel.LIGHTLY_INJURED)
	print("TEST MEASURE won quests, hero started Hurt: %d deaths in %d wins" % [hurt.deaths, hurt.wins])
	check(hurt.deaths > 0, "a hero who set out Hurt can die on a win")
	check(hurt.listed_wrong == 0, "dead_adventurers and death lines match who died (Hurt): %d off" % hurt.listed_wrong)


func _test_injure_character() -> void:
	var hero := GuildCharacter.new()
	hero.injury_level = GuildCharacter.InjuryLevel.GRAVELY_INJURED
	check(hero.injure_character(false) == false, "protected hit at Gravely returns false")
	check(hero.injury_level == GuildCharacter.InjuryLevel.GRAVELY_INJURED, "protected hero stops at Gravely")
	check(hero.injure_character(true) == true, "unprotected hit at Gravely kills")
	check(hero.injury_level == GuildCharacter.InjuryLevel.DEAD, "hero is dead")
	var sore := GuildCharacter.new()
	check(sore.injure_character(false) == false and sore.injury_level == GuildCharacter.InjuryLevel.SORE, "protected hit still injures below Gravely")
