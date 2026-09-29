# Creates a template for quests on the UI with
# an accept button and slots to assign characters
class_name QuestCard

extends PanelContainer

# triggers when play accepts quest
signal accepted(quest)

# triggers when a character is added or removed from quest
# the party array is the characters that are in the slots
# for the quest
signal party_changed(quest, party: Array)

var quest

# keeps track of the cards slots
var slots: Array[CharacterSlot] = []

# refs to nodes we need to change later
var _accept_button: Button
var _slot_row: HFlowContainer

# called by quest_list.gd after creating the card
func setup(data) -> void:
	quest = data
	_build()

# build card at runtime instead of new scene (lowkey might change later)
func _build() -> void:
	# Stretch the card across the full width of the list.
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
 
	# Card background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.25, 0.15)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
 
	# The card holds one column: header on top, slots underneath.
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	
	# header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)
	var title := Label.new()
	title.text = str(quest.get("title"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	_accept_button = Button.new()
	_accept_button.text = "Accept"
	_accept_button.custom_minimum_size = Vector2(160, 90)
	_accept_button.pressed.connect(_on_accept_pressed)
	header.add_child(_accept_button)
	
	# slot row
	_slot_row = HFlowContainer.new()
	_slot_row.add_theme_constant_override("h_separation", 12)
	_slot_row.add_theme_constant_override("v_separation", 12)
	_slot_row.visible = false
	column.add_child(_slot_row)
 
	# Make as many slots as the quest asks for.
	for i in int(quest.get("slots")):
		var slot := CharacterSlot.new()
		slot.changed.connect(_on_slot_changed)
		_slot_row.add_child(slot)
		slots.append(slot)

# Runs when the Accept/Cancel button is pressed
# toggles between open and closed
func _on_accept_pressed() -> void:
	var is_open := not _slot_row.visible
	_slow_row.visible = is_open
	_accept_button.text = "Cancel" if is_open else "Accept"

	if is_open:
		accepted.emit(quest)
	else:
		# Empty every slot and send characters back
		for slot in slots:
			slot.assign(null)
