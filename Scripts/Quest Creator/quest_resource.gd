extends Resource

class_name CreatedQuest

enum QuestDifficulty {
	G = -1,
	F = 0,
	D = 1,
	C = 2,
	B = 3,
	A = 4,
	S = 5,
	## Freeplay only (after HallMain.FINAL_DAY): every quest that would roll
	## above S lands here. Shown as "S++" (HallStyle.rank_letter); its
	## requirement and pay keep climbing through requirement_multiplier.
	SPP = 6,
}

enum QuestType {
	MiscNoBonus = 0,
	DungeonClear = 1,
	Escort = 2,
	ScoutTerrain = 3,
	GatherIntel = 4,
	EliminateMonsters = 5,
	DefendLocation = 6,
	SearchForResources = 7,
	RepresentTheGuild = 8,
}

enum FavoredStat {
	Power = 0,
	Defense = 1,
	Wisdom = 2,
	Sleaze = 3,
	Pluck = 4,
	PowerAndDefense = 10,
	PowerAndWisdom = 20,
	PowerAndSleaze = 30,
	DefenseAndWisdom = 12,
	DefenseAndSleaze = 13,
	WisdomAndSleaze = 23,
	PowerAndPluck = 40,
}

enum QuestStyle {
	Normal = 0,
	MinorStory = 1,
	MajorMilestone = 2,
}

## The stat each world region favors, by regionNum (Region.RegionType), as a
## GuildCharacter.StatType index: Windswept Meadows -> Defense, Boglands ->
## Sleaze, Ashen Wastes -> Power, Glass Mountains -> Wisdom. calcSuccessChance
## counts it twice, and a good-odds win can train it (roll_trained_stat).
const REGION_FAVORED_STAT := [1, 3, 0, 2]

## The favored-stat component that means Pluck (not a StatType, so it's never
## read with get_quest_stat or trained).
const PLUCK_COMPONENT := 4

#enum for modifiers if we ever choose to do them

var numAdventurers: int
var maxAdventurers: int
var goldReward: int
var startingGoldReward: int

var location: String
var regionNum: int:
	get:
		return regionNum
#var/vars for other flavors (characters/items/etc)

var difficulty: QuestDifficulty
var type: QuestType
var favStat: FavoredStat
#var for modifier(s) if we ever choose to do that

var questTitle: String:
	get:
		return questTitle

var questSummary: String = "":
	get:
		return questSummary

var questNum: int:
	get:
		return questNum

var dead_adventurers : Array[GuildCharacter]

## Whether this run of generateResults fails the quest. Rolled once at the
## start (same odds as the old end-of-quest roll) so the fights know whether a
## hero can die. Not saved: it only matters while the story is generated.
var _will_fail: bool = false

## Each hero's injury_level when generateResults began (hero -> level). A hero
## who set out Hurt (LIGHTLY_INJURED) or worse can die even on a won quest.
var _starting_levels: Dictionary = {}

## Freeplay scaling on the stat total this quest asks for (1.0 = none).
## Set by apply_freeplay_scaling; calcSuccessChance multiplies statHitNum by it.
var requirement_multiplier: float = 1.0

## Equipment the party found while searching on this quest. The guild keeps it
## whether or not the quest succeeds (HallRules.play_quest adds it to ItemContainer).
var found_items: Array[StandardItem]

## Chance (percent) that a successful search turns up equipment, before any
## risk or shorthanded bonuses.
var equipment_base_chance: float = 10.0
## Extra chance (percent) at a 0% quest success chance, scaling down to nothing
## at 100%, so less prepared parties are more likely to find gear.
var equipment_risk_bonus: float = 25.0
## Extra chance (percent) for each open party slot the quest was sent without.
var equipment_shorthanded_bonus: float = 10.0
## The highest the equipment find chance (percent) can go.
var equipment_max_chance: float = 50.0

var successfulChecks: int
var styleOfQuest = QuestStyle

## The equipment this quest pays instead of gold, rolled when the quest is made
## so the Board can show it. Empty for a normal gold quest. Only paid out when
## the quest succeeds (HallRules.play_quest adds it to ItemContainer).
var reward_items: Array[StandardItem]

## Chance (percent) on day 1 that a standard quest pays in items instead of gold.
var item_reward_base_chance: float = 5.0
## Extra item-quest chance (percent) for each day after day 1, so item quests
## turn up more often the further into the game the player gets.
var item_reward_chance_per_day: float = 1.5
## The highest the item-quest chance (percent) can go.
var item_reward_max_chance: float = 30.0
## Extra reward items per difficulty rank: the count is 1 + difficulty * this,
## rounded down (F/D 1 item, C/B 2, A/S 3).
var item_reward_count_per_rank: float = 0.5

## Chance (percent) that a good-odds win trains the quest's favored stat
## (favStat) rather than the region's (REGION_FAVORED_STAT). See roll_trained_stat.
var trained_stat_quest_chance: float = 50.0

