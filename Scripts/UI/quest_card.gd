# Creates a template for quests on the UI with
# an accept button and slots to assign characters
class_name QuestCard
extends PanelContainer

# triggers when play accepts quest
signal accepted(quest)
signal closed(quest)
signal denied(quest)

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

# true once player denies quest
var is_denied := false

# get slots for the quests for reading and writing
var slots: Array[CharacterSlot] = []

# @onready grabs the nodes that are marked with 
# a % once scene is ready, makes sure if scene tree is 
# changed everything works
@onready var _title_label: Label = %TitleLabel
@onready var _accept_button: Button = %AcceptButton
@onready var _deny_button: Button = %DenyButton
@onready var _slot_row: HFlowContainer = %SlotRow


func _ready() -> void:
	# slots stay hidden untill quest is accepted
	_slot_row.visible = false
	_accept_button.pressed.connect(_on_accept_pressed)
	_deny_button.pressed.connect(_on_deny_pressed)


# called by quest_list.gd after card is added to scene
func setup(data) -> void:
	quest = data
	_update_text()
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


# quest headline, where title goes
static func get_title(q: CreatedQuest) -> String:
	return q.questTitle


# smaller info lines under title: type, reward, party size, favored stat, success chance
static func get_details(q: CreatedQuest, chance: int = -1) -> String:
	# Once difficulty is added ill add the rank in:
	# var rank = CreatedQuest.QuestDifficulty.find_key(q.difficulty)
	var stat = CreatedQuest.FavoredStat.find_key(q.favStat)

	var count := get_slot_count(q)
	var adventurers := "1 Adventurer" if count == 1 else "%d Adventurers" % count

	var chance_text := "Success Chance: --"
	if chance >= 0:
		chance_text = "Success Chance: %d%%" % mini(chance, 100)

	return "%s - %d Gold\n%s - Favors: %s\n%s" % [get_type_name(q), q.goldReward, adventurers, stat, chance_text]


# turns the QuestType enum into a name players can read
static func get_type_name(q: CreatedQuest) -> String:
	match q.type:
		CreatedQuest.QuestType.DungeonClear:
			return "Clear Dungeon Quest"
		CreatedQuest.QuestType.Escort:
			return "Escort Quest"
		CreatedQuest.QuestType.ScoutTerrain:
			return "Scout Terrain Quest"
		CreatedQuest.QuestType.GatherIntel:
			return "Gather Intel Quest"
		_:
			return "Unknown Quest"


# How many character slots each quests needs, currently
# no party size value but if its added later
static func get_slot_count(q: CreatedQuest) -> int:
	return q.maxAdventurers if q.maxAdventurers > 0 else 2
# -----------------------------------------------


# toggles card between open and closed
func _on_accept_pressed() -> void:
	is_open = not is_open
	_slot_row.visible = is_open
	_accept_button.text = "Cancel" if is_open else "Accept"

	# deny only shows when quest isn't accepted
	_deny_button.visible = not is_open

	if is_open:
		accepted.emit(quest)
	else:
		for slot in slots:
			slot.assign(null)
		closed.emit(quest)


# Turns the quest down but keeps quest data in case we need it
func _on_deny_pressed() -> void:
	for slot in slots:
		slot.assign(null) # send anyone in the slots back to the roster
	is_open = false
	is_denied = true
	visible = false

	denied.emit(quest)


# true if the player still needs to deal with this quest
func is_outstanding() -> bool:
	return not is_denied and not is_ready_to_send()


# returns characters currently placed on this quest
func get_party() -> Array:
	var party := []
	for slot in slots:
		if slot.character != null:
			party.append(slot.character)
	return party


# true if quest is accepted and every slot is filled
func is_ready_to_send() -> bool:
	return is_open and not get_party().is_empty()


# if any slot is changed, pass the updated party along
func _on_slot_changed(_slot: CharacterSlot) -> void:
	_update_text()
	party_changed.emit(quest, get_party())
	print(quest.calcSuccessChance(get_party()))


# rebuilds the title and details text with the current party's success chance
func _update_text() -> void:
	var party := get_party()
	var chance := -1
	if not party.is_empty():
		chance = quest.calcSuccessChance(party)
	_title_label.text = get_title(quest) + "\n" + get_details(quest, chance)
