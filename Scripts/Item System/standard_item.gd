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

var cost: int

var curr_user: GuildCharacter


func _init(_role: GuildCharacter.CharacterRole) -> void:
	rarity = get_rarity()
	name = str(Rarity.find_key(rarity)) + " " + ExternalContentContainer.get_item_title(_role)

	var rarity_percentage = rarity / total_rarity

	#Take a discount off of the initial cost based on the rarity of the item - less rare items have a lower median cost
	mean_cost = initial_cost - (rarity * initial_cost)

	#Deviate a little bit around the intial mean
	cost = randfn(mean_cost, max_cost_deviation)

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
