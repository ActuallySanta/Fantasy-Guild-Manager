# Creates a template for quests on the UI with
# an accept button and slots to assign characters
class_name QuestCard
extends PanelContainer

# triggers when play accepts quest
signal accepted(quest)
signal closed(quest)

# triggers when a character is added or removed from quest
# the party array is the characters that are in the slots
# for the quest
signal party_changed(quest, party: Array)

# Used for character_slot scene
@export var slot_scene: PackedScene

# quest data
var quest

# check if quest is open
var is_open := false

# get slots for the quests for reading and writing
var slots: Array[CharacterSlot] = []

# @onready grabs the nodes that are marked with 
# a % once scene is ready, makes sure if scene tree is 
# changed everything works
@onready var _title_label: Label = %TitleLabel
@onready var _accept_button: Button = %AcceptButton
@onready var _slot_row: HFlowContainer = %SlotRow

func _ready() -> void:
	# slots stay hidden untill quest is accepted
	_slot_row.visible = false
	_accept_button.pressed.connect(_on_accept_pressed)

# called by quest_list.gd after card is added to scene
func setup(data) -> void:
	quest = data
	_title_label.text = get_title(quest) + "\n" + get_details(quest)
	
	if slot_scene == null:
		push_error("QuestCard: drag character_slot.tscn into Slot Scene in the Inspector.")
		return
	
	# make a slot for each slot the quest needs
	for i in get_slot_count(quest):
		var slot: CharacterSlot = slot_scene.instantiate()
		_slot_row.add_child(slot)
		slot.changed.connect(_on_slot_changed)
		slots.append(slot)

# right here is the only spot where I touch quest
# system data. Once Jacob changes things ill change
# stuff here

# quest headline, where I will add title
static func get_title(q) -> String:
	var title = q.get("title")
	if title:
		return str(title)
	
	match q.type:
		CreatedQuest.QuestType.DungeonClear:
			return "Clear the %s" % q.location
		CreatedQuest.QuestType.Escort:
			return "Escort a client through the %s" % q.location
		_:
			return "Raid the %s" % q.location

# smaller info line under title for rank and rewards
static func get_details(q) -> String:
	var rank = CreatedQuest.QuestDifficulty.find_key(q.difficulty)
	return "Rank %s - %d Gold" % [rank, q.goldReward]

# How many character slots each quests needs, currently
# no party size value but if its added later
static func get_slot_count(q) -> int:
	var size = q.get("party_size")
	return int(size) if size != null else 2
# -----------------------------------------------

# toggles card between open and closed
func _on_accept_pressed() -> void:
	is_open = not is_open
	_slot_row.visible = is_open
	_accept_button.text = "Cancel" if is_open else "Accept"
	
	if is_open:
		accepted.emit(quest)
	else:
		for slot in slots: 
			slot.assign(null)
		closed.emit(quest)

# returns characters currently placed on this quest
func get_party() -> Array:
	var party := []
	for slot in slots:
		if slot.character != null:
			party.append(slot.character)
	return party

# true if quest is accepted and every slot is filled
func is_ready_to_send() -> bool:
	return is_open and not slots.is_empty() and get_party().size() == slots.size()

# if any slot is changed, pass the updated party along
func _on_slot_changed(_slot: CharacterSlot) -> void:
	party_changed.emit(quest, get_party())
