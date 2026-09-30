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
	SLEAZINESS,
}

enum CharacterStatus {
	IDLE,
	ON_QUEST,
	TRAINING,
	HEALING,
	DEAD,
}

var name: String
var hometown: String
var description: String
var max_rand_backstories : int = 3

var role: CharacterRole

var injury_level: InjuryLevel

var stats: Dictionary[StatType, int] = {
	StatType.STRENGTH: 0,
	StatType.DEFENSE: 0,
	StatType.WISDOM: 0,
	StatType.SLEAZINESS: 0,
}

var pluck: int = 0

var total_points: int = 20

var gender: CharacterGender

var status: CharacterStatus

var title: String


#The constructor, called when the object is created
func _init() -> void:
	# Get a random gender, role, and name
	gender = randi_range(0, CharacterGender.size() - 1) as CharacterGender
	role = randi_range(0, CharacterRole.size() - 1) as CharacterRole
	name = ExternalContentContainer._get_character_name(gender)

	# Generate the main stat
	_generate_stat_spread(stats, total_points)
	description = generate_description()

	injury_level = InjuryLevel.HEALTHY
	status = CharacterStatus.IDLE

	title = name + " the " + str(CharacterRole.find_key(role))

	pass


## Generate the stats using normalized random number sampling
func _generate_stat_spread(_stats: Dictionary[StatType, int], _total_points: int) -> void:
	var _stat_weights: Array[float]
	# Make sure that the stat weights are the same size as the amount of stats
	_stat_weights.resize(_stats.size())

	var stat_sum: float

	#Generate random numbers and sum them all up
	for stat in _stat_weights.size():
		_stat_weights[stat] = randf()
		stat_sum += _stat_weights[stat]

	#After all the stats are added together, make them proportional to the total points
	for stat in _stats.size():
		var _proportion: float = _stat_weights[stat] / stat_sum
		_stats[stat] = (_proportion * _total_points)

	pass

func generate_description() -> String:
	
	var _description = ExternalContentContainer._get_role_backstory(self) +"\n"
	
	for i in max_rand_backstories:
		var temp = ExternalContentContainer._get_random_backstory(self)+"\n"
		if(!_description.containsn(temp)):
			_description +=temp
	
	return _description
