extends Control

class_name CharacterUICard

var loaded_character: GuildCharacter

#Get a reference to every UI element

@onready var character_name_label: Label = $"VBoxContainer/Name Background/CenterContainer/Character Name Label"

@onready var character_icon: TextureRect = $"VBoxContainer/MarginContainer/Character Icon"

@onready var character_description_label: Label = $"VBoxContainer/Stat Block/MarginContainer/HBoxContainer/VBoxContainer2/Character Description Label"
@onready var character_injury_label: Label = $"VBoxContainer/Stat Block/MarginContainer/HBoxContainer/VBoxContainer2/Character Injury Label"


@onready var defense_label: Label = $"VBoxContainer/Stat Block/MarginContainer/HBoxContainer/VBoxContainer/Defense Label"
@onready var sleaziness_label: Label = $"VBoxContainer/Stat Block/MarginContainer/HBoxContainer/VBoxContainer/Sleaziness Label"
@onready var pluck_label: Label = $"VBoxContainer/Stat Block/MarginContainer/HBoxContainer/VBoxContainer/Pluck Label"
@onready var strength_label: Label = $"VBoxContainer/Stat Block/MarginContainer/HBoxContainer/VBoxContainer/Strength Label"
@onready var wisdom_label: Label = $"VBoxContainer/Stat Block/MarginContainer/HBoxContainer/VBoxContainer/Wisdom Label"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set all the text based off the character
	character_name_label.text = loaded_character.title

	strength_label.text = "Strength: " + str(loaded_character.stats[GuildCharacter.StatType.STRENGTH])
	defense_label.text = "Defense: " + str(loaded_character.stats[GuildCharacter.StatType.DEFENSE])
	wisdom_label.text = "Wisdom: " + str(loaded_character.stats[GuildCharacter.StatType.WISDOM])
	sleaziness_label.text = "Sleaziness: " + str(loaded_character.stats[GuildCharacter.StatType.SLEAZINESS])
	pluck_label.text = "Pluck: " + str(loaded_character.pluck)
	character_description_label.text = loaded_character.description
	character_injury_label.text = "Injury Level: " + str(GuildCharacter.InjuryLevel.find_key(loaded_character.injury_level))
	character_icon.texture = ExternalContentContainer.get_character_icon(loaded_character.role)
	pass # Replace with function body.


func _on_close_button_pressed() -> void:
	queue_free()
