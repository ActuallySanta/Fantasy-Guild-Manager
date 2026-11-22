## Hall rules: building the day's quests and playing one out. No state and no
## nodes: every function is static and takes what it needs, so the rules can be
## read (and tested) apart from the UI. hall_main.gd owns the quest entries and
## the run's tallies, and calls in here.
##
## Quest entries (see hall_main.gd quest_entries) are built by new_entry().
class_name HallRules


# ============================================================ SETTINGS

## How many quests the board gets, by day: the first row whose `max_day` the
## day is at or under is used. Days past the last row get QUESTS_PER_DAY_LATE.
const QUESTS_PER_DAY_BY_DAY := [
	{"max_day": 2, "count": 1},
	{"max_day": 6, "count": 2},
	{"max_day": 9, "count": 3},
	{"max_day": 10, "count": 4},
]
const QUESTS_PER_DAY_LATE := 5
## Standing per quest rank: a guild at this much standing (or less) gets rank
## 0 (F) quests, up to twice this gets rank 1, and so on up to TOP_STANDING_RANK.
const STANDING_PER_RANK := 10
## The highest rank standing alone can center quests on.
const TOP_STANDING_RANK := 5
## At or under this much standing, every quest is rank 0 (a struggling guild
## only gets the easiest work).
const STARTER_STANDING := 5
## Pluck each party member gains for winning a quest, by the odds the party
## was sent at: the longer the odds, the more they grow from beating them.
## Only paid on wins under the quest rank's train_odds_for threshold; wins at
## or above it train a stat instead (TRAIN_STAT_GAIN).
## Checked top to bottom: the first row whose `min` chance (percent) the odds
## reach is used. The `min`s match HallStyle.ODDS_BANDS, so the gain lines up with
## the odds word on Assign Party (Strong odds / Fair odds / Risky / Long shot).
const PLUCK_GAIN_BY_ODDS := [
	{"min": 80, "gain": 1},
	{"min": 60, "gain": 2},
	{"min": 40, "gain": 3},
	{"min": 0, "gain": 4},
]
## Good-odds threshold (percent success chance) on an F-rank quest: a win sent
## at or above a rank's threshold trains a stat instead of giving Pluck.
const TRAIN_ODDS_BASE := 60
## How much the good-odds threshold rises per quest rank (percent), so harder
## quests need better odds to train and pay Pluck more often (F 60 .. S 85).
const TRAIN_ODDS_PER_RANK := 5
## The rank where the threshold stops rising (S++ uses S's threshold).
const TRAIN_ODDS_TOP_RANK := CreatedQuest.QuestDifficulty.S
## Stat points each party member gains in the trained stat on a good-odds win.
const TRAIN_STAT_GAIN := 1
## Freeplay difficulty climb: each day past HallMain.FINAL_DAY adds this share
## to every new quest's stat requirement and gold reward (0.02 = +2% a day, so
## Day 75 quests ask for and pay 1.5x). Linear and without a cap.
const FREEPLAY_SCALE_PER_DAY := 0.02

## Days that end in a boss quest (the last is HallMain.FINAL_DAY).
const BOSS_DAYS := [10, 20, 30, 40, 50]
## The BOSS_DAYS with two bosses to fight (the second uses the negative day number).
const BOSS_TWO_DAYS := [20, 40]
## The first day the difficulty staircase starts climbing; before it every
## quest asks for its base stats (scale 1.0).
const DIFFICULTY_START_DAY := 5
## Requirement growth for each day from DIFFICULTY_START_DAY on (0.01 = +1% a day).
const DIFFICULTY_DRIFT_PER_DAY := 0.01
## Requirement growth added for each boss already past (0.15 = +15% per boss).
const DIFFICULTY_STEP_PER_BOSS := 0.15
## Extra requirement multiplier on a boss quest, on top of the day's scale.
const BOSS_SPIKE := 1.35
## Extra requirement multiplier on the final battle, on top of the day's scale.
const FINAL_BOSS_SPIKE := 1.15


