extends Resource

class_name CreatedQuest

enum QuestDifficulty {
	F = 0,
	D = 1,
	C = 2,
	B = 3,
	A = 4,
	S = 5,
}

enum QuestType {
	#skip 0 for now
	DungeonClear = 1,
	Escort = 2,
	ScoutTerrain = 3,
	GatherIntel = 4,
}

enum FavoredStat {
	Attack = 0,
	Defense = 1,
	Wisdom = 2,
	Sleaze = 3,
	Pluck = 4,
}

#enum for modifiers if we ever choose to do them

var numAdventurers: int
var maxAdventurers: int
var goldReward: int
#var for statReward if applicable

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

## Equipment the party found while searching on this quest. The guild keeps it
## whether or not the quest succeeds (hall_main adds it to ItemContainer).
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

## The equipment this quest pays instead of gold, rolled when the quest is made
## so the Board can show it. Empty for a normal gold quest. Only paid out when
## the quest succeeds (hall_main / DayBar add it to ItemContainer).
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

func _init(diff := 0, dayNum := 0) -> void:
	if (dayNum == 10):
		_initMilestoneVars(dayNum)
		return

	difficulty = diff
	maxAdventurers = randi_range(1, 3)
	regionNum = randi_range(0, 3)
	questNum = randi_range(0, 7)
	type = ExternalContentContainer.get_Quest_Story(questNum, 0).to_int()
	location = QuestManager.world_regions[regionNum].returnName(type)
	print(regionNum, " ", location)
	
	if(maxAdventurers == 1):
		goldReward = 100 + (150 * difficulty)
	else:
		goldReward = 150 + (175 * difficulty)

	# Some quests pay in equipment instead: the items replace the base gold
	# (search finds can still add bonus gold to goldReward later)
	if (randf_range(0.0, 100.0) < _get_item_reward_chance()):
		_roll_reward_items()
		goldReward = 0

	match type:
		1:
			favStat = FavoredStat.Attack
			questTitle = str("Raid the ", location)
		2:
			favStat = FavoredStat.Defense
			questTitle = str("Escort someone to ", location)
		3:
			favStat = FavoredStat.Wisdom
			questTitle = str("Explore ", location)
		4:
			favStat = FavoredStat.Sleaze
			questTitle = str("Gather information on ", location)

	print("")
	pass


func calcSuccessChance(_questingAdventurers: Array) -> int:
	var statHitNum = 60.0 + (20 * difficulty)
	if (maxAdventurers == 1):
		statHitNum = (statHitNum / 2)
	var statTotal = 0.0

	for adventurer in _questingAdventurers:
		# Rebuild the temp stats first so the pluck bonus matches the current
		# pluck level and base stats (both change after quests, training, gear...)
		adventurer.reset_temp_stats()

		statTotal += adventurer.get_quest_stat(0) + adventurer.get_quest_stat(1) + adventurer.get_quest_stat(2) + adventurer.get_quest_stat(3)
		match favStat:
			0:
				statTotal += adventurer.get_quest_stat(0)
				#regioncheck
			1:
				statTotal += adventurer.get_quest_stat(1)
			2:
				statTotal += adventurer.get_quest_stat(2)
			3:
				statTotal += adventurer.get_quest_stat(3)

	return (snapped((statTotal / statHitNum), 0.01) * 100)


#this is the main root method for deciding and generating results I'll have
#methods branch off to decide certain parts of the results
func generateResults(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var returnString = ""

	numAdventurers = _questingAdventurers.size()
	#print(numAdventurers)

	var data = { "location": location }
	if (numAdventurers == 1):
		returnString = str(
			returnString,
			"[b]",
			_questingAdventurers[0].name,
			"[/b] ",
			ExternalContentContainer.get_Quest_Story(questNum, 1).c_unescape().format(data),
		)
	else:
		returnString = str(
			returnString,
			"[b]",
			_questingAdventurers[0].name,
			"[/b] and [b]",
			_questingAdventurers[1].name,
			"[/b] ",
			ExternalContentContainer.get_Quest_Story(questNum, 1).c_unescape().format(data),
		)

	var loopbreaker = 12 + (3 * difficulty)
	while randi_range(-1, 10) < loopbreaker:
		match randi_range(0, 1):
			0:
				returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
			1:
				returnString = str(returnString, _search(_questingAdventurers, _successChance))
		loopbreaker = loopbreaker - 1

	var successDetermination = randi_range(0, 100)
	match true:
		_ when successDetermination >= _successChance:
			if (numAdventurers == 1):
				returnString = str(returnString, "[b]", _questingAdventurers[0].name, " ", ExternalContentContainer.get_Quest_Story(questNum, 3).c_unescape().format(data))
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name,
					" ",
					ExternalContentContainer.get_Quest_Story(questNum, 3).c_unescape().format(data),
				)
			returnString = str(returnString, "[b]Summary[/b]: The quest was [color=red][b]NOT SUCCESSFUL[/b][/color]. Your guild failed to obtain the reward.\n")
			questSummary = str(questSummary, "[b]Summary[/b]: The quest was NOT SUCCESSFUL. Your guild failed to obtain the reward.\n")

			if (goldReward > 200):
				returnString = str(returnString, "However, your adventurers did bring back [color=FFE700][b]", goldReward - 200, " gold[/b][/color].\n")
				questSummary = str(questSummary, "However, your adventurers did bring back ", goldReward - 200, " gold")
		_:
			if (numAdventurers == 1):
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name, " ",
					ExternalContentContainer.get_Quest_Story(questNum, 4).c_unescape().format(data),
				)
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name, " ",
					ExternalContentContainer.get_Quest_Story(questNum, 4).c_unescape().format(data),
				)
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