func _init(diff := 0, dayNum := 0) -> void:
	match(dayNum):
		1, 2, 4, 7, 9, 10, 12, 15, 18, -18, 20, -20, 30, 40, -40, 50, 22, 24, 26, 28, 32, 33, 34, 36, 38, 39, 42, 45, 48:
			_initMilestoneVars(dayNum)
			return

	difficulty = diff
	if (dayNum <= 5):
		maxAdventurers = randi_range(1, 2)
	else:
		maxAdventurers = randi_range(1, 3)
	regionNum = randi_range(0, 3)
	questNum = randi_range(0, 15)
	type = ExternalContentContainer.get_Quest_Story(questNum, 0).to_int()
	location = QuestManager.world_regions[regionNum].returnName(type)
	print(regionNum, " ", location)
	
	successfulChecks = 0
	styleOfQuest = 0
	
	if(maxAdventurers == 1):
		startingGoldReward = 100 + (125 * difficulty)
		goldReward = 100 + (125 * difficulty)
	elif(maxAdventurers == 2):
		goldReward = 150 + (175 * difficulty)
		startingGoldReward = 150 + (175 * difficulty)
	elif(maxAdventurers == 3):
		goldReward = 200 + (225 * difficulty)
		startingGoldReward = 200 + (225 * difficulty)

	# Some standard quests (dayNum 0) pay in equipment instead: the items replace
	# the base gold. The final battle (HallMain.FINAL_DAY) always pays gold, like
	# the Bone Drake. (search finds can still add bonus gold to goldReward later)
	if (dayNum == 0 and randf_range(0.0, 100.0) < _get_item_reward_chance()):
		_roll_reward_items()
		goldReward = 0
		startingGoldReward = 0

	match type:
		1, 5:
			favStat = FavoredStat.Power
			if (type == 1):
				match randi_range(0, 1):
					0:
						questTitle = str("Raid the ", location)
					1:
						questTitle = str("Storm the ", location)
			else:
				match randi_range(0, 1):
					0:
						questTitle = str("Clear out monsters at the ", location)
					1:
						questTitle = str("Eliminate monsters at the ", location)
		2, 6:
			favStat = FavoredStat.Defense
			if (type == 2):
				match randi_range(0, 1):
					0:
						questTitle = str("Protect a client on their journey to ", location)
					1:
						questTitle = str("Escort a client to ", location)
			else:
				match randi_range(0, 1):
					0:
						questTitle = str("Defend ", location, " from attack")
					1:
						questTitle = str("Protect ", location, " from attack")
		3, 7:
			favStat = FavoredStat.Wisdom
			if (type == 3):
				match randi_range(0, 1):
					0:
						questTitle = str("Survey ", location)
					1:
						questTitle = str("Explore ", location)
			else:
				match randi_range(0, 1):
					0:
						questTitle = str("Search for resources in ", location)
					1:
						questTitle = str("Seek rare resources in ", location)
		4, 8:
			favStat = FavoredStat.Sleaze
			if (type == 4):
				match randi_range(0, 1):
					0:
						questTitle = str("Scour for intel on ", location)
					1:
						questTitle = str("Gather information on ", location)
			else:
				match randi_range(0, 1):
					0:
						questTitle = str("Represent the guild at ", location)
					1:
						questTitle = str("Speak for the guild at ", location)

	print("")
	pass


## Freeplay: makes this quest harder and better paid by the same factor.
## multiplier: 1.0 = unchanged, 1.5 = needs half again the stats and pays
## half again the gold (see HallRules.FREEPLAY_SCALE_PER_DAY).
func apply_freeplay_scaling(multiplier: float) -> void:
	requirement_multiplier = multiplier
	apply_freeplay_gold(multiplier)


## Scales only the gold reward (goldReward and startingGoldReward), leaving the
## stat requirement alone. multiplier: 1.0 = unchanged.
func apply_freeplay_gold(multiplier: float) -> void:
	goldReward = roundi(goldReward * multiplier)
	startingGoldReward = roundi(startingGoldReward * multiplier)


func calcSuccessChance(_questingAdventurers: Array) -> int:
	var statHitNum = 60.0 + (20 * difficulty)
	# The requirement scales with party size, 2 slots being the baseline
	# (1 slot x0.5, 3 slots x1.5, 5 slots x2.5, 8 slots x4).
	statHitNum *= QuestScoring.get_slot_count(self) / 2.0
	statHitNum *= requirement_multiplier
	var statTotal = 0.0

	for adventurer in _questingAdventurers:
		# Rebuild the temp stats first so the pluck bonus matches the current
		# pluck level and base stats (both change after quests, training, gear...)
		adventurer.reset_temp_stats()

		statTotal += adventurer.get_quest_stat(0) + adventurer.get_quest_stat(1) + adventurer.get_quest_stat(2) + adventurer.get_quest_stat(3)
		# the region's favored stat counts twice
		statTotal += adventurer.get_quest_stat(region_favored_stat())

		# the favored stat's components count once each (Pluck alone counts twice,
		# like a single stat); a Pluck component counts the hero's pluck value
		for component in favored_components():
			if component == PLUCK_COMPONENT:
				statTotal += adventurer.pluck * (2 if int(favStat) == PLUCK_COMPONENT else 1)
			else:
				statTotal += adventurer.get_quest_stat(component)

	return (snapped((statTotal / statHitNum), 0.01) * 100)