# ============================================================ STARTING HERO

## Every new run starts with this hero already in the guild, so Day 1 can go
## straight to questing (the tutorial no longer walks through hiring).
## Average stats: a recruit's 17 points spread evenly, plus the Priest's +3
## Wisdom (see GuildCharacter.generate_stat_spread).
const STARTING_HERO_NAME := "Uncle John"
const STARTING_HERO_ROLE := GuildCharacter.CharacterRole.PRIEST
const STARTING_HERO_GENDER := GuildCharacter.CharacterGender.MALE
const STARTING_HERO_STATS := {
	GuildCharacter.StatType.STRENGTH: 4,
	GuildCharacter.StatType.DEFENSE: 4,
	GuildCharacter.StatType.WISDOM: 8,
	GuildCharacter.StatType.SLEAZINESS: 4,
}


## A new Uncle John: a Priest with average stats, free, joined on Day 1.
static func make_starting_hero() -> GuildCharacter:
	var hero := GuildCharacter.new()
	hero.gender = STARTING_HERO_GENDER
	hero.role = STARTING_HERO_ROLE
	hero.name = STARTING_HERO_NAME
	hero.icon = ExternalContentContainer.get_character_icon(hero.role)
	for stat in STARTING_HERO_STATS:
		hero.stats[stat] = STARTING_HERO_STATS[stat]
	hero.title = hero.name + " the " + str(GuildCharacter.CharacterRole.find_key(hero.role))
	# the backstory is written for the role (and may use the name), so redo it
	hero.description = hero.generate_description()
	hero.cost = 0
	hero.joined_on_day = 1
	return hero


# ============================================================ QUESTS

## A new quest entry for hall_main's quest_entries:
##   {quest, state (HallStyle.QUEST_STATE_*), party: Array, milestone: bool,
##    final: bool (true for the HallMain.FINAL_DAY battle; set by build_day_quests)}
static func new_entry(quest: CreatedQuest, is_milestone: bool) -> Dictionary:
	return {"quest": quest, "state": HallStyle.QUEST_STATE_OPEN, "party": [], "milestone": is_milestone, "final": false}


## Today's quest entries:
## the milestone day has only the Bone Drake, HallMain.FINAL_DAY has only the
## final battle, every other day has quests_per_day(day). In freeplay (after
## FINAL_DAY) ranks can roll past S into S++, and every quest scales up a
## little more each day (freeplay_scale).
## day: GameState.day; standing: GuildUpgrades.standing;
## is_freeplay: GameState.is_freeplay.
## Returns an Array of new_entry() Dictionaries, in board order.
static func build_day_quests(day: int, standing: int, is_freeplay: bool) -> Array:
	# boss days: only the day's boss entries (not in freeplay, which only
	# repeats the final day's number as a normal day)
	if is_boss_day(day) and not (is_freeplay and day == HallMain.FINAL_DAY):
		return _build_boss_entries(day)

	var standing_rank := standing_rank_for(standing)
	# the highest rank a quest can roll: S, or S++ once freeplay has begun
	var top_rank: int = CreatedQuest.QuestDifficulty.SPP if is_freeplay else CreatedQuest.QuestDifficulty.S
	var entries := []
	
	var noRepeatQuests = false #used to avoid cloning minor quests
	for quest_number in quests_per_day(day):
		var rank: int = clampi(standing_rank + int(rand_bell_curve()), 0, top_rank)
		# a roll two ranks off the guild's standing is pulled one rank back toward it
		if rank - standing_rank == 2:
			rank -= 1
		elif rank - standing_rank == -2:
			rank += 1
		if standing <= STARTER_STANDING:
			rank = 0

		var quest := CreatedQuest.new(rank, GameState.day)
		if(noRepeatQuests): #if a minor quest has already been created, create only standard quests
			quest = CreatedQuest.new(rank, 5)
		match(GameState.day): #set the boolean
			2, 4, 7, 9, 12, 15, 22, 24, 26, 28, 32, 33, 34, 36, 38, 39, 42, 45, 48:
				noRepeatQuests = true
			18:
				quest = CreatedQuest.new(rank, GameState.day)
				_scale_normal_quest(quest, day, is_freeplay)
				entries.append(new_entry(quest, false))
				quest = CreatedQuest.new(rank, -1 * GameState.day)
				_scale_normal_quest(quest, day, is_freeplay)
				entries.append(new_entry(quest, false))
				return entries
		
		_scale_normal_quest(quest, day, is_freeplay)
		entries.append(new_entry(quest, false))
	return entries


