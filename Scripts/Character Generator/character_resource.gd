extends Resource
class_name GuildCharacter

enum CHARACTER_ROLE{
	KNIGHT,
	PRIEST,
	PATHFINDER,
	MAGE,
}

enum INJURY_LEVEL{
	HEALTHY = 0,
	SORE = 1,
	LIGHTLY_INJURED = 2,
	GRAVELY_INJURED = 3,
	DEAD = 4,
}

var name:String

var role:CHARACTER_ROLE

var injury_level:INJURY_LEVEL

var strength : int = 0
var defense: int = 0 
var wisdom : int = 0
var pluck : int = 0

#The constructor, called when the object is created
func _init() -> void:
	pass
