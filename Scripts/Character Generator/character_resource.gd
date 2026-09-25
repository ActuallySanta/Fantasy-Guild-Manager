extends Resource

class_name GuildCharacter

enum CharacterGender {
	FEMALE = 0,
	MALE = 1,
	ANDROGYNOUS = 2,
}

enum CharacterRole {
	KNIGHT,
	PRIEST,
	PATHFINDER,
	MAGE,
}

enum InjuryLevel {
	HEALTHY = 0,
	SORE = 1,
	LIGHTLY_INJURED = 2,
	GRAVELY_INJURED = 3,
	DEAD = 4,
}

enum StatType {
	STRENGTH,
	DEFENSE,
	WISDOM,
	PLUCK,
}

var name: String

var role: CharacterRole

var injury_level: InjuryLevel

var stats: Dictionary[StatType, int] = {
	StatType.STRENGTH: 0,
	StatType.DEFENSE: 0,
	StatType.WISDOM: 0,
	StatType.PLUCK: 0,
}
var gender: CharacterGender


#The constructor, called when the object is created
func _init() -> void:
	gender = randi_range(0, 2)

	name = ExternalContentContainer._get_character_name(gender)
	pass
