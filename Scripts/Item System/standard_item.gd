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

## How strongly quest difficulty pushes the rarity roll toward better tiers.
## Each tier's weight is multiplied by (1 + difficulty * tier * this), so at
## difficulty 0 (F rank, and the Shop) the odds are the plain Rarity weights.
var rarity_difficulty_shift: float = 0.3

var curr_user: GuildCharacter


## Builds a new item for a hero role.
## _role: which CharacterRole can equip this item.
## _difficulty: the QuestDifficulty it was found on (0 for Shop stock), which
## makes higher rarities more likely.
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


## Rolls a weighted random rarity.
## difficulty: the QuestDifficulty the item comes from (0 = no shift). Higher
## difficulties move weight from the low tiers to the high tiers, so any rarity
## can still drop but hard quests favor better gear.
## Returns the rolled Rarity.
func get_rarity(difficulty: int = 0) -> Rarity:
	# Each tier's base weight (its Rarity value), scaled by how far up the
	# tier list it is times the difficulty. Tier 0 (Common) never changes.
	var tier_weights: Array[float] = []
	var total_weight: float = 0.0
	for tier in Rarity.values().size():
		var base_weight: float = Rarity.values()[tier]
		var tier_weight: float = base_weight * (1.0 + difficulty * tier * rarity_difficulty_shift)
		tier_weights.append(tier_weight)
		total_weight += tier_weight

	var rarity_roll := randf_range(0.0, total_weight)

	# Walk up the tiers until the running total passes the roll
	var cumulative: float = 0.0
	for tier in tier_weights.size():
		cumulative += tier_weights[tier]
		if (rarity_roll <= cumulative):
			return Rarity.values()[tier]

	return Rarity.COMMON
