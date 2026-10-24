@abstract class_name StandardItem
extends Resource

@export var name: String
@export var description: String

@export var median_cost: int
@export var max_cost_deviation: int

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

@export var rarity: Rarity


func _init(_role: GuildCharacter.CharacterRole) -> void:
	name = ExternalContentContainer.get_item_title(_role)
	rarity = get_rarity()
	pass


func get_rarity() -> Rarity:
	var total_weight: int = 0
	for i in Rarity:
		total_weight += i

	var rarity_roll := randi_range(0, total_weight)

	var cumulative: int = 0

	for i in Rarity:
		cumulative += i
		if (rarity_roll <= cumulative):
			return i

	return Rarity.COMMON