## The boss entries for a boss day (see BOSS_DAYS): one or two quests built from
## the written boss stories (CreatedQuest._initMilestoneVars), all milestone
## entries, with the day's boss requirement scale. HallMain.FINAL_DAY's entry
## is also marked final (it rolls the credits).
## day: a BOSS_DAYS day (GameState.day should equal it, quests read it).
## Returns an Array of new_entry() Dictionaries.
static func _build_boss_entries(day: int) -> Array:
	var entries := []
	# the second boss of a two-boss day uses the negative day number
	var variants: Array = [day, -day] if BOSS_TWO_DAYS.has(day) else [day]
	for variant in variants:
		var quest := CreatedQuest.new(0, variant)
		var is_final := day == HallMain.FINAL_DAY
		quest.requirement_multiplier = requirement_scale(day, true, is_final)
		var entry := new_entry(quest, true)
		entry.final = is_final
		entries.append(entry)
	return entries


## Applies the day's requirement scale to a normal (non-boss) quest, and
## freeplay's gold scaling when `is_freeplay`.
static func _scale_normal_quest(quest: CreatedQuest, day: int, is_freeplay: bool) -> void:
	quest.requirement_multiplier = requirement_scale(day, false, false)
	if is_freeplay:
		quest.apply_freeplay_gold(freeplay_scale(day))


## Freeplay's multiplier on quest requirements and rewards on `day`: 1.0 on
## HallMain.FINAL_DAY, then FREEPLAY_SCALE_PER_DAY more for each day after it.
static func freeplay_scale(day: int) -> float:
	return 1.0 + FREEPLAY_SCALE_PER_DAY * maxi(day - HallMain.FINAL_DAY, 0)


## Whether `day` is one of BOSS_DAYS.
static func is_boss_day(day: int) -> bool:
	return BOSS_DAYS.has(day)


## How many BOSS_DAYS come before `day` (strictly less than it).
static func bosses_before(day: int) -> int:
	var count := 0
	for boss_day: int in BOSS_DAYS:
		if boss_day < day:
			count += 1
	return count


## The first boss day on or after `day`, or -1 when none is left.
static func next_boss_day(day: int) -> int:
	for boss_day: int in BOSS_DAYS:
		if boss_day >= day:
			return boss_day
	return -1


## The staircase multiplier on quest requirements on `day`: 1.0 before
## DIFFICULTY_START_DAY, then a steady drift per day plus a step per boss
## passed. Frozen from HallMain.FINAL_DAY on (freeplay_scale takes over).
static func difficulty_scale(day: int) -> float:
	if day < DIFFICULTY_START_DAY:
		return 1.0
	var capped_day := mini(day, HallMain.FINAL_DAY)
	return 1.0 		+ DIFFICULTY_DRIFT_PER_DAY * (capped_day - (DIFFICULTY_START_DAY - 1)) 		+ DIFFICULTY_STEP_PER_BOSS * bosses_before(capped_day)


## The full multiplier on a quest's stat requirement on `day`: the staircase,
## times the boss spike (BOSS_SPIKE, or FINAL_BOSS_SPIKE for the final battle),
## times freeplay's climb.
static func requirement_scale(day: int, is_boss: bool, is_final: bool) -> float:
	var spike := 1.0
	if is_final:
		spike = FINAL_BOSS_SPIKE
	elif is_boss:
		spike = BOSS_SPIKE
	return difficulty_scale(day) * spike * freeplay_scale(day)


