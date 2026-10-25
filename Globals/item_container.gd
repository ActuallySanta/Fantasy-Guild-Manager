extends Node

var owned_items: Array[StandardItem]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("\n")
	for i in 5:
		owned_items.append(PassiveItem.new(GuildCharacter.CharacterRole.values().pick_random()))
		print(owned_items[i].name)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
