extends Node2D

@export var max_characters: int = 5
@export var active_characters: Array[GuildCharacter]

## How many characters will be shown at the character hiring screen
@export var max_hireable_characters: int = 3
var hireable_characters: Array[GuildCharacter] = []

signal on_hireables_refreshed
signal on_character_added


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
	on_hireables_refreshed.emit()


## Living members of the guild. The dead stay on the roster (so they can be
## revived) but don't take up a bed.
func living_count() -> int:
	return active_characters.filter(func(character):
		return character.injury_level < GuildCharacter.InjuryLevel.DEAD).size()


## True when there's a bed for one more living member.
func has_free_bed() -> bool:
	return living_count() < max_characters


func generate_new_character() -> void:
	if (not has_free_bed()):
		return

	var _new_char := GuildCharacter.new()
	active_characters.append(_new_char)
	print("NEW CHARACTER GENERATED: " + _new_char.name)
	pass


func add_character_to_guild(_character: GuildCharacter) -> bool:
	if (not has_free_bed()):
		return false
	
	if(GameState.day >= 3 && GameState.gold >= _character.cost):
		GameState.add_gold(-(_character.cost))
	elif(GameState.day >= 3):
		return false
	
	active_characters.append(_character)
	hireable_characters.erase(_character) # char hired, so no longer for hire
	print(_character.name + " HAS JOINED THE GUILD")
	on_character_added.emit()
	return true