## The GuildCharacter.StatType index this quest's region favors
## (see REGION_FAVORED_STAT).
func region_favored_stat() -> int:
	return REGION_FAVORED_STAT[regionNum]


## The favored stat's components. A value under 10 is one component (a
## GuildCharacter.StatType index 0-3, or PLUCK_COMPONENT); a two-digit value is
## a combo of its two digits, e.g. 12 = Defense + Wisdom, 40 = Pluck + Power.
## Returns an Array[int] (PLUCK_COMPONENT = Pluck, which is not a StatType).
func favored_components() -> Array[int]:
	var value := int(favStat)
	var components: Array[int] = []
	if value < 10:
		components.append(value)
	else:
		components.append(value / 10)
		components.append(value % 10)
	return components


## The one or two stats a good-odds win on this quest can train: the quest's
## favored stat's trainable components (GuildCharacter.StatType 0-3; Pluck isn't
## a stat, so it's dropped), then the region's. Falls back to just the region's
## stat when nothing trainable is left. Returns an Array of StatType indexes.
func trained_stat_options() -> Array[int]:
	var options: Array[int] = []
	for component in favored_components():
		if component != PLUCK_COMPONENT and not options.has(component):
			options.append(component)
	if not options.has(region_favored_stat()):
		options.append(region_favored_stat())
	return options


## Pick the stat a good-odds win trains: one of the quest's trainable favored
## stats trained_stat_quest_chance percent of the time (when it has any),
## otherwise the region's. Returns a GuildCharacter.StatType index (0-3).
func roll_trained_stat() -> int:
	var favored: Array[int] = []
	for component in favored_components():
		if component != PLUCK_COMPONENT:
			favored.append(component)
	if not favored.is_empty() and randf_range(0.0, 100.0) < trained_stat_quest_chance:
		return favored.pick_random()
	return region_favored_stat()


