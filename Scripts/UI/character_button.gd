# single character thats in roster, player can either
# drag or click to assign them to a quest
class_name CharacterButton
extends Button

# variable to remember selected character
# make sure its shared by every character button with static
static var selected: CharacterButton = null

# character data
var character

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)

# called by roster.gd after button is added to scene
# fills in button with character data
func setup(data) -> void:
	character = data
	text = get_display_name(character)
	icon = get_icon(character)

# functions to read character info
static func get_display_name(c) -> String:
	return str(c.get("title"))

static func get_icon(c) -> Texture2D:
	return ExternalContentContainer.get_character_icon(c.role)

# Runs when player taps this character
func _on_pressed() -> void:
	if selected == self:
		clear_selection()
	else:
		_select(self)

# highlights button and remembers it as a selected one
static func _select(button: CharacterButton) -> void:
	clear_selection()
	selected = button
	selected.modulate = Color(1.0, 0.85, 0.4)

# function to remove the highlights and clear selection
static func clear_selection() -> void:
	if selected and is_instance_valid(selected):
		selected.modulate = Color.WHITE
	selected = null

# function calls when a player starts to drag this button
func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := TextureRect.new()
	preview.texture = icon
	preview.custom_minimum_size = Vector2(80, 80)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"type": "character", "character": character}
