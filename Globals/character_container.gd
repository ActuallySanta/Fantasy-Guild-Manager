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
	
	if(GameState.day >= 4 && GameState.gold >= 200):
		print("GameState.add_gold(-200)")
	elif(GameState.day >= 4):
		return false
	
	active_characters.append(_character)
	hireable_characters.erase(_character) # char hired, so no longer for hire
	print(_character.name + " HAS JOINED THE GUILD")
	on_character_added.emit()
	return true