## How many quests the board gets on `day` (see QUESTS_PER_DAY_BY_DAY).
static func quests_per_day(day: int) -> int:
	for row in QUESTS_PER_DAY_BY_DAY:
		if day <= row.max_day:
			return row.count
	return QUESTS_PER_DAY_LATE


## The quest rank (0 = F .. TOP_STANDING_RANK) a guild with this much standing
## centers its quests on: one rank per STANDING_PER_RANK, rounded up, from 0.
static func standing_rank_for(standing: int) -> int:
	return clampi(ceili(float(standing) / STANDING_PER_RANK) - 1, 0, TOP_STANDING_RANK)


## Standing a won quest pays: one more than its rank (F = 1, E = 2, ...).
static func standing_for_win(quest: CreatedQuest) -> int:
	return quest.difficulty + 1


## Standing a failed quest costs: half a win's, rounded up (rank 0-1 = 1,
## 2-3 = 2, 4-5 = 3). Never less than 1, so the G rank (-1) costs 1 too.
static func standing_for_loss(quest: CreatedQuest) -> int:
	return maxi(ceili((quest.difficulty + 1) / 2.0), 1)


## Standing lost for denying a quest: its rank, but never less than 1, so
## even an F-Rank quest costs something to turn down.
static func standing_for_deny(quest: CreatedQuest) -> int:
	return maxi(quest.difficulty, 1)


## A normally distributed random number (Box-Muller transform).
## mean: the center; standard_deviation: the spread. Returns the sample.
static func rand_bell_curve(mean: float = 0.0, standard_deviation: float = 1.0) -> float:
	var u1: float = randf()
	var u2: float = randf()
	# avoid log(0), which is undefined
	if u1 == 0.0:
		u1 = 0.0001
	var standard_normal: float = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	# scale by the standard deviation and shift by the mean
	return (standard_normal * standard_deviation) + mean


## Pluck each party member gains for winning a quest sent at `chance` percent
## (see PLUCK_GAIN_BY_ODDS). A party with no chance yet (-1) counts as a long shot.
static func pluck_gain_for(chance: float) -> int:
	for row in PLUCK_GAIN_BY_ODDS:
		if chance >= row.min:
			return row.gain
	return PLUCK_GAIN_BY_ODDS[-1].gain


## The good-odds threshold (percent success chance) for a quest of `rank`
## (a CreatedQuest.QuestDifficulty): TRAIN_ODDS_BASE plus TRAIN_ODDS_PER_RANK
## per rank, up to TRAIN_ODDS_TOP_RANK.
static func train_odds_for(rank: int) -> int:
	return TRAIN_ODDS_BASE + TRAIN_ODDS_PER_RANK * clampi(rank, 0, TRAIN_ODDS_TOP_RANK)


## Whether winning a quest of `rank` sent at `chance` percent trains a stat
## (true) or gives Pluck (false). A party with no chance yet (-1) never trains.
static func trains_stat(chance: float, rank: int) -> bool:
	return chance >= train_odds_for(rank)


# ============================================================ PLAYING A QUEST

