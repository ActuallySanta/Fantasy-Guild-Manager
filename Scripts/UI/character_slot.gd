# creates the slot on the quest to add a character
class_name CharacterSlot
extends Button

# send signal whenever slot changes
signal changed(slot: CharacterSlot)

# text for empty slot
const EMPTY_TEXT = "+"

# character currently in slot
var character = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# tag every slot so we can find them all later
	add_to_group("character_slots")
	pressed.connect(_on_pressed)

# Runs when a player taps or clicks slot
func _on_pressed() -> void:
	if CharacterButton.selected:
		# Assign selected character from roster here
		assign(CharacterButton.selected.character)
		CharacterButton.clear_selection()
	elif character != null:
		# if nothing is selected but slot if filled empty it
		assign(null)

# Godot asks this while something is dragged over the slot.
# true = "you're allowed to drop that here."
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == "character"
 
 
# Godot calls this when a valid drag is released over the slot.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	assign(data["character"])

# function that actaully changes whats in the slot 
func assign (new_character) -> void:
	# make sure only one character can be in a slot at a time
	if new_character != null:
		for slot in get_tree().get_nodes_in_group("character_slots"):
			if slot != self and is_same(slot.character, new_character):
				slot.assign(null)
	
	character = new_character
	text = EMPTY_TEXT if character == null else str(character.get("name"))
	changed.emit(self)
	
	# hide placed characters and show free ones
	get_tree().call_group("roster", "refresh")
