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

var curr_user: GuildCharacter


func _init(_role: GuildCharacter.CharacterRole) -> void:
	role = _role
	rarity = get_rarity()
	name = str(Rarity.find_key(rarity)) + " " + ExternalContentContainer.get_item_title(_role)

	#Each rarity tier costs 40% more than the one below it (Common = initial_cost)
	var tier: int = Rarity.values().find(rarity)
	mean_cost = roundi(initial_cost * pow(1.0 + rarity_cost_step, tier))

	#Deviate a little bit around the intial mean, then round to a clean price
	cost = maxi(snappedi(roundi(randfn(mean_cost, max_cost_deviation)), cost_rounding), cost_rounding)

	curr_user = null
	pass


func get_rarity() -> Rarity:
	var total_weight: int = 0
	for i in Rarity.values():
		total_weight += i

	var rarity_roll := randi_range(0, total_weight)

	var cumulative: int = 0

	for i in Rarity.keys().size():
		cumulative += Rarity.values()[i]
		if (rarity_roll <= cumulative):
			return Rarity.values()[i]

	return Rarity.COMMON
