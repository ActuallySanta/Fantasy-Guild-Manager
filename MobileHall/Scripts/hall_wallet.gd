## Hall wallet: the numbers behind the header's gold and standing popups
## (popup_gold.gd, popup_standing.gd). What standing unlocks next and how far
## it is from the floor where recruits stop coming; what tonight's quests could
## pay and what gold can buy right now. No state and no nodes: every function
## is static and reads the autoloads or takes what it needs.
class_name HallWallet


# ============================================================ SETTINGS

## Standing above GuildUpgrades.MINIMUM_STANDING at which the popup's red
## "loss" half reads empty. Closer to the floor than this, it fills up.
const LOSS_WINDOW := 20


# ============================================================ STANDING

## Every standing milestone, lowest first: [{at: int, kind: String, value: int}]
##   kind "rank_appears": quests of rank `value` start to show up (the first
##                        step past HallRules.STARTER_STANDING)
##   kind "rank":         quests center on rank `value` (a CreatedQuest.QuestDifficulty)
##   kind "upgrade":      buildings can be upgraded to level `value`
## Built from the tuning in HallRules and GuildUpgrades, so it follows them.
static func standing_milestones() -> Array[Dictionary]:
	var milestones: Array[Dictionary] = []
	# past STARTER_STANDING the board's ranks roll around the guild's rank, so rank 1 can show up
	milestones.append({"at": HallRules.STARTER_STANDING + 1, "kind": "rank_appears", "value": 1})
	# one rank up per STANDING_PER_RANK (standing_rank_for rounds up, so it's one point past each step)
	for rank in range(1, HallRules.TOP_STANDING_RANK + 1):
		milestones.append({"at": HallRules.STANDING_PER_RANK * rank + 1, "kind": "rank", "value": rank})
	# UPGRADE_STANDING_REQ[N - 1] is the standing needed to buy level N
	for level_index in GuildUpgrades.UPGRADE_STANDING_REQ.size():
		var needed: int = GuildUpgrades.UPGRADE_STANDING_REQ[level_index]
		if needed > 0:
			milestones.append({"at": needed, "kind": "upgrade", "value": level_index + 1})
	milestones.sort_custom(func(a, b): return a.at < b.at)
	return milestones


## The first milestone above `standing`, or {} once every one is reached.
static func next_standing_milestone(standing: int) -> Dictionary:
	for milestone in standing_milestones():
		if milestone.at > standing:
			return milestone
	return {}


## Where the green "gain" half starts: the last milestone reached, or the
## recruit floor when none has been reached yet.
static func previous_standing_mark(standing: int) -> int:
	var mark: int = GuildUpgrades.MINIMUM_STANDING
	for milestone in standing_milestones():
		if milestone.at <= standing:
			mark = milestone.at
	return mark


## How full the gain half is (0..1): progress from previous_standing_mark to
## the next milestone. 1 once every milestone is reached.
static func gain_fill(standing: int) -> float:
	var next := next_standing_milestone(standing)
	if next.is_empty():
		return 1.0
	var start := previous_standing_mark(standing)
	return clampf(float(standing - start) / float(next.at - start), 0.0, 1.0)


## Standing left before recruits stop coming (0 or less = they already have).
static func standing_above_floor(standing: int) -> int:
	return standing - GuildUpgrades.MINIMUM_STANDING


## How full the loss half is (0..1): empty at LOSS_WINDOW or more above the
## floor, full at the floor.
static func loss_fill(standing: int) -> float:
	return clampf(1.0 - float(standing_above_floor(standing)) / LOSS_WINDOW, 0.0, 1.0)


## Letter of the rank this much standing centers quests on ("F", "D", ...).
static func standing_rank_letter(standing: int) -> String:
	return rank_name(HallRules.standing_rank_for(standing))


## A CreatedQuest.QuestDifficulty as its letter.
static func rank_name(rank: int) -> String:
	return str(CreatedQuest.QuestDifficulty.find_key(rank))


# ============================================================ GOLD

## What tonight's quests could pay, from the quest entries on the board
## (HallMain.quest_entries). Gold found along the way can add a little more.
## Returns {best: int (every sent quest wins), expected: int (each weighted by
## its odds), sent_count: int, open_count: int (still waiting for Send or Deny),
## open_best: int (what those open ones pay on a win)}.
static func tonight_earnings(entries: Array) -> Dictionary:
	var result := {"best": 0, "expected": 0, "sent_count": 0, "open_count": 0, "open_best": 0}
	var expected := 0.0
	for entry in entries:
		var quest: CreatedQuest = entry.quest
		if entry.state == HallStyle.QUEST_STATE_OPEN:
			result.open_count += 1
			result.open_best += quest.goldReward
			continue
		if entry.state != HallStyle.QUEST_STATE_SENT:
			continue
		result.sent_count += 1
		result.best += quest.goldReward
		var party: Array[GuildCharacter] = []
		party.assign(entry.party)
		# calcSuccessChance can run past 100 (a sure thing)
		var chance := clampf(DayBar._get_success_chance(quest, party) / 100.0, 0.0, 1.0) if not party.is_empty() else 0.0
		# a loss still pays what DayBar says it does (gold found along the way)
		expected += chance * DayBar._get_gold_earned(quest, true) + (1.0 - chance) * DayBar._get_gold_earned(quest, false)
	result.expected = roundi(expected)
	return result


## What a new recruit costs to hire today.
static func recruit_price() -> int:
	return GuildCharacter.recruit_cost_for_day(GameState.day)


## Whether standing is too low for any recruit to come (see CharacterContainer).
static func are_recruits_blocked() -> bool:
	return GameState.standing <= GuildUpgrades.MINIMUM_STANDING


## The cheapest gear still on sale in the shop today, or -1 if it's sold out.
static func cheapest_gear_price() -> int:
	var cheapest := -1
	for index in ItemShop.stock.size():
		if ItemShop.is_sold(index):
			continue
		var cost: int = ItemShop.get_item(index).cost
		if cheapest < 0 or cost < cheapest:
			cheapest = cost
	return cheapest


## The cheapest building upgrade, or {} when every building is maxed:
## {gold: int, standing_short: bool (standing is too low to buy it yet)}.
static func cheapest_upgrade() -> Dictionary:
	var cheapest := {}
	for building in GuildUpgrades.Building.values():
		if not GuildUpgrades.is_implemented(building) or GuildUpgrades.is_max_level(building):
			continue
		var cost := GuildUpgrades.get_next_gold_cost(building)
		if cheapest.is_empty() or cost < cheapest.gold:
			var is_standing_short := GuildUpgrades.get_upgrade_status(building) == GuildUpgrades.UpgradeStatus.STANDING_TOO_LOW
			cheapest = {"gold": cost, "standing_short": is_standing_short}
	return cheapest
