extends Node

var owned_items: Array[StandardItem]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func give_item_to_character(_item: StandardItem, _character: GuildCharacter) -> void:
	if (_item.curr_user != null):
		remove_item_from_character(_item, _item.curr_user)

	_character.equipped_items.append(_item)
	_item.curr_user = _character


func remove_item_from_character(_item: StandardItem, _character: GuildCharacter) -> bool:
	if (!_character.equipped_items.has(_item)):
		return false
	else:
		_character.equipped_items.erase(_item)
		_item.curr_user = null
		return true
	return false
