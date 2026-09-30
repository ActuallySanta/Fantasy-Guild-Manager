extends VBoxContainer

@export var placeholder_count: int = 15
@export var card_height: int = 140

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in placeholder_count:
		add_child(_make_card(i))

# Creates a simple quest card to test content section
func _make_card(index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, card_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.25, 0.15)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", style)
	
	var label := Label.new()
	label.text = "Quest #%d - Kill a Goober" % (index + 1)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(label)
	
	return card
