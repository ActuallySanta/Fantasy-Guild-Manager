extends Control

@onready var character_total_display: Label = $"NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/Character Total Display"
@onready var character_banner_container: VBoxContainer = $"NinePatchRect/MarginContainer/VBoxContainer/ScrollContainer/Character Banner Container"

const CHARACTER_HIRING_BANNER = preload("uid://5kdaenkqw3iw")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_character_total()
	CharacterContainer.on_character_added.connect(_on_character_added)
	CharacterContainer.on_hireables_refreshed.connect(populate_hiring_page)
	populate_hiring_page()
	pass # Replace with function body.


##Updates the total text with the accurate amount of characters the guild has as well as the total characters that you can have in your guild at the moment
func update_character_total():
	character_total_display.text = "TOTAL: " + str(CharacterContainer.active_characters.size()) + " / " + str(CharacterContainer.max_characters)

# when someone is hired update the total 
# and remove them from the page
func _on_character_added() -> void:
	update_character_total()
	populate_hiring_page()

func _on_close_button_pressed() -> void:
	hide()


func populate_hiring_page():
	# clear old banners first so we never get duplicates
	for child in character_banner_container.get_children():
		character_banner_container.remove_child(child)
		child.queue_free()

	for character in CharacterContainer.hireable_characters:
		var char_banner := CHARACTER_HIRING_BANNER.instantiate()
		char_banner.loaded_character = character
		character_banner_container.add_child(char_banner)
	
	#Populate the page with the given amount of characters
	#for i in CharacterContainer.max_hireable_characters:
		#var char_banner := CHARACTER_HIRING_BANNER.instantiate()
		#char_banner.loaded_character = GuildCharacter.new()
		#character_banner_container.add_child(char_banner)
