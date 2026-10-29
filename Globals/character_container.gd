## The guild's roster, today's For Hire pool, and heroes who were released.
## Released heroes who are still alive may come back to For Hire on a later
## day, for a higher price (see refresh_hireable_characters).
extends Node2D

@export var max_characters: int = 5
@export var active_characters: Array[GuildCharacter]

## How many characters will be shown at the character hiring screen
@export var max_hireable_characters: int = 3
var hireable_characters: Array[GuildCharacter] = []

## Living heroes who were released from the guild. Each new day they have a
## small chance to show up in For Hire again. Hiring one takes them off this list.
var released_characters: Array[GuildCharacter] = []

## Chance (0-1) each released hero has of showing up in For Hire on a new day.
const RETURN_CHANCE := 0.15
## A returning hero costs this many times the day's normal recruit price...
const RETURN_COST_MULTIPLIER := 2
## ...counted from at least this much, so they're never free on days 1-2.
const RETURN_MIN_COST := 100

signal on_hireables_refreshed
signal on_character_added
signal on_character_removed


func _ready() -> void:
	#for i in max_characters:
	#generate_new_character()
	refresh_hireable_characters()
	pass


# Replaces the hiring pool with new characters on a new day
func refresh_hireable_characters() -> void:
	hireable_characters.clear()
	
	if(GameState.day <= 1):
		max_hireable_characters = 2
	elif(GameState.day <= 3):
		max_hireable_characters = 1
	elif(GameState.day <= 10):
		max_hireable_characters = 2
	else:
		max_hireable_characters = 3
		
	if (GameState.standing > GuildUpgrades.MINIMUM_STANDING):
		for i in max_hireable_characters:
			hireable_characters.append(GuildCharacter.new())
		_add_returning_characters()
	on_hireables_refreshed.emit()


## Each released hero rolls RETURN_CHANCE to come back to For Hire today.
## They come on top of the normal recruits, so they never push out a new face.
func _add_returning_characters() -> void:
	var return_cost := maxi(GuildCharacter.recruit_cost_for_day(GameState.day), RETURN_MIN_COST) \
			* RETURN_COST_MULTIPLIER
	for released_character in released_characters:
		if randf() < RETURN_CHANCE:
			released_character.cost = return_cost
			hireable_characters.append(released_character)


func generate_new_character() -> void:
	if (active_characters.size() == max_characters):
		return

	var _new_char := GuildCharacter.new()
	active_characters.append(_new_char)
	print("NEW CHARACTER GENERATED: " + _new_char.name)
	pass


func add_character_to_guild(_character: GuildCharacter) -> bool:
	if (active_characters.size() == max_characters):
		return false
	
	# anyone with a price pays it (returning heroes cost gold even on days 1-2)
	if(_character.cost > 0 && GameState.gold >= _character.cost):
		GameState.add_gold(-(_character.cost))
	elif(_character.cost > 0):
		return false
	
	active_characters.append(_character)
	hireable_characters.erase(_character) # char hired, so no longer for hire
	released_characters.erase(_character) # a returning hero is back for good
	print(_character.name + " HAS JOINED THE GUILD")
	on_character_added.emit()
	return true


## Takes a hero off the roster for good: their gear goes back to the pack and
## they leave the Training Yard and the Hospital. Living heroes are remembered
## in released_characters so they might come back to For Hire later.
## Leaving a quest party is the hall's job (see HallMain.release).
## Returns false if they weren't in the guild.
func remove_character_from_guild(_character: GuildCharacter) -> bool:
	if (not active_characters.has(_character)):
		return false

	# duplicate: unequipping changes equipped_items while we loop over it
	for item in _character.equipped_items.duplicate():
		ItemShop.unequip(item)
	GuildUpgrades.stop_training(_character)
	GuildUpgrades.discharge(_character)

	active_characters.erase(_character)
	if (_character.injury_level < GuildCharacter.InjuryLevel.DEAD):
		released_characters.append(_character)
	print(_character.name + " HAS LEFT THE GUILD")
	on_character_removed.emit()
	return true
