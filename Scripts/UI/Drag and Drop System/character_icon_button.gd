extends DragDropCell

class_name CharacterIconButton

@export var held_character: GuildCharacter


func _ready() -> void:
	icon = held_character.icon
	text = held_character.title
