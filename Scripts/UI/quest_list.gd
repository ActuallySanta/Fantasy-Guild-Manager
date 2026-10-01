# this script is what fills content with sample quest cards
extends VBoxContainer
@export var quest_card_scene: PackedScene
#@export var roster_panel: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if quest_card_scene == null:
		push_error("QuestList: drag quest card scene into inspector")
		return
		
	for quest in _get_quests():
		add_quest(quest)

# creates a quest card
func add_quest(quest) -> QuestCard:
	var card: QuestCard = quest_card_scene.instantiate()
	add_child(card)		# add so nodes are ready
	card.setup(quest)	# add data
	card.accepted.connect(_on_quest_accepted)
	card.closed.connect(_on_quest_closed)
	card.party_changed.connect(_on_party_changed)
	return card

func _any_quest_open() -> bool:
	for card in get_children():
		if card is QuestCard and card.is_open:
			return true
	return false

# placeholder system for quests fix later
func _get_quests() -> Array:
	return [
		{"title": "Slay the Goober", "slots": 3},
		{"title": "Escort the Merchant to Town", "slots": 2},
		{"title": "Clear the Cave Bats", "slots": 1},
		{"title": "Scout the Demon King's Border", "slots": 4},
		{"title": "Find the Lost Cat", "slots": 1},
	]

# called when play accepts quest
func _on_quest_accepted(quest) -> void:
	get_tree().call_group("roster", "open")
	print("Accepted: ", quest.get("title"))

func _on_quest_closed(quest) -> void:
	if not _any_quest_open():
		get_tree().call_group("roster", "close")
	print("Closed: ", quest.get("title"))

# function to get the characters on quest
func _on_party_changed(quest, party: Array) -> void:
	var names := party.map(func(c): return CharacterButton.get_display_name(c))
	print(quest.get("title"), " party: ", names)
