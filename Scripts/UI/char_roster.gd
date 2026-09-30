# fills the roster with buttons that act as character
extends HBoxContainer
@export var character_button_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if character_button_scene == null:
		push_error("Roster: drag character_button.tscn into Character Button Scene in the Inspector.")
		return
	
	for character in _get_characters():
		var button: CharacterButton = character_button_scene.instantiate()
		add_child(button)	# add first
		button.setup(character)		# fill data

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
