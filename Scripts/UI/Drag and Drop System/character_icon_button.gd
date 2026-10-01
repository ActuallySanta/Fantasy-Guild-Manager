extends DragDropCell

class_name CharacterIconButton

@export var held_character: GuildCharacter


func _ready() -> void:
	icon = ExternalContentContainer._get_character_icon(held_character.role)
	text = held_character.title
