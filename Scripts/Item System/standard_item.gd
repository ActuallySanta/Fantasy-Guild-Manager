@abstract class_name StandardItem

extends Resource

@export var name: String
@export var description: String

@export var mean_cost: int
@export var max_cost_deviation: int = 50

@export var icon: Texture2D

@export var role: GuildCharacter.CharacterRole

enum Rarity {
	COMMON = 35,
	UNCOMMON = 25,
	RARE = 20,
	LEGENDARY = 15,
	MYTHIC = 4,
	NAMED = 1,
}
var total_rarity: int = 100

@export var rarity: Rarity

var initial_cost = 250

## How much more each rarity tier costs than the one below it (0.4 = +40%)
var rarity_cost_step: float = 0.4

## Final prices are rounded to the nearest multiple of this (237 -> 250)
var cost_rounding: int = 50

var cost: int

## Relative weights for the low tiers. Whatever chance Legendary and Mythic
## don't take is split between these in this ratio. (The Rarity enum values
## are no longer used as weights, but they stay as they are: saves store them.)
## NAMED never rolls from the Shop or quests.
const LOW_TIER_WEIGHTS := {
	Rarity.COMMON: 35.0,
	Rarity.UNCOMMON: 25.0,
	Rarity.RARE: 20.0,
}

## Chance (percent) that a roll is Legendary, by the guild's standing rank
## (HallRules.standing_rank_for: F, D, C, B, A, S). Ranks past the end
## (none today) use the last entry.
const LEGENDARY_PERCENT_BY_RANK: Array[float] = [0.0, 0.0, 1.0, 5.0, 5.0, 10.0]

## Chance (percent) that a roll is Mythic, by the guild's standing rank
## (F, D, C, B, A, S). Ranks past the end use the last entry.
const MYTHIC_PERCENT_BY_RANK: Array[float] = [0.0, 0.0, 0.0, 1.0, 2.0, 5.0]

## How strongly quest difficulty pushes the low-tier roll toward Rare.
## Each low tier's weight is multiplied by (1 + difficulty * tier * this), so
## at difficulty 0 (F rank, and the Shop) the odds are the plain
## LOW_TIER_WEIGHTS. Difficulty doesn't change the Legendary/Mythic odds; only
## the guild's rank does.
var rarity_difficulty_shift: float = 0.3

var curr_user: GuildCharacter


## Builds a new item for a hero role.
## _role: which CharacterRole can equip this item.
## _difficulty: the QuestDifficulty it was found on (0 for Shop stock), which
## makes Rare more likely than Common. Legendary/Mythic odds come from the
## guild's standing rank (see get_rarity).
func _init(_role: GuildCharacter.CharacterRole, _difficulty: int = 0) -> void:
	role = _role
	rarity = get_rarity(_difficulty)
	name = str(Rarity.find_key(rarity)) + " " + ExternalContentContainer.get_item_title(_role)

	#Each rarity tier costs 40% more than the one below it (Common = initial_cost)
	var tier: int = Rarity.values().find(rarity)
	mean_cost = roundi(initial_cost * pow(1.0 + rarity_cost_step, tier))

	#Deviate a little bit around the intial mean, then round to a clean price
	cost = maxi(snappedi(roundi(randfn(mean_cost, max_cost_deviation)), cost_rounding), cost_rounding)

	curr_user = null
	pass


## Rolls a random rarity.
## Legendary and Mythic come first, at the flat chances for the guild's
## standing rank (LEGENDARY_PERCENT_BY_RANK / MYTHIC_PERCENT_BY_RANK), so
## they're locked until C and B rank. Otherwise it's a weighted pick among
## Common/Uncommon/Rare.
## difficulty: the QuestDifficulty the item comes from (0 = no shift). Higher
## difficulties move low-tier weight from Common toward Rare.
## Returns the rolled Rarity (never NAMED).
func get_rarity(difficulty: int = 0) -> Rarity:
	var guild_rank: int = HallRules.standing_rank_for(GameState.standing)
	var mythic_percent: float = MYTHIC_PERCENT_BY_RANK[mini(guild_rank, MYTHIC_PERCENT_BY_RANK.size() - 1)]
	var legendary_percent: float = LEGENDARY_PERCENT_BY_RANK[mini(guild_rank, LEGENDARY_PERCENT_BY_RANK.size() - 1)]

	var high_roll := randf() * 100.0
	if high_roll < mythic_percent:
		return Rarity.MYTHIC
	if high_roll < mythic_percent + legendary_percent:
		return Rarity.LEGENDARY

	# Low tiers: each base weight scaled by its tier index times the
	# difficulty. Tier 0 (Common) never changes.
	var low_tiers: Array = LOW_TIER_WEIGHTS.keys()
	var tier_weights: Array[float] = []
	var total_weight: float = 0.0
	for tier in low_tiers.size():
		var tier_weight: float = LOW_TIER_WEIGHTS[low_tiers[tier]] * (1.0 + difficulty * tier * rarity_difficulty_shift)
		tier_weights.append(tier_weight)
		total_weight += tier_weight

	var rarity_roll := randf_range(0.0, total_weight)

	# Walk up the tiers until the running total passes the roll
	var cumulative: float = 0.0
	for tier in tier_weights.size():
		cumulative += tier_weights[tier]
		if (rarity_roll <= cumulative):
			return low_tiers[tier]

	return Rarity.COMMON