func _combatEncounter(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var combatChance = _successChance / 100.0
	combatChance *= combatChance
	combatChance *= 100.0

	if combatChance > 90:
		combatChance = 90

	var returnString = ""
	var successDetermination = randi_range(0, 100)

	if combatChance >= successDetermination:
		var succComDet = randi_range(1, 100)
		if(1 <= succComDet && succComDet <= 25):
				returnString = str(
					"[b]The Party[/b] was ATTACKED by a group of ",
					QuestManager.world_regions[regionNum].returnMonster(),
					"s, but defeated them [color=green][b]without sustaining any injuries[/b][/color].\n"
				)
		elif (26 <= succComDet && succComDet <= 50):
				var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
				returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ",
					QuestManager.world_regions[regionNum].returnMonster(),
					", but defeated it [color=green][b]without sustaining any injuries[/b][/color].\n"
					)
		elif (51 <= succComDet && succComDet <= 75):
				returnString = str(
					"[b]The Party[/b] was ATTACKED by a group of ",
					QuestManager.world_regions[regionNum].returnMonster(),
					"s. They defeated them [color=green][b]without sustaining any injuries[/b][/color].\n"
					)
		elif (76 <= succComDet && succComDet <= 90):
				var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
				var extraGold = randi_range(11, 29)
				goldReward += extraGold
				returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ",
					QuestManager.world_regions[regionNum].returnMonster(),
					", and defeated it, finding [color=FFE700][b] ", extraGold," gold [/b][/color]on its corpse.\n"
					)
		elif (91 <= succComDet && succComDet <= 100):
				var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
				var extraGold = randi_range(11, 29)
				goldReward += extraGold
				returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ",
					QuestManager.world_regions[regionNum].returnMonster(), ", and defeated it, finding [color=FFE700][b] ", extraGold, 
					" gold [/b][/color]on its corpse. However, they were [color=FD0000][b]INJURED[/b][/color] in the process.\n"
					)
				var died : bool = attackedAdventurer.injure_character()
				
				if(died and not dead_adventurers.has(attackedAdventurer)):
					dead_adventurers.append(attackedAdventurer)

	else:
		var attackedAdventurer: GuildCharacter = _questingAdventurers.pick_random()
		var succComDet = randi_range(1, 100)
		
		if(1 <= succComDet && succComDet <= 25):
			returnString = str(
			"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ", QuestManager.world_regions[regionNum].returnMonster(),
			". They managed to fight the monster off but were [color=FD0000][b]INJURED[/b][/color] in the process.\n"
			)
		elif (26 <= succComDet && succComDet <= 50):
			returnString = str(
					"[b]The Party[/b] was ATTACKED by a group of ", QuestManager.world_regions[regionNum].returnMonster(),
					"s. They managed to defeat them, but not before [color=FD0000][b]", attackedAdventurer.name, " was INJURED[/b][/color] in the process.\n"
					)
		elif (51 <= succComDet && succComDet <= 75):
			returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ", QuestManager.world_regions[regionNum].returnMonster(),
					", and defeated it. However, they were [color=FD0000][b]INJURED[/b][/color] in the process.\n"
					)
		elif (76 <= succComDet && succComDet <= 90):
			returnString = str(
					"[b]The Party[/b] was ATTACKED by a group of ",
					QuestManager.world_regions[regionNum].returnMonster(),
					"s, but defeated them [color=green][b]without sustaining any injuries[/b][/color].\n"
				)
		elif (91 <= succComDet && succComDet <= 100):
				returnString = str(
					"[b]", attackedAdventurer.name, "[/b] was ATTACKED by a ",
					QuestManager.world_regions[regionNum].returnMonster(),
					", but defeated it [color=green][b]without sustaining any injuries[/b][/color].\n"
					)
		
		if(succComDet <=75):
			var died : bool = attackedAdventurer.injure_character()

			if(died and not dead_adventurers.has(attackedAdventurer)):
				dead_adventurers.append(attackedAdventurer)
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
	else:
		var succSearDet = randi_range(1, 100)
		if(1 <= succSearDet && succSearDet <= 15):
			returnString = str(returnString, "[b]", searchingAdventurer.name, "[/b] tripped on a rock and gained [color=FD0000][b]1 INJURY[/b][/color].\n")
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
			"[/b] was [color=FD0000][b]INJURED 1 TIME[/b][/color].\n")
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
## GameState.day (hall_main passes dayNum = 0 for normal quests, so the day is
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


