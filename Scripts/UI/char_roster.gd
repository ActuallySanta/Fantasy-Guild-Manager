# fills the roster with buttons that act as character
extends HFlowContainer
@export var character_button_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Tag this node so slots can tell it to refresh with
	# get_tree().call_group("roster", "refresh").
	# add_to_group("roster", "refresh")
	add_to_group("roster")
	rebuild()
	
	# clears roster and rebuilds it from character system
func rebuild() -> void:
	if character_button_scene == null:
		push_error("Roster: drag character_button.tscn into Character Button Scene in the Inspector.")
		return
		
	# return the old buttons first so we never get duplicates
	for child in get_children():
		remove_child(child)
		child.queue_free()
		
	# one button per character the guild has
	for character in CharacterContainer.active_characters:
		var button: CharacterButton = character_button_scene.instantiate()
		add_child(button)
		button.setup(character)
		
	# keep anyone already sitting in a slot hidden
	refresh()
		

# hides every character in a quest slot and shows everyone else
func refresh() -> void:
	# collect characters in slots
	var placed := []
	for slot in get_tree().get_nodes_in_group("character_slots"):
		if slot.character != null:
			placed.append(slot.character)

	# hide buttons characters are in the list
	for button in get_children():
		var is_placed := placed.any(func(c): return is_same(c, button.character))
		button.visible = not is_placed
