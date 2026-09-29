extends Control

class_name CharacterUICard

var loaded_character: GuildCharacter

#Get a reference to every UI element
@onready var character_description_label: Label = $"Stat Block/HBoxContainer/Character Description Label"
@onready var character_name_label: Label = $"Name Background/CenterContainer/Character Name Label"
@onready var character_icon: TextureRect = $"Character Icon"

@onready var defense_label: Label = $"Stat Block/HBoxContainer/VBoxContainer/Defense Label"
@onready var strength_label: Label = $"Stat Block/HBoxContainer/VBoxContainer/Strength Label"
@onready var wisdom_label: Label = $"Stat Block/HBoxContainer/VBoxContainer/Wisdom Label"
@onready var sleaziness_label: Label = $"Stat Block/HBoxContainer/VBoxContainer/Sleaziness Label"
@onready var pluck_label: Label = $"Stat Block/HBoxContainer/VBoxContainer/Pluck Label"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Generate a random character
	loaded_character = GuildCharacter.new()

	# Set all the text based off the character
	character_name_label.text = loaded_character.title
	strength_label.text = "Strength: " + str(loaded_character.stats[GuildCharacter.StatType.STRENGTH])
	defense_label.text = "Defense: " + str(loaded_character.stats[GuildCharacter.StatType.DEFENSE])
	wisdom_label.text = "Wisdom: " + str(loaded_character.stats[GuildCharacter.StatType.WISDOM])
	sleaziness_label.text = "Sleaziness: " + str(loaded_character.stats[GuildCharacter.StatType.SLEAZINESS])
	pluck_label.text = "Pluck: " + str(loaded_character.pluck)
	pass # Replace with function body.
