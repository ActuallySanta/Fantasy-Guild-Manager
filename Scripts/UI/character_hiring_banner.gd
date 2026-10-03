extends MarginContainer

var loaded_character: GuildCharacter

@onready var character_icon: TextureRect = $"HBoxContainer/MarginContainer2/Character Icon"
@onready var name_label: Label = $"HBoxContainer/MarginContainer/Name Label"
@onready var hometown_label: Label = $"HBoxContainer/MarginContainer/Stats Container/Hometown Label"
@onready var defense_label: Label = $"HBoxContainer/MarginContainer/Stats Container/Defense Label"
@onready var sleaziness_label: Label = $"HBoxContainer/MarginContainer/Stats Container/Sleaziness Label"
@onready var pluck_label: Label = $"HBoxContainer/MarginContainer/Stats Container/Pluck Label"
@onready var strength_label: Label = $"HBoxContainer/MarginContainer/Stats Container/Strength Label"
@onready var wisdom_label: Label = $"HBoxContainer/MarginContainer/Stats Container/Wisdom Label"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set all the text based off the character
	name_label.text = loaded_character.title

	strength_label.text = "Strength: " + str(loaded_character.stats[GuildCharacter.StatType.STRENGTH])
	defense_label.text = "Defense: " + str(loaded_character.stats[GuildCharacter.StatType.DEFENSE])
	wisdom_label.text = "Wisdom: " + str(loaded_character.stats[GuildCharacter.StatType.WISDOM])
	sleaziness_label.text = "Sleaziness: " + str(loaded_character.stats[GuildCharacter.StatType.SLEAZINESS])
	pluck_label.text = "Pluck: " + str(loaded_character.pluck)
	character_icon.texture = ExternalContentContainer.get_character_icon(loaded_character.role)

pass # Replace with function body.

##Add the character to the guild if there is space
func _on_clickable_area_pressed() -> void:
	var success: bool = CharacterContainer.add_character_to_guild(loaded_character)
	if (success):
		queue_free()
