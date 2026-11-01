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


## Builds a passive stat item for a hero role.
## _role: which CharacterRole can equip this item.
## _difficulty: the QuestDifficulty it was found on (0 for Shop stock), passed
## on to StandardItem so harder quests roll better rarities.
func _init(_role: GuildCharacter.CharacterRole, _difficulty: int = 0) -> void:
	super._init(_role, _difficulty)
	affected_stat = GuildCharacter.StatType.values().pick_random()
	stat_amount = stat_addition_table[rarity]
