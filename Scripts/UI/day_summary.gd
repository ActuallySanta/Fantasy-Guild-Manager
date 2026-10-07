# popup listing every quest that went out during a day and
# whether it succeeded
class_name DaySummary
extends Control

@export var entry_scene: PackedScene

# unique label nodes
@onready var _entry_list: VBoxContainer = %EntryList
@onready var _empty_label: Label = %EmptyLabel
@onready var _new_day_button: BaseButton = %NewDayButton
 
 
func _ready() -> void:
	visible = false  # hidden until the day ends
	_new_day_button.pressed.connect(_on_new_day_pressed)
 
# Fills the list with one entry per quest result, then shows the popup.
func show_results(results: Array) -> void:
	if entry_scene == null:
		push_error("drag summary_entry.tscn into Entry Scene in the Inspector")
		return
 
	# Clear out entries from any previous day.
	for child in _entry_list.get_children():
		_entry_list.remove_child(child)
		child.queue_free()
 
	for result in results:
		var entry: SummaryEntry = entry_scene.instantiate()
		_entry_list.add_child(entry) # add first
		entry.setup(result)          # then fill in the data
 
	# message if no quests were sent out.
	_empty_label.visible = results.is_empty()
 
	show()

func _on_new_day_pressed() -> void:
	hide()
	GameState.start_new_day()
