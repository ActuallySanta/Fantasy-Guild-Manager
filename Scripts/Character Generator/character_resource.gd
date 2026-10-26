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
var hometown: Region
var description: String
var max_rand_backstories: int = 3

var role: CharacterRole

var injury_level: InjuryLevel
var injury_count: int

var stat_deviation: int = 2

var stats: Dictionary[StatType, int] = {
	StatType.STRENGTH: 0,
	StatType.DEFENSE: 0,
	StatType.WISDOM: 0,
	StatType.SLEAZINESS: 0,
}

var temp_stats: Dictionary[StatType, int] = {
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

var icon: Texture2D

var equipped_items: Array[StandardItem]

var max_items: int = 2


#The constructor, called when the object is created
func _init() -> void:
	# Get a random gender, role, and name
	gender = randi_range(0, CharacterGender.size() - 1) as CharacterGender
	role = randi_range(0, CharacterRole.size() - 1) as CharacterRole
	name = ExternalContentContainer.get_character_name(gender)

	hometown = QuestManager.world_regions.pick_random()

	icon = ExternalContentContainer.get_character_icon(role)

	# Generate the main stat
	generate_stat_spread(stats, total_points)
	description = generate_description()

	injury_level = InjuryLevel.HEALTHY
	injury_count = 0
	status = CharacterStatus.IDLE

	title = name + " the " + str(CharacterRole.find_key(role))

	pass


## Generate the stats using normalized random number sampling
func generate_stat_spread(_stats: Dictionary[StatType, int], _total_points: int) -> void:
	var _stat_weights: Array[float]
	# Make sure that the stat weights are the same size as the amount of stats
	_stat_weights.resize(_stats.size())

	var stat_sum: float

	#Generate random numbers and sum them all up
	for stat in _stat_weights.size():
		_stat_weights[stat] = randfn(_total_points / _stats.size(), stat_deviation)
		stat_sum += _stat_weights[stat]

	#After all the stats are added together, make them proportional to the total points
	for stat in _stats.size():
		var _proportion: float = _stat_weights[stat] / stat_sum
		_stats[stat] = (_proportion * _total_points)

	pass


func generate_description() -> String:
	var _description = ExternalContentContainer.get_role_backstory(self) + "\n"

	for i in max_rand_backstories:
		var temp = ExternalContentContainer.get_random_backstory(self) + "\n"
		if (!_description.containsn(temp)):
			_description += temp

	return _description


func injure_character() -> bool:
	injury_count += 1
	injury_level += 1

	if (injury_level == InjuryLevel.DEAD):
		return true
	else:
		return false


func level_up_random_stat(_points_to_add: int):
	for i in _points_to_add:
		var stat_to_pick = stats.keys().pick_random()
		stats[stat_to_pick] += 1
		total_points += 1


func increase_temp_stat(_stat: StatType, _points_to_add: int):
	temp_stats[_stat] += _points_to_add
	pass


func reset_temp_stats():
	for entry in temp_stats:
		temp_stats[entry] = 0


##Add all the stats from the equipped item slots
func add_passive_item_stats():
	for item in equipped_items:
		if (item is PassiveItem):
			var pass_item: PassiveItem = item as PassiveItem
			increase_temp_stat(pass_item.affected_stat, pass_item.stat_amount)


##Attempt to add an item in, returns true if the item was added, false if it wasn't able to
func try_add_item(_item: StandardItem) -> bool:
	if (equipped_items.size() < max_items):
		equipped_items.append(_item)
		return true
	else:
		return false