#this is the main root method for deciding and generating results I'll have
#methods branch off to decide certain parts of the results
func generateResults(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var returnString = ""

	numAdventurers = _questingAdventurers.size()

	# roll the outcome up front (same probability as the old end-of-quest roll)
	# so the fights know whether a hero is allowed to die
	_will_fail = randi_range(0, 100) >= _successChance
	_starting_levels.clear()
	for hero in _questingAdventurers:
		_starting_levels[hero] = hero.injury_level

	var data = { "location": location }
	returnString = str(returnString, "[b]", _questingAdventurers[0].name,)
			
	for i in range(numAdventurers - 2):
			returnString = str( returnString, ", ", _questingAdventurers[i + 1].name,)
	
	if(numAdventurers > 1):
		returnString = str( returnString, " and ", _questingAdventurers[numAdventurers - 1].name,)
	
	returnString = str(returnString, "[/b] ")
	match(styleOfQuest):
			0:
				returnString = str(returnString, ExternalContentContainer.get_Quest_Story(questNum, 1).c_unescape().format(data),)
			1:
				returnString = str(returnString, ExternalContentContainer.get_Minor_Story(questNum, 1).c_unescape().format(data),)
			2:
				returnString = str(returnString, ExternalContentContainer.get_Milestone_story(questNum, 1).c_unescape().format(data),)
		
	var extraGold = 50 + (25 * difficulty)
	var addGold = true
	var runMiddle = false
	if(difficulty <= 1):
		var loopbreaker = 12 + (3 * difficulty)
		if(difficulty == QuestDifficulty.G):
			loopbreaker = -1
			returnString = str(returnString, _search(_questingAdventurers, _successChance))
			returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
			returnString = str(returnString, _search(_questingAdventurers, _successChance))
			
		while randi_range(-1, 10) < loopbreaker:
			match randi_range(0, 1):
				0:
					returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
				1:
					returnString = str(returnString, _search(_questingAdventurers, _successChance))
			loopbreaker = loopbreaker - 1
	else:
		runMiddle = true
		var loopbreaker = 4 + (2 * difficulty)
		while randi_range(-1, 6) < loopbreaker:
			match randi_range(0, 1):
				0:
					returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
				1:
					returnString = str(returnString, _search(_questingAdventurers, _successChance))
			loopbreaker = loopbreaker - 1
			
		if(successfulChecks >= 2 + difficulty):
			match(styleOfQuest):
				0:
					returnString = str(
			returnString,
			ExternalContentContainer.get_Quest_Story(questNum, 3).c_unescape().format(data),
			"[color=FFE700][b] ", extraGold, " gold[/b][/color]", " added to potential quest reward.\n")
				1:
					returnString = str(
			returnString,
			ExternalContentContainer.get_Minor_Story(questNum, 3).c_unescape().format(data),
			"[color=FFE700][b] ", extraGold, " gold[/b][/color]", " added to potential quest reward.\n")
				2:
					returnString = str(
			returnString,
			ExternalContentContainer.get_Milestone_story(questNum, 3).c_unescape().format(data),
			"[color=FFE700][b] ", extraGold, " gold[/b][/color]", " added to potential quest reward.\n")
		else:
			addGold = false
			match(styleOfQuest):
				0:
					returnString = str(
			returnString,
			ExternalContentContainer.get_Quest_Story(questNum, 2).c_unescape().format(data),
			"[color=FFE700][b] ", extraGold, " gold[/b][/color]", " removed from potential quest reward.\n")
				1:
					returnString = str(
			returnString,
			ExternalContentContainer.get_Minor_Story(questNum, 2).c_unescape().format(data),
			"[color=FFE700][b] ", extraGold, " gold[/b][/color]", " removed from potential quest reward.\n")
				2:
					returnString = str(
			returnString,
			ExternalContentContainer.get_Milestone_story(questNum, 2).c_unescape().format(data),
			"[color=FFE700][b] ", extraGold, " gold[/b][/color]", " removed from potential quest reward.\n")

		loopbreaker = 4 + (2 * difficulty)
		while randi_range(-1, 6) < loopbreaker:
			match randi_range(0, 1):
				0:
					returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
				1:
					returnString = str(returnString, _search(_questingAdventurers, _successChance))
			loopbreaker = loopbreaker - 1

	match true:
		_ when _will_fail:
				returnString = str(returnString, "[b]", _questingAdventurers[0].name,)
				for i in range(numAdventurers - 2):
					returnString = str( returnString, ", ", _questingAdventurers[i + 1].name,)
	
				if(numAdventurers > 1):
					returnString = str( returnString, " and ", _questingAdventurers[numAdventurers - 1].name,)
	
				returnString = str(returnString, "[/b] ")
				match(styleOfQuest):
					0:
						returnString = str(returnString, ExternalContentContainer.get_Quest_Story(questNum, 4).c_unescape().format(data),)
					1:
						returnString = str(returnString, ExternalContentContainer.get_Minor_Story(questNum, 4).c_unescape().format(data),)
					2:
						returnString = str(returnString, ExternalContentContainer.get_Milestone_story(questNum, 4).c_unescape().format(data),)

				returnString = str(returnString, _retreat(_questingAdventurers))
				returnString = str(returnString, "[b]Summary[/b]: The quest was [color=red][b]NOT SUCCESSFUL[/b][/color]. Your guild failed to obtain the reward.\n")
				questSummary = str(questSummary, "[b]Summary[/b]: The quest was NOT SUCCESSFUL. Your guild failed to obtain the reward.\n")

				if (goldReward > startingGoldReward):
					returnString = str(returnString, "However, your adventurers did bring back [color=FFE700][b]", goldReward - startingGoldReward, " gold[/b][/color].\n")
					questSummary = str(questSummary, "However, your adventurers did bring back ", goldReward - startingGoldReward, " gold")
		_:
			returnString = str(returnString, "[b]", _questingAdventurers[0].name,)
			for i in range(numAdventurers - 2):
					returnString = str( returnString, ", ", _questingAdventurers[i + 1].name,)
	
			if(numAdventurers > 1):
					returnString = str( returnString, " and ", _questingAdventurers[numAdventurers - 1].name,)
	
			returnString = str(returnString, "[/b] ")
			match(styleOfQuest):
					0:
						returnString = str(returnString, ExternalContentContainer.get_Quest_Story(questNum, 5).c_unescape().format(data),)
					1:
						returnString = str(returnString, ExternalContentContainer.get_Minor_Story(questNum, 5).c_unescape().format(data),)
					2:
						returnString = str(returnString, ExternalContentContainer.get_Milestone_story(questNum, 5).c_unescape().format(data),)

			if(addGold && runMiddle):
				goldReward += extraGold
			elif (runMiddle):
				goldReward -= extraGold
			if pays_in_items():
				# item quests name their reward, plus any bonus gold found on the way
				var reward_names := ", ".join(_get_reward_item_names())
				returnString = str(returnString, "[b]Summary[/b]: The quest was [color=green][b]SUCCESSFUL[/b][/color]. Your guild gained [color=4FC3F7][b]", reward_names, "[/b][/color]")
				questSummary = str(questSummary, "[b]Summary[/b]: The quest was SUCCESSFUL. Your guild gained ", reward_names)
				if (goldReward > 0):
					returnString = str(returnString, " and [color=FFE700][b]", goldReward, " gold[/b][/color]")
					questSummary = str(questSummary, " and ", goldReward, " gold")
				returnString = str(returnString, ".\n")
				questSummary = str(questSummary, ".\n")
			else:
				returnString = str(returnString, "[b]Summary[/b]: The quest was [color=green][b]SUCCESSFUL[/b][/color]. Your guild gained [color=FFE700][b]", goldReward, " gold[/b][/color].\n")
				questSummary = str(questSummary, "[b]Summary[/b]: The quest was SUCCESSFUL. Your guild gained ", goldReward, " gold.\n")

	# list found equipment after either outcome, since the guild keeps it either way
	returnString = str(returnString, _get_found_items_lines())
	returnString = str(returnString, _deathLines())

	#loop with size based on difficulty -> higher difficulty more loops 
	#sends combat or search to its own methods

	#once the loop moves on you put the middle if the quest has one and
	#then the loop begins again (again, only if the quest has a middle)

	#once the loop moves on we are done here
	return returnString

## Whether a hero may die from the next hit: on a failed quest, or when they
## set out Hurt (LIGHTLY_INJURED) or worse. Heroes who set out Healthy or Sore
## on a won quest stop at Gravely injured.
func _can_die(hero: GuildCharacter) -> bool:
	return _will_fail or _starting_levels.get(hero, 0) >= GuildCharacter.InjuryLevel.LIGHTLY_INJURED


## Heroes the next fight hit could still change: alive, and not already at the
## Gravely cap while protected from dying.
func _hittable_heroes(party: Array[GuildCharacter]) -> Array[GuildCharacter]:
	var hittable: Array[GuildCharacter] = []
	for hero in party:
		if hero.injury_level >= GuildCharacter.InjuryLevel.DEAD:
			continue
		if not _can_die(hero) and hero.injury_level >= GuildCharacter.InjuryLevel.GRAVELY_INJURED:
			continue
		hittable.append(hero)
	return hittable


## Injures a hero from a fight and records a death.
func _injure_in_fight(hero: GuildCharacter) -> void:
	var died: bool = hero.injure_character(_can_die(hero))
	if died and not dead_adventurers.has(hero):
		dead_adventurers.append(hero)


## Every hero takes one more injury after a failed quest's fights (can die).
## Returns the story line for it, or "" when nobody could be hurt further.
func _retreat(party: Array[GuildCharacter]) -> String:
	var anyone_hurt := false
	for hero in party:
		if hero.injury_level >= GuildCharacter.InjuryLevel.DEAD:
			continue
		anyone_hurt = true
		var died: bool = hero.injure_character(true)
		if died and not dead_adventurers.has(hero):
			dead_adventurers.append(hero)
	if not anyone_hurt:
		return ""
	return "[b]The party was beaten back[/b] and everyone was [color=FD0000][b]INJURED[/b][/color] in the retreat.\n"


func _combatEncounter(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var combatChance = _successChance / 100.0
	combatChance *= combatChance
	combatChance *= 100.0

	if combatChance > 90:
		combatChance = 90

	var returnString = ""
	var successDetermination = randi_range(0, 100)

	var monster = QuestManager.world_regions[regionNum].returnMonster()
	if(styleOfQuest == 1):
		match(questNum):
			5, 6, 7, 8:
				monster = QuestManager._returnQuestMonster(1)
	elif(styleOfQuest == 2):
		match(questNum):
			0:
				monster = QuestManager._returnQuestMonster(0)
			1, 2:
				monster = QuestManager._returnQuestMonster(2)

	# whether the fight hurts someone is set by the quest's odds, not by who
	# won the fight, so the average wear per hero matches the injury table
	var hurt_hero: GuildCharacter = null
	var hittable := _hittable_heroes(_questingAdventurers)
	var injury_chance := QuestInjuries.injury_chance_per_encounter(
		_successChance, difficulty, _questingAdventurers.size())
	if not hittable.is_empty() and randf() < injury_chance:
		hurt_hero = hittable.pick_random()

	var won_fight: bool = combatChance >= successDetermination
	# a won fight sometimes turns up gold on the monster's corpse
	var corpse_gold := 0
	if won_fight and randi_range(1, 100) > 75:
		corpse_gold = randi_range(11, 29)
		goldReward += corpse_gold
	var gold_text := str("[color=FFE700][b] ", corpse_gold, " gold [/b][/color]")
	var any_hero: GuildCharacter = _questingAdventurers.pick_random()
	var variant := randi_range(1, 3)

	if hurt_hero != null:
		var hurt_name: String = hurt_hero.name
		if corpse_gold > 0:
			returnString = str(
				"[b]", hurt_name, "[/b] was ATTACKED by a(n) ", monster, ", and defeated it, finding ",
				gold_text, "on its corpse. However, they were [color=FD0000][b]INJURED[/b][/color] in the process.\n")
		elif variant == 1:
			returnString = str(
				"[b]", hurt_name, "[/b] was ATTACKED by a(n) ", monster,
				". They managed to fight the monster off but were [color=FD0000][b]INJURED[/b][/color] in the process.\n")
		elif variant == 2:
			returnString = str(
				"[b]The Party[/b] was ATTACKED by a group of ", monster,
				"s. They managed to defeat them, but not before [color=FD0000][b]", hurt_name, " was INJURED[/b][/color] in the process.\n")
		else:
			returnString = str(
				"[b]", hurt_name, "[/b] was ATTACKED by a(n) ", monster,
				", and defeated it. However, they were [color=FD0000][b]INJURED[/b][/color] in the process.\n")
		_injure_in_fight(hurt_hero)
	elif corpse_gold > 0:
		returnString = str(
			"[b]", any_hero.name, "[/b] was ATTACKED by a(n) ", monster,
			", and defeated it, finding ", gold_text, "on its corpse.\n")
	elif variant == 1:
		returnString = str(
			"[b]The Party[/b] was ATTACKED by a group of ", monster,
			"s, but defeated them [color=green][b]without sustaining any injuries[/b][/color].\n")
	elif variant == 2:
		returnString = str(
			"[b]", any_hero.name, "[/b] was ATTACKED by a(n) ", monster,
			", but defeated it [color=green][b]without sustaining any injuries[/b][/color].\n")
	else:
		returnString = str(
			"[b]The Party[/b] was ATTACKED by a group of ", monster,
			"s. They defeated them [color=green][b]without sustaining any injuries[/b][/color].\n")

	if won_fight:
		successfulChecks += 1
	return returnString

func _search(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var searchChance = _successChance / 100
	searchChance = searchChance * searchChance
	searchChance *= 100
	if (searchChance > 90):
		searchChance = 90

	var returnString = ""
	var successDetermination = randi_range(0, 100)
	var searchingAdventurer: GuildCharacter = _questingAdventurers.pick_random()
	if(searchChance >= successDetermination):
		# Sub-chance of a successful search: equipment is found instead of the
		# usual gold, more often when the party is less prepared for the quest
		var equipment_roll := randf_range(0.0, 100.0)
		if (equipment_roll < _get_equipment_find_chance(_questingAdventurers, _successChance)):
			return _find_equipment(searchingAdventurer)

		var succSearDet = randi_range(1, 100)
		if(1 <= succSearDet && succSearDet <= 13):
			var extraGold = randi_range(11, 29)
			goldReward += extraGold
			returnString = str(returnString, "[b]The Party[/b] discovered an old chest containing [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		elif(14 <= succSearDet && succSearDet <= 25):
			var extraGold = randi_range(11, 29)
			goldReward += extraGold
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] found an old chest containing [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		elif(26 <= succSearDet && succSearDet <= 38):
			var extraGold = randi_range(3, 15)
			goldReward += extraGold
			returnString = str(returnString, "[b]The Party[/b] unearthed a lockbox that contained [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		elif(38 <= succSearDet && succSearDet <= 50):
			var extraGold = randi_range(3, 15)
			goldReward += extraGold
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] found someone's lost wallet on the ground, which still had [color=FFE700][b]", extraGold, " gold[/b][/color] in it.\n")
		elif(51 <= succSearDet && succSearDet <= 62):
			var extraGold = randi_range(25, 59)
			goldReward += extraGold
			returnString = str(returnString, "[b]The Party[/b] discovered a secret room filled with treasure, including [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		elif(63 <= succSearDet && succSearDet <= 75):
			var extraGold = randi_range(24, 59)
			goldReward += extraGold
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] unearthed a rather gaudy looking artifact, which turned out to be worth [color=FFE700][b]", extraGold, " gold[/b][/color].\n")
		successfulChecks += 1
	else:
		var succSearDet = randi_range(1, 100)
		if(1 <= succSearDet && succSearDet <= 15):
			returnString = str(returnString, "[b]", searchingAdventurer.name, "[/b] tripped on a rock and came back [color=FD0000][b]empty-handed and bruised in spirit[/b][/color].\n")
		elif(16 <= succSearDet && succSearDet <= 45):
			returnString = str(returnString, "[b]The Party[/b] discovered a hidden room containing multiple chests, but [color=FD0000][b]NOTHING OF VALUE[/b][/color] was inside.\n")
		elif(46 <= succSearDet && succSearDet <= 75):
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] went off alone to search for treasure, but returned with [color=FD0000][b]NOTHING[/b][/color].\n")
		elif(76 <= succSearDet && succSearDet <= 90):
			var extraGold = randi_range(3, 15)
			goldReward += extraGold
			returnString = str(returnString, "[b]", searchingAdventurer.name, 
			"[/b] found an old chest containing [color=FFE700][b]", extraGold, " gold[/b][/color]. However, the chest was trapped and [b]", searchingAdventurer.name,
			"[/b] [color=FD0000][b]barely got away with the coins[/b][/color].\n")
		elif(91 <= succSearDet && succSearDet <= 100):
			goldReward += 1
			returnString = str(returnString, "[b]The Party[/b] unearthed a lockbox that contained [color=FFE700][b]1 gold[/b][/color].\n")
			
	return returnString


## How likely (percent) a successful search is to turn up equipment.
## Riskier quests pay off: the chance goes up as the success chance goes down,
## and again for every party slot left empty.
## questing_adventurers: the party on this quest.
## success_chance: the quest's success chance (0-100).
## Returns the find chance, clamped to 0..equipment_max_chance.
func _get_equipment_find_chance(questing_adventurers: Array[GuildCharacter], success_chance: float) -> float:
	# 0 when the party is sure to succeed, 1 when it is sure to fail
	var risk: float = 1.0 - clampf(success_chance / 100.0, 0.0, 1.0)
	# how many party slots the quest was sent without
	var empty_slots: int = maxi(maxAdventurers - questing_adventurers.size(), 0)

	var find_chance: float = equipment_base_chance
	find_chance += equipment_risk_bonus * risk
	find_chance += equipment_shorthanded_bonus * empty_slots
	return clampf(find_chance, 0.0, equipment_max_chance)


## Makes a piece of equipment for the searching adventurer to bring home.
## The item is for the finder's role (gear is role-locked) and its rarity
## scales with this quest's difficulty.
## searching_adventurer: the hero who found it.
## Returns the story line for the find.
func _find_equipment(searching_adventurer: GuildCharacter) -> String:
	var found_item := PassiveItem.new(searching_adventurer.role, difficulty)
	# match ItemShop._make_item: equipping checks item.role
	found_item.role = searching_adventurer.role
	found_items.append(found_item)

	return str("[b]", searching_adventurer.name, "[/b] discovered a hidden cache containing a(n) [color=4FC3F7][b]",
		found_item.name, "[/b][/color].\n")


## The end-of-quest line listing every piece of equipment found, for both the
## story and questSummary. Found gear is kept even when the quest fails.
## Returns an empty string if nothing was found.
func _get_found_items_lines() -> String:
	if found_items.is_empty():
		return ""

	var item_names: Array[String] = []
	for found_item in found_items:
		item_names.append(found_item.name)

	var found_items_line := str("Your adventurers also brought back: ", ", ".join(item_names), ".\n")
	questSummary = str(questSummary, found_items_line)
	return str("[color=4FC3F7][b]Equipment found[/b][/color]: ", ", ".join(item_names), ".\n")


## True if this quest pays in equipment (reward_items) instead of gold.
func pays_in_items() -> bool:
	return not reward_items.is_empty()


## The reward as shown on the Board and Assign Party, e.g. "2 items · RARE,
## COMMON" for an item quest or "250 gold" for a gold quest.
func get_reward_text() -> String:
	if not pays_in_items():
		return str(goldReward, " gold")

	var rarity_names := PackedStringArray()
	for reward_item in reward_items:
		rarity_names.append(str(StandardItem.Rarity.find_key(reward_item.rarity)))
	var item_word := "item" if reward_items.size() == 1 else "items"
	return "%d %s · %s" % [reward_items.size(), item_word, ", ".join(rarity_names)]


## How likely (percent) a new standard quest is to pay in items, growing with
## GameState.day (HallRules passes dayNum = 0 for normal quests, so the day is
## read from GameState instead).
## Returns the chance, clamped to 0..item_reward_max_chance.
func _get_item_reward_chance() -> float:
	var days_in: int = maxi(GameState.day - 1, 0)
	var reward_chance: float = item_reward_base_chance + item_reward_chance_per_day * days_in
	return clampf(reward_chance, 0.0, item_reward_max_chance)


## Fills reward_items for an item quest: more items on harder quests, each for
## a random hero role (like Shop stock), with rarity weighted by difficulty.
## Sorted rarest first so the Board lists the best item first.
func _roll_reward_items() -> void:
	reward_items.clear()
	var item_count: int = 1 + int(difficulty * item_reward_count_per_rank)
	for i in item_count:
		var role: GuildCharacter.CharacterRole = GuildCharacter.CharacterRole.values().pick_random()
		var reward_item := PassiveItem.new(role, difficulty)
		# match ItemShop._make_item: equipping checks item.role
		reward_item.role = role
		reward_items.append(reward_item)

	# a higher tier index in the Rarity enum means a rarer item
	var rarity_order: Array = StandardItem.Rarity.values()
	reward_items.sort_custom(func(a: StandardItem, b: StandardItem) -> bool:
		return rarity_order.find(a.rarity) > rarity_order.find(b.rarity))


## The names of the reward items, e.g. ["RARE Dagger", "COMMON Charm"].
func _get_reward_item_names() -> PackedStringArray:
	var reward_names := PackedStringArray()
	for reward_item in reward_items:
		reward_names.append(reward_item.name)
	return reward_names


## Fills in a boss quest read from the Milestone Story Parts rows (the days
## 30, 40 and 50 bosses). Gold is the same 300 + 150 per rank as the others.
## rank: difficulty; slots: maxAdventurers; story_row: row of Milestone Story
## Parts.txt; region: index into QuestManager.world_regions; favored: the
## FavoredStat; title: the quest's title on the board.
func _init_boss_vars(rank: int, slots: int, story_row: int, region: int, favored: FavoredStat, title: String) -> void:
	difficulty = rank
	maxAdventurers = slots
	questNum = story_row
	type = ExternalContentContainer.get_Milestone_story(questNum, 0).to_int()
	regionNum = region
	location = QuestManager.world_regions[regionNum].returnName(type)
	goldReward = 300 + (150 * difficulty)
	startingGoldReward = 300 + (150 * difficulty)
	favStat = favored
	questTitle = title
	styleOfQuest = 2


func _initMilestoneVars(dayNum: int):
	match dayNum:
		10:
			difficulty = 2
			maxAdventurers = 3
			questNum = 0
			type = ExternalContentContainer.get_Milestone_story(questNum, 0).to_int()
			regionNum = 1
			location = QuestManager.world_regions[regionNum].returnName(type)
			goldReward = 300 + (150 * difficulty)
			startingGoldReward = 300 + (150 * difficulty)
			favStat = FavoredStat.Defense
			questTitle = str("A Bone Drake is ATTACKING ", location, "! Save the town before it is DESTROYED!")
			styleOfQuest = 2
		20:
			difficulty = 3
			maxAdventurers = 3
			questNum = 1
			type = ExternalContentContainer.get_Milestone_story(questNum, 0).to_int()
			regionNum = 2
			location = QuestManager.world_regions[regionNum].returnName(type)
			goldReward = 300 + (150 * difficulty)
			startingGoldReward = 300 + (150 * difficulty)
			favStat = FavoredStat.Power
			questTitle = str("Defeat the RESURRECTED BONE DRAKE!")
			styleOfQuest = 2
		-20:
			difficulty = 3
			maxAdventurers = 3
			questNum = 2
			type = ExternalContentContainer.get_Milestone_story(questNum, 0).to_int()
			regionNum = 3
			location = QuestManager.world_regions[regionNum].returnName(type)
			goldReward = 300 + (150 * difficulty)
			startingGoldReward = 300 + (150 * difficulty)
			favStat = FavoredStat.Wisdom
			questTitle = str("Pursue a NECROMANCER and defeat him!")
			styleOfQuest = 2
		30:
			# Blood Moon Cult's portal, the first Demon General
			_init_boss_vars(3, 5, 3, 2, FavoredStat.Sleaze, # region 2 = Ashen Wastes
					"Close the Blood Moon Cult's portal and defeat the DEMON GENERAL!")
		40:
			# King Bernard, the Power and Defense general
			_init_boss_vars(4, 4, 4, 1, FavoredStat.PowerAndDefense, # region 1 = Boglands
					"Unmask and defeat the DEMON GENERAL KING BERNARD!")
		-40:
			# King Alastair, the Wisdom and Sleaze general
			_init_boss_vars(4, 5, 5, 3, FavoredStat.WisdomAndSleaze, # region 3 = Glass Mountains
					"Unmask and defeat the DEMON GENERAL KING ALASTAIR!")
		50:
			# THE DEMON KING, the final battle
			_init_boss_vars(5, 8, 6, 0, FavoredStat.Pluck, # region 0 = Windswept Meadows
					"Face THE DEMON KING!")
		_:
			var storyNum = 0
			match dayNum:
				1:
					storyNum = 0
				2:
					storyNum = 1
				4:
					storyNum = 2
				7:
					storyNum = 3
				9:
					storyNum = 4
				12:
					storyNum = 5
				15:
					storyNum = 6
				18:
					storyNum = 7
				-18:
					storyNum = 8
				# lead-up side quests (MinorVariables rows 9-21) building to the bosses.
				# The three "AWOL Advisor" quests: row 15 reveals Bernard, 17 reveals
				# Alastair, and 16 (both) comes last, just before day 40.
				22:
					storyNum = 9
				24:
					storyNum = 10
				26:
					storyNum = 11
				28:
					storyNum = 12
				32:
					storyNum = 13
				33:
					storyNum = 14
				34:
					storyNum = 15
				36:
					storyNum = 17
				38:
					storyNum = 16
				39:
					storyNum = 18
				42:
					storyNum = 19
				45:
					storyNum = 20
				48:
					storyNum = 21
					
			difficulty = ExternalContentContainer.get_Minor_Story_Variables(storyNum, 0).to_int()
			maxAdventurers = ExternalContentContainer.get_Minor_Story_Variables(storyNum, 1).to_int()
			questNum = ExternalContentContainer.get_Minor_Story_Variables(storyNum, 2).to_int()
			type = ExternalContentContainer.get_Minor_Story(questNum, 0).to_int()
			regionNum = ExternalContentContainer.get_Minor_Story_Variables(storyNum, 3).to_int()
			location = QuestManager.world_regions[regionNum].returnName(type)
			goldReward = ExternalContentContainer.get_Minor_Story_Variables(storyNum, 4).to_int()
			startingGoldReward = ExternalContentContainer.get_Minor_Story_Variables(storyNum, 4).to_int()
			favStat = ExternalContentContainer.get_Minor_Story_Variables(storyNum, 5).to_int()
			questTitle = ExternalContentContainer.get_Minor_Story_Variables(storyNum, 6)
			styleOfQuest = 1
			
			print("diff: ", difficulty, " maxAd: ", maxAdventurers, " questNum: ", questNum, " type: ", type, " region: ", regionNum,
			" loc: ", location, " gold: ", goldReward, " favStat: ", favStat, " title: ", questTitle, " style: ", styleOfQuest)

	print("")
	#pass

#one line per adventurer who died on this quest, added to the summary too
#(dead adventurers stay in the roster so the Hospital can revive them)
func _deathLines() -> String:
	var deathText = ""
	for char in dead_adventurers:
		deathText = str(deathText, "Unfortunately [b]", char.name, "[/b] succumbed to their injuries and passed away.\n")
	questSummary = str(questSummary, deathText)
	return deathText


func generatePartyDuo() -> Array[GuildCharacter]:
	var party: Array[GuildCharacter]

	var firstAdventurer = GuildCharacter.new()
	var secondAdventurer = GuildCharacter.new()

	party.append(firstAdventurer)
	party.append(secondAdventurer)

	return party
