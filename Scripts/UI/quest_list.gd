# this script is what fills content with sample quest cards
class_name QuestList
extends VBoxContainer

# emmited whenever quest board changes
signal board_changed

@export var quest_card_scene: PackedScene
@export var quests_per_day: int = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# tag node so other systems will be able to reach it
	add_to_group("quest_list")
	populate(_generate_quests())

func populate(quests: Array) -> void:
	if quest_card_scene == null:
		push_error("QuestList: drag quest_card.tscn into Quest Card Scene in the Inspector.")
		return
	
	# remove the old card
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	for quest in quests:
		add_quest(quest)
	
	# Old slots are gone, so put any characters back in the roster
	# and close it, since no quest is open anymore
	get_tree().call_group("roster", "refresh")
	get_tree().call_group("roster", "close")
	board_changed.emit()

# creates a quest card
func add_quest(quest) -> QuestCard:
	var card: QuestCard = quest_card_scene.instantiate()
	add_child(card)		# add so nodes are ready
	card.setup(quest)	# add data
	card.accepted.connect(_on_quest_accepted)
	card.closed.connect(_on_quest_closed)
	card.denied.connect(_on_quest_denied)
	card.party_changed.connect(_on_party_changed)
	return card

func _generate_quests() -> Array:
	var quests := []
	for i in quests_per_day:
		quests.append(CreatedQuest.new())
	return quests

# how many quests still need deicisions
func get_outstanding_count() -> int:
	var count := 0
	for card in get_children():
		if card is QuestCard and card.is_outstanding():
			count += 1
	return count

# returns every quest card thats ready to go out for the day
func get_dispatched_cards() -> Array[QuestCard]:
	var dispatched: Array[QuestCard] = []
	for card in get_children():
		if card is QuestCard and card.is_ready_to_send():
			dispatched.append(card)
	return dispatched

func _any_quest_open() -> bool:
	for card in get_children():
		if card is QuestCard and card.is_open:
			return true
	return false

# called when play accepts quest
func _on_quest_accepted(quest) -> void:
	get_tree().call_group("roster", "open")
	board_changed.emit()
	print("Accepted: ", QuestCard.get_title(quest))

func _on_quest_closed(quest) -> void:
	if not _any_quest_open():
		get_tree().call_group("roster", "close")
	board_changed.emit()
	print("Closed: ", QuestCard.get_title(quest))

func _on_quest_denied(quest) -> void:
	if not _any_quest_open():
		get_tree().call_group("roster", "close")
	board_changed.emit()
	print("Denied: ", QuestCard.get_title(quest))

# function to get the characters on quest
func _on_party_changed(quest, party: Array) -> void:
	board_changed.emit()
	var names := party.map(func(c): return CharacterButton.get_display_name(c))
	print(QuestCard.get_title(quest), " party: ", names)
