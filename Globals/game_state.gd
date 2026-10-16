# script to hold all of the game-wide values that all of our
# other screens will need
extends Node

# triggered after the day number goes up
signal day_started(day: int)

# triggered when one of the resources is changed
signal resources_changed

# The current day, starts on day 1.
var day: int = 1:
	get:
		return day

var gold: int:
	get:
		return GuildUpgrades.gold

var standing: int:
	get:
		return GuildUpgrades.standing


func _ready() -> void:
	GuildUpgrades.resources_changed.connect(resources_changed.emit)


# Called by Start New Day button.
func start_new_day() -> void:
	day += 1

	if CharacterContainer.has_method("refresh_hireable_characters"):
		CharacterContainer.refresh_hireable_characters()

	# Tell everything else the new day has begun.
	day_started.emit(day)


func add_gold(amount: int) -> void:
	GuildUpgrades.add_gold(amount)


func add_standing(amount: int) -> void:
	GuildUpgrades.add_standing(amount)


func reduce_standing(amount: int) -> void:
	GuildUpgrades.reduce_standing(amount)
