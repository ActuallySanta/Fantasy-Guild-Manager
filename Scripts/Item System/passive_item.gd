extends StandardItem

class_name PassiveItem

@export var affected_stat: GuildCharacter.StatType
@export var stat_amount: int

var stat_addition_table: Dictionary[StandardItem.Rarity, int] = {
	StandardItem.Rarity.COMMON: 2,
	StandardItem.Rarity.UNCOMMON: 8,
	StandardItem.Rarity.RARE: 16,
	StandardItem.Rarity.LEGENDARY: 24,
	StandardItem.Rarity.MYTHIC: 32,
	StandardItem.Rarity.NAMED: 40,
}


func _init(_role: GuildCharacter.CharacterRole) -> void:
	super._init(_role)
	affected_stat = GuildCharacter.StatType.values().pick_random()
	stat_amount = stat_addition_table[rarity]
