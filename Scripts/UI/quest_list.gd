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
	GameState.day_started.connect(_on_day_started)
	populate(_generate_quests())

# creates new quests on new day
func _on_day_started(_day: int) -> void:
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
		if(GameState.day != 10):
			add_quest(quest)
		else:
			add_quest(CreatedQuest.new(10))
			break
	
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
	# keep the quest you're filling in view when the roster opens under it
	card.accepted.connect(func(_quest): _focus_card(card))
	for slot in card.slots:
		slot.pressed.connect(_focus_card.bind(card))
	return card

# The roster panel opens below the quest board and shrinks it, which can
# push the quest you just accepted out of view. Once the layout has
# settled, scroll so that card's top sits at the top of the board, keeping
# its title and slots visible above the roster.
func _focus_card(card: QuestCard) -> void:
	var scroll := get_parent() as ScrollContainer
	if scroll == null:
		return
	# wait for the roster to open and the card's slot row to lay out
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(card) or not card.visible:
		return
	scroll.scroll_vertical = int(card.position.y)
	# if the card is near the bottom the scroll clamps, so at least make
	# sure the whole card is on screen
	scroll.ensure_control_visible(card)

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
