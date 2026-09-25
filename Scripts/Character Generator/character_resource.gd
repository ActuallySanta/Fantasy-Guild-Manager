extends Resource

class_name GuildCharacter

enum CharacterGender {
	FEMALE = 0,
	MALE = 1,
	ANDROGYNOUS = 2,
}

enum CharacterRole {
	KNIGHT = 0,
	PRIEST = 1,
	PATHFINDER = 2,
	MAGE = 3,
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

var total_points:int = 20

var gender: CharacterGender


#The constructor, called when the object is created
func _init() -> void:
	gender = randi_range(0, CharacterGender.size()) as CharacterGender
	role = randi_range(0,CharacterRole.size()) as CharacterRole
	name = ExternalContentContainer._get_character_name(gender)
	
	_generate_stat_spread(stats,total_points)
	
	injury_level = InjuryLevel.HEALTHY
	pass

func _generate_stat_spread(_stats : Dictionary[StatType,int], _total_points : int)-> void:
	var _stat_weights : Array[float]
	# Make sure that the stat weights are the same size as the amount of stats
	_stat_weights.resize(_stats.size())
	
	var stat_sum : float
	
	#Generate random numbers and sum them all up
	for stat in _stat_weights:
		stat = randf()
		stat_sum +=stat
	
	#After all the stats are added together, make them proportional to the total points
	for stat in _stat_weights:
		var _proportion : float = stat/stat_sum
		stat = (_proportion*_total_points)
		
	pass