func _initMilestoneVars(dayNum: int):
	match dayNum:
		10:
			difficulty = 2
			maxAdventurers = 2
			questNum = 0
			type = ExternalContentContainer.get_Milestone_story(questNum, 0).to_int()
			location = ExternalContentContainer.get_Location_Name(1)
			goldReward = 300 + (150 * difficulty)
			favStat = FavoredStat.Attack
			questTitle = str("A Bone Drake is ATTACKING ", location, "! Save the town before it is DESTROYED!")

	print("")
	pass


func generateMilestoneResults(_questingAdventurers: Array[GuildCharacter], _successChance: float) -> String:
	var returnString = ""
	numAdventurers = _questingAdventurers.size()

	var data = { "location": location }
	if (numAdventurers == 1):
		returnString = str(
			returnString,
			"[b]",
			_questingAdventurers[0].name,
			"[/b] ",
			ExternalContentContainer.get_Milestone_story(questNum, 1).c_unescape().format(data),
		)
	else:
		returnString = str(
			returnString,
			"[b]",
			_questingAdventurers[0].name,
			"[/b] and [b]",
			_questingAdventurers[1].name,
			"[/b] ",
			ExternalContentContainer.get_Milestone_story(questNum, 1).c_unescape().format(data),
		)

	var loopbreaker = 12 + (3 * difficulty)
	while randi_range(-1, 10) < loopbreaker:
		match randi_range(0, 1):
			0:
				returnString = str(returnString, _combatEncounter(_questingAdventurers, _successChance))
			1:
				returnString = str(returnString, _search(_questingAdventurers, _successChance))
		loopbreaker = loopbreaker - 1

	var successDetermination = randi_range(0, 100)
	match true:
		_ when successDetermination >= _successChance:
			if (numAdventurers == 1):
				returnString = str(returnString, "[b]", _questingAdventurers[0].name, "[/b] ", ExternalContentContainer.get_Milestone_story(questNum, 3).c_unescape().format(data))
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name,
					" ",
					ExternalContentContainer.get_Milestone_story(questNum, 3).c_unescape().format(data),
				)
			returnString = str(returnString, "Summary: The quest was [color=red][b]NOT SUCCESSFUL[/b][/color]. Your guild failed to obtain the reward.\n")
			questSummary = str(questSummary, "Summary: The quest was NOT SUCCESSFUL. Your guild failed to obtain the reward.\n")

			if (goldReward > 200):
				returnString = str(returnString, "However, your adventurers did bring back [color=gold][b]", goldReward - 200, " gold[/b][/color].\n")
				questSummary = str(questSummary, "However, your adventurers did bring back ", goldReward - 200, " gold")
		_:
			if (numAdventurers == 1):
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] ",
					ExternalContentContainer.get_Milestone_story(questNum, 4).c_unescape().format(data),
				)
			else:
				returnString = str(
					returnString,
					"[b]",
					_questingAdventurers[0].name,
					"[/b] and [b]",
					_questingAdventurers[1].name,
					ExternalContentContainer.get_Milestone_story(questNum, 4).c_unescape().format(data),
				)
			returnString = str(returnString, "Summary: The quest was [color=green][b]SUCCESSFUL[/b][/color]. Your guild gained [color=gold][b]", goldReward, " gold[/b][/color].\n")
			questSummary = str(questSummary, "Summary: The quest was SUCCESSFUL. Your guild gained ", goldReward, " gold.")

	# list found equipment after either outcome, since the guild keeps it either way
	returnString = str(returnString, _get_found_items_lines())
	returnString = str(returnString, _deathLines())

	return returnString


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
