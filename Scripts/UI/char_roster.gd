# fills the roster with buttons that act as character
extends HFlowContainer
@export var character_button_scene: PackedScene
@export var roster_panel: Control
@export var close_button: Button

# shown instead of the roster when nobody is free to go on a quest
var _empty_notice: VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Tag this node so slots can tell it to refresh with
	# get_tree().call_group("roster", "refresh").
	# add_to_group("roster", "refresh")
	add_to_group("roster")
	CharacterContainer.on_character_added.connect(rebuild)
	
	if roster_panel == null:
		push_error("Roster: drag the Roster panel into Roster Panel in the Inspector.")
	if close_button:
		close_button.pressed.connect(close)
	else:
		push_error("Roster: drag the CloseButton into Close Button in the Inspector.")
	
	# rebuild when someone is hired
	CharacterContainer.on_character_added.connect(rebuild)
	
	_build_empty_notice()
	close()  # start hidden so the quest list gets the whole screen
	rebuild()

func open() -> void:
	rebuild()
	if roster_panel:
		roster_panel.visible = true

func close() -> void:
	if roster_panel:
		roster_panel.visible = false
	# don't leave character highlighted when roster is hidden
	CharacterButton.clear_selection()
	
func is_open() -> bool:
	return roster_panel != null and roster_panel.visible
	
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

	_update_empty_notice()


# true if at least one character is free to be put on a quest
func has_available_characters() -> bool:
	for button in get_children():
		if button is CharacterButton and button.visible:
			return true
	return false


# Message that replaces the roster when every
# character is already on a quest (or the guild has nobody yet)
func _build_empty_notice() -> void:
	_empty_notice = VBoxContainer.new()
	_empty_notice.name = "EmptyNotice"
	_empty_notice.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty_notice.alignment = BoxContainer.ALIGNMENT_CENTER
	_empty_notice.add_theme_constant_override("separation", 12)
	_empty_notice.visible = false
	# same height as the roster's scroll area so the panel doesn't jump
	_empty_notice.custom_minimum_size = Vector2(0, 270)

	var label := Label.new()
	label.text = "No one is free to go on this quest.\nHire more characters to fill the party!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 24)
	_empty_notice.add_child(label)

	# sits next to the roster's scroll area (RosterColumn) so it can
	# take the scroll area's place
	var scroll := get_parent()
	if scroll and scroll.get_parent():
		scroll.get_parent().add_child.call_deferred(_empty_notice)


func _update_empty_notice() -> void:
	if _empty_notice == null:
		return
	var nobody_free := not has_available_characters()
	_empty_notice.visible = nobody_free
	get_parent().visible = not nobody_free  # the RosterScroll