## Play out one quest with QuestScoring and pay its gold and standing into
## GameState. On a win the party trains a stat (good odds, see trains_stat) or
## gains Pluck (riskier odds), found equipment goes into the pack, and the
## fallen remember where they fell. The run's tallies are left to the caller
## (hall_main.gd _tally_quest).
## entry: a quest entry (see new_entry); day: GameState.day.
## Returns one result for the Day Report:
##   {quest, party, story, succeeded, chance, gold, standing (negative on a loss), pluck, trained_stat, stat_gain, injured, died, items, reward_items, milestone, final}
## (pluck = what each party member gained, 0 on a failure or a trained win;
## trained_stat = the GuildCharacter.StatType index the party trained, -1 if
## none; stat_gain = how much each party member gained in it)
## (injured = the party members whose injury level went up on this quest but
## who survived; died = the party members who died on it; items = the
## equipment found while searching, already added to the pack; reward_items =
## an item quest's reward, added to the pack only when the quest succeeded)
static func play_quest(entry: Dictionary, day: int) -> Dictionary:
	var party: Array[GuildCharacter] = []
	party.assign(entry.party)

	# remember health before, to see who got hurt
	var injury_before := {}
	for character in party:
		injury_before[character] = character.injury_level

	# play it out
	var chance: float = QuestScoring.get_success_chance(entry.quest, party)
	# only play the quest out once, or its loot and injuries would be rolled twice
	var story: String
	# ==== FINAL QUEST STORY ==================================================
	# PLACEHOLDER: the final battle plays out like any other quest for now.
	# When it has its own story, add a branch here, for example:
	#   elif entry.final:
	#       story = entry.quest.generateFinalResults(party, chance)
	# A loss must still contain "NOT SUCCESSFUL" (QuestScoring.FAIL_MARKER).
	# ==== END FINAL QUEST STORY ==============================================
	story = entry.quest.generateResults(party, chance)
	var succeeded: bool = QuestScoring.did_succeed(story)
	var gold_earned: int = QuestScoring.get_gold_earned(entry.quest, succeeded)
	var standing_earned: int = 0
	if succeeded:
		standing_earned = standing_for_win(entry.quest)
	else:
		# a loss costs standing, but never sinks the guild past its floor
		# (GuildUpgrades.add_standing doesn't clamp, so the clamp lives here)
		var room_above_floor := maxi(GameState.standing - GuildUpgrades.MINIMUM_STANDING, 0)
		standing_earned = -mini(standing_for_loss(entry.quest), room_above_floor)
	GameState.add_gold(gold_earned)
	GameState.add_standing(standing_earned)

	# equipment found while searching goes to the pack, even if the quest failed
	# (an item quest's reward replaces its gold, so it's only paid on a success)
	var found_items: Array[StandardItem] = entry.quest.found_items.duplicate()
	var reward_items: Array[StandardItem] = []
	if succeeded and entry.quest.pays_in_items():
		reward_items = entry.quest.reward_items.duplicate()
	if not found_items.is_empty() or not reward_items.is_empty():
		ItemContainer.owned_items.append_array(found_items)
		ItemContainer.owned_items.append_array(reward_items)
		# refresh gear rows and unworn counts
		ItemShop.gear_changed.emit()

	# A win at good odds for the quest's rank trains one stat for the whole
	# party (the quest's or the region's favored stat); a riskier win raises
	# everyone's Pluck instead, more for winning against worse odds.
	var pluck_gained := 0
	var trained_stat := -1
	var stat_gained := 0
	if succeeded and trains_stat(chance, entry.quest.difficulty):
		trained_stat = entry.quest.roll_trained_stat()
		stat_gained = TRAIN_STAT_GAIN
		for character in party:
			character.stats[trained_stat] += stat_gained
	elif succeeded:
		pluck_gained = pluck_gain_for(chance)
		for character in party:
			character.pluck += pluck_gained

	# the dead are listed apart from the hurt, and remember where they fell
	var injured := []
	var died := []
	for character in party:
		if HallStyle.is_dead(character) and injury_before[character] < GuildCharacter.InjuryLevel.DEAD:
			died.append(character)
			character.died_on_day = day
			character.died_on_quest = entry.quest.questTitle
		elif character.injury_level > injury_before[character]:
			injured.append(character)

	return {
		"quest": entry.quest,
		"party": entry.party.duplicate(),
		"story": story,
		"succeeded": succeeded,
		"chance": chance,
		"gold": gold_earned,
		"standing": standing_earned,
		"pluck": pluck_gained,
		"trained_stat": trained_stat,
		"stat_gain": stat_gained,
		"injured": injured,
		"died": died,
		"items": found_items,
		"reward_items": reward_items,
		"milestone": entry.milestone,
		"final": entry.final,
		"story_quest": entry.get("story_quest", false),
	}
