## Equip picker: the sheet that slides up from the Pack's "Equip on…" button.
##   Head      - the item's seal, name and what it does
##   Can wear  - one equip_pick_row per living hero of the item's role, free
##               slots first: Equip (a free slot) or Swap… (slots full: the
##               Pack then asks which item comes off, overlay_gear_confirm.gd)
##   Wrong role - the other heroes named, so it's clear why they're missing
##   Cancel
## It belongs to tab_pack.gd, which opens it and acts on its signals; tapping
## the dim behind it closes it too. Drawn over the whole screen (top_level).
## Scene: MobileHall/Scenes/Overlays/overlay_equip_picker.tscn
extends Control


const PickRowScene := preload("uid://tlc3k0theskd")  # MobileHall/Scenes/Rows/equip_pick_row.tscn

signal equip_chosen(character: GuildCharacter)
signal swap_chosen(character: GuildCharacter)
signal closed

# ---- TEXT
const TITLE := "Equip the %s"
const CAN_WEAR := "Can wear it"
const NONE_CAN_WEAR := "No living %s on the roster to wear it."
const WRONG_ROLE := "Wrong role: %s"
const BUTTON_EQUIP := "Equip"
const BUTTON_SWAP := "Swap…"
const BUTTON_CANCEL := "Cancel"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _tag: PanelContainer = %Tag
@onready var _tag_text: Label = %TagText
@onready var _title: Label = %Title
@onready var _effect: Label = %Effect
@onready var _can_wear: Label = %CanWear
@onready var _fits: VBoxContainer = %Fits
@onready var _none_note: Label = %NoneNote
@onready var _wrong_role: Label = %WrongRole
@onready var _cancel_button: Button = %CancelButton

## The item being equipped (null while closed).
var _item: StandardItem


func _ready() -> void:
	_can_wear.text = CAN_WEAR
	_cancel_button.text = BUTTON_CANCEL
	_cancel_button.pressed.connect(func(): closed.emit())
	_dim.gui_input.connect(_on_dim_input)


## Show the picker for an owned item.
func open(item: StandardItem) -> void:
	_item = item
	visible = true
	refresh()
	HallFx.fade_in(self, 0.0, 0.15)


func close() -> void:
	_item = null
	visible = false


## Rebuild for the current item (the roster or gear may have changed).
func refresh() -> void:
	if _item == null:
		return
	var look := HallStyle.item_look(_item)
	HallStyle.style_tag(_tag, _tag_text, look.tag, look.color)
	_title.text = TITLE % look.name
	_effect.text = look.effect

	HallStyle.clear_children(_fits)
	var heroes := HallGear.heroes_for(_item)
	for character in heroes:
		var changes := HallGear.preview(character, _item, null)
		var change: Dictionary = changes[0] if not changes.is_empty() else {}
		var row: Control = HallStyle.add_row(_fits, PickRowScene)
		if HallGear.has_free_slot(character):
			row.setup(character, change, BUTTON_EQUIP, "gold", func(): equip_chosen.emit(character))
		else:
			row.setup(character, change, BUTTON_SWAP, "paper", func(): swap_chosen.emit(character))
	_none_note.visible = heroes.is_empty()
	_none_note.text = NONE_CAN_WEAR % HallStyle.item_role_name(_item)

	var others := HallGear.heroes_wrong_role(_item)
	_wrong_role.visible = not others.is_empty()
	_wrong_role.text = WRONG_ROLE % HallStyle.join_names(others, ", ")


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		closed.emit()
