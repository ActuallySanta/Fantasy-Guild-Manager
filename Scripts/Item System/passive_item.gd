extends StandardItem

class_name PassiveItem

@export var affected_stat: GuildCharacter.StatType
@export var stat_amount: int

var stat_addition_table: Dictionary[StandardItem.Rarity, int] = {
	StandardItem.Rarity.COMMON: 2,
	StandardItem.Rarity.UNCOMMON: 4,
	StandardItem.Rarity.RARE: 6,
	StandardItem.Rarity.LEGENDARY: 8,
	StandardItem.Rarity.MYTHIC: 10,
	StandardItem.Rarity.NAMED: 12,
}


func _init(_role: GuildCharacter.CharacterRole) -> void:
	super._init(_role)
	affected_stat = GuildCharacter.StatType.values().pick_random()
	stat_amount = stat_addition_table[rarity]
