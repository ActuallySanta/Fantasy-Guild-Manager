## Gear confirmation: asked before gear comes off a hero, from the Pack.
##   Take off - "Take the Drakebone Blade off Gwen?" with the stat it drops
##              ("Power 40 → 18"): Keep it on / Take off
##   Swap     - for a hero whose gear slots are full: the new item, a pick of
##              which worn item comes off (one gear_row each), what that does to
##              their stats, and Cancel / Swap
## It belongs to tab_pack.gd, which opens it and acts on its signals; tapping
## the dim behind it cancels. Drawn over the whole screen (top_level).
## Scene: MobileHall/Scenes/Overlays/overlay_gear_confirm.tscn
extends Control


const GearRowScene := preload("uid://5qr0450k1huj")  # MobileHall/Scenes/Rows/gear_row.tscn

signal take_off_confirmed(item: StandardItem)
signal swap_confirmed(item_on: StandardItem, item_off: StandardItem, character: GuildCharacter)
signal closed

# ---- TEXT
const TITLE_TAKE_OFF := "Take the %s off %s?"
const TITLE_SWAP := "Swap %s's gear?"
const ON_LINE := "The %s goes on (%s)."
const CHOICE_HEADING := "Which comes off?"
const NOTE_TAKE_OFF := "It goes back in the pack, and %s gets a free gear slot."
const NOTE_SWAP := "The %s goes back in the pack."
const BUTTON_PICK := "Pick"
const BUTTON_KEEP := "Keep it on"
const BUTTON_TAKE_OFF := "Take off"
const BUTTON_CANCEL := "Cancel"
const BUTTON_SWAP := "Swap"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _portrait: Control = %Portrait
@onready var _title: Label = %Title
@onready var _on_line: Label = %OnLine
@onready var _choice_heading: Label = %ChoiceHeading
@onready var _choices: VBoxContainer = %Choices
@onready var _changes: RichTextLabel = %Changes
@onready var _note: Label = %Note
@onready var _cancel_button: Button = %CancelButton
@onready var _confirm_button: Button = %ConfirmButton

## What's being asked: {} while closed, else
## {"kind": "take_off", "item": StandardItem} or
## {"kind": "swap", "item_on": StandardItem, "character": GuildCharacter, "item_off": StandardItem}.
var _request := {}


func _ready() -> void:
	_choice_heading.text = CHOICE_HEADING
	_cancel_button.pressed.connect(func(): closed.emit())
	_confirm_button.pressed.connect(_on_confirm)
	_dim.gui_input.connect(_on_dim_input)


## Ask before taking a worn item off its wearer.
func open_take_off(item: StandardItem) -> void:
	if item.curr_user == null:
		return
	_request = {"kind": "take_off", "item": item}
	_show()


## Ask which worn item comes off so item_on can go on character (slots full).
func open_swap(item_on: StandardItem, character: GuildCharacter) -> void:
	if character.equipped_items.is_empty():
		return
	_request = {"kind": "swap", "item_on": item_on, "character": character, "item_off": character.equipped_items[0]}
	_show()


func close() -> void:
	_request = {}
	visible = false


func is_open() -> bool:
	return not _request.is_empty()


func _show() -> void:
	visible = true
	refresh()
	HallFx.fade_in(self, 0.0, 0.15)


## Redraw for the current request; closes itself if the gear moved meanwhile.
func refresh() -> void:
	if _request.is_empty():
		return
	if _request.kind == "take_off":
		_show_take_off()
	else:
		_show_swap()


func _show_take_off() -> void:
	var item: StandardItem = _request.item
	var wearer: GuildCharacter = item.curr_user
	if wearer == null:
		closed.emit()
		return
	var item_name: String = HallStyle.item_look(item).name
	_portrait.show_character(wearer)
	_title.text = TITLE_TAKE_OFF % [item_name, wearer.name]
	_on_line.visible = false
	_choice_heading.visible = false
	_choices.visible = false
	_set_changes(HallGear.preview(wearer, null, item))
	_note.text = NOTE_TAKE_OFF % wearer.name
	_cancel_button.text = BUTTON_KEEP
	_confirm_button.text = BUTTON_TAKE_OFF
	HallStyle.style_button(_confirm_button, "paper")
	HallStyle.set_font_color(_confirm_button, HallStyle.RED)


func _show_swap() -> void:
	var character: GuildCharacter = _request.character
	var item_on: StandardItem = _request.item_on
	# the item picked to come off must still be on them
	if not character.equipped_items.has(_request.item_off):
		if character.equipped_items.is_empty():
			closed.emit()
			return
		_request.item_off = character.equipped_items[0]
	var item_off: StandardItem = _request.item_off
	var look_on := HallStyle.item_look(item_on)
	_portrait.show_character(character)
	_title.text = TITLE_SWAP % character.name
	_on_line.visible = true
	_on_line.text = ON_LINE % [look_on.name, look_on.effect.get_slice(" · ", 0)]
	_choice_heading.visible = true
	_choices.visible = true
	HallStyle.clear_children(_choices)
	for worn in character.equipped_items:
		var row: Control = HallStyle.add_row(_choices, GearRowScene)
		var is_chosen: bool = worn == item_off
		row.setup(HallStyle.item_look(worn), "" if is_chosen else BUTTON_PICK, "paper", _pick_off.bind(worn), is_chosen)
	_set_changes(HallGear.preview(character, item_on, item_off))
	_note.text = NOTE_SWAP % HallStyle.item_look(item_off).name
	_cancel_button.text = BUTTON_CANCEL
	_confirm_button.text = BUTTON_SWAP
	HallStyle.style_button(_confirm_button, "gold")
	_confirm_button.remove_theme_color_override("font_color")


func _set_changes(changes: Array[Dictionary]) -> void:
	_changes.visible = not changes.is_empty()
	_changes.text = HallGear.preview_text(changes)


func _pick_off(item: StandardItem) -> void:
	_request.item_off = item
	refresh()


func _on_confirm() -> void:
	if _request.is_empty():
		return
	if _request.kind == "take_off":
		take_off_confirmed.emit(_request.item)
	else:
		swap_confirmed.emit(_request.item_on, _request.item_off, _request.character)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		closed.emit()
