# fills the roster with buttons that act as character
extends HFlowContainer
@export var character_button_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Tag this node so slots can tell it to refresh with
	# get_tree().call_group("roster", "refresh").
	add_to_group("roster")
	
	if character_button_scene == null:
		push_error("Roster: drag character_button.tscn into Character Button Scene in the Inspector.")
		return
	
	for character in _get_characters():
		var button: CharacterButton = character_button_scene.instantiate()
		add_child(button)	# add first
		button.setup(character)		# fill data

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

# placeholder character info
func _get_characters() -> Array:
	return [
		{"name": "Jordan"},
		{"name": "Daniel"},
		{"name": "Jacob"},
		{"name": "Santi"},
		{"name": "Alex"},
		{"name": "Mark"},
	]
