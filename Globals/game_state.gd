# script to hold all of the game-wide values that all of our
# other screens will need
extends Node
 
# triggered after the day number goes up
signal day_started(day: int)
 
# The current day, starts on day 1.
var day: int = 1
 
# Called by Start New Day button.
func start_new_day() -> void:
	day += 1
 
	if CharacterContainer.has_method("refresh_hireable_characters"):
		CharacterContainer.refresh_hireable_characters()
 
	# Tell everything else the new day has begun.
	day_started.emit(day)
