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

## True once the main story is over and the player chose Begin Freeplay
## (HallMain.start_freeplay): days go on forever and quests keep scaling up.
var is_freeplay := false


func _ready() -> void:
	GuildUpgrades.resources_changed.connect(resources_changed.emit)


# Called by Start New Day button.
func start_new_day() -> void:
	day += 1

	if CharacterContainer.has_method("refresh_hireable_characters"):
		CharacterContainer.refresh_hireable_characters()

	_refresh_temp_stats()
	
	# Tell everything else the new day has begun.
	day_started.emit(day)

## Back to Day 1 for a new run (HallMain.start_new_run). Doesn't emit
## day_started: the hall scene is reloaded right after and builds Day 1 itself.
func reset() -> void:
	day = 1
	is_freeplay = false


func _refresh_temp_stats():
	for entry in CharacterContainer.active_characters:
		entry.reset_temp_stats()
	pass
	
func add_gold(amount: int) -> void:
	GuildUpgrades.add_gold(amount)


func add_standing(amount: int) -> void:
	GuildUpgrades.add_standing(amount)


func reduce_standing(amount: int) -> void:
	GuildUpgrades.reduce_standing(amount)
