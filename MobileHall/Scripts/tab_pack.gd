## Pack sub-tab of the Items tab ("Pack grid", picked by the team from the
## inventory mockups): every item the guild owns, and who wears what.
##   Head     - title, the "Hide equipped items" box and a count line
##   Filters  - All / Knight / Priest / Pathfinder / Mage
##   Grid     - one pack_tile per item, grouped by role; a worn one carries its
##              hero's portrait and an "ON GWEN" ribbon
##   Item bar - the picked item: what it does, who wears it, and Take off or
##              Equip on… (sits where the action bar normally is; hall_main
##              hides the action bar on this tab)
## Equip on… opens the hero picker (overlay_equip_picker.gd); Take off, and
## swapping onto a hero whose slots are full, ask first (overlay_gear_confirm.gd).
## Both are children of this scene drawn over the whole screen. The picked
## item, the filters and which overlay is open are view state only, kept here;
## gear only changes through hall (equip_item / unequip_item / swap_gear).
## Scene: MobileHall/Scenes/Tabs/tab_pack.tscn
extends VBoxContainer


const PackTileScene := preload("uid://g3ntvsh05abd")  # MobileHall/Scenes/Rows/pack_tile.tscn

## Filter value for "every role" (otherwise a GuildCharacter.CharacterRole).
const FILTER_ALL := -1
## Role order on the grid and the filter row.
const ROLE_ORDER := [
	GuildCharacter.CharacterRole.KNIGHT,
	GuildCharacter.CharacterRole.PRIEST,
	GuildCharacter.CharacterRole.PATHFINDER,
	GuildCharacter.CharacterRole.MAGE,
]
## Filter button height and label size (design px).
const FILTER_HEIGHT := 60
const FILTER_FONT_SIZE := 24

# ---- TEXT
const TITLE := "The Guild Pack"
const HIDE_WORN := "Hide equipped"
const COUNT_LINE := "%s · %d worn · %d spare"
const EMPTY_PACK := "The pack is empty. Buy gear in the Shop, or win it on quests."
const ALL_WORN := "Every item here is being worn. Untick \"Hide equipped\" to see them."
const NONE_FOR_ROLE := "No %s gear in the pack."
const FILTER_ALL_TEXT := "All"
const NOTHING_PICKED := "Pick an item"
const WORN_BY := "Worn by %s"
const SPARE_NOTE := "In the pack · ready to equip"
const BUTTON_TAKE_OFF := "Take off"
const BUTTON_EQUIP := "Equip on…"

# ---- NODES
@onready var _scroll: ScrollContainer = %Scroll
@onready var _title: Label = %Title
@onready var _hide_worn_toggle: CheckButton = %HideWornToggle
@onready var _count_line: Label = %CountLine
@onready var _filters: HBoxContainer = %Filters
@onready var _grid: GridContainer = %Grid
@onready var _empty_note: Label = %EmptyNote
@onready var _wearer_portrait: Control = %WearerPortrait
@onready var _item_name: Label = %ItemName
@onready var _item_effect: Label = %ItemEffect
@onready var _item_status: Label = %ItemStatus
@onready var _action_button: Button = %ActionButton
@onready var _picker: Control = %EquipPicker
@onready var _confirm: Control = %GearConfirm

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The picked item (null = none). Kept by reference: owned_items can reorder.
var _selected: StandardItem
## FILTER_ALL or a CharacterRole.
var _filter := FILTER_ALL
## Hide items someone is wearing.
var _hide_worn := false
## True right after the player taps a tile, so that tile pops on this refresh.
var _just_picked := false


func setup(main: HallMain) -> void:
	hall = main
	_title.text = TITLE
	_hide_worn_toggle.text = HIDE_WORN
	_hide_worn_toggle.toggled.connect(_on_hide_worn_toggled)
	# the filter buttons are authored in the scene: All, then one per role in ROLE_ORDER
	var filter_values := [FILTER_ALL] + ROLE_ORDER
	for index in _filters.get_child_count():
		var button: Button = _filters.get_child(index)
		var value: int = filter_values[index]
		button.text = FILTER_ALL_TEXT if value == FILTER_ALL else _role_word(value)
		button.pressed.connect(_set_filter.bind(value))
	_action_button.pressed.connect(_on_action_pressed)
	_picker.equip_chosen.connect(_on_equip_chosen)
	_picker.swap_chosen.connect(_on_swap_chosen)
	_picker.closed.connect(_picker.close)
	_confirm.take_off_confirmed.connect(_on_take_off_confirmed)
	_confirm.swap_confirmed.connect(_on_swap_confirmed)
	_confirm.closed.connect(_confirm.close)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	if _selected != null and not ItemContainer.owned_items.has(_selected):
		_selected = null
	_hide_worn_toggle.set_pressed_no_signal(_hide_worn)
	_show_filters()
	_show_grid()
	_show_item_bar()
	_picker.refresh()
	_confirm.refresh()


func _show_filters() -> void:
	var filter_values := [FILTER_ALL] + ROLE_ORDER
	for index in _filters.get_child_count():
		var button: Button = _filters.get_child(index)
		var is_on: bool = filter_values[index] == _filter
		HallStyle.style_button(button, "wood" if is_on else "paper", FILTER_FONT_SIZE)
		button.custom_minimum_size.y = HallFontScale.px(FILTER_HEIGHT)


func _show_grid() -> void:
	var owned := ItemContainer.owned_items
	var worn_count := owned.size() - ItemShop.unworn_count()
	_count_line.text = COUNT_LINE % [HallStyle.count_text(owned.size(), "item", "items"), worn_count, owned.size() - worn_count]

	HallStyle.clear_children(_grid)
	var shown := _shown_items()
	for item in shown:
		var tile: Control = HallStyle.add_row(_grid, PackTileScene)
		tile.setup(item, item == _selected, _pick.bind(item))
		if hall.pending_fx.get("gear_in") == item:
			HallFx.stamp_in(tile, 1.2)
		elif _just_picked and item == _selected:
			HallFx.pop(tile, 1.08)
	_just_picked = false

	_empty_note.visible = shown.is_empty()
	if owned.is_empty():
		_empty_note.text = EMPTY_PACK
	elif _filter != FILTER_ALL and not _has_role(owned, _filter):
		_empty_note.text = NONE_FOR_ROLE % _role_word(_filter)
	else:
		_empty_note.text = ALL_WORN


## Owned items that pass the filters, grouped by role (ROLE_ORDER), in the
## order they were got within a role.
func _shown_items() -> Array[StandardItem]:
	var shown: Array[StandardItem] = []
	for role in ROLE_ORDER:
		if _filter != FILTER_ALL and role != _filter:
			continue
		for item in ItemContainer.owned_items:
			if item.role != role:
				continue
			if _hide_worn and item.curr_user != null:
				continue
			shown.append(item)
	return shown


## Name, what it does, who wears it, and the button for the picked item.
func _show_item_bar() -> void:
	var item := _selected
	_item_effect.visible = item != null
	_item_status.visible = item != null
	_action_button.visible = item != null
	_wearer_portrait.visible = item != null and item.curr_user != null
	if item == null:
		_item_name.text = NOTHING_PICKED
		return
	var look := HallStyle.item_look(item)
	_item_name.text = look.name
	_item_effect.text = look.effect
	var wearer: GuildCharacter = item.curr_user
	if wearer != null:
		_wearer_portrait.show_character(wearer)
		_item_status.text = WORN_BY % wearer.name
		HallStyle.set_font_color(_item_status, HallStyle.NAVY)
		_action_button.text = BUTTON_TAKE_OFF
		HallStyle.style_button(_action_button, "paper")
		HallStyle.set_font_color(_action_button, HallStyle.RED)
	else:
		_item_status.text = SPARE_NOTE
		HallStyle.set_font_color(_item_status, HallStyle.GREEN_TEXT)
		_action_button.text = BUTTON_EQUIP
		HallStyle.style_button(_action_button, "gold")
		_action_button.remove_theme_color_override("font_color")


func _pick(item: StandardItem) -> void:
	_selected = item
	_just_picked = true
	refresh()


func _set_filter(value: int) -> void:
	_filter = value
	refresh()


func _on_hide_worn_toggled(is_on: bool) -> void:
	_hide_worn = is_on
	refresh()


func _on_action_pressed() -> void:
	if _selected == null:
		return
	if _selected.curr_user != null:
		_confirm.open_take_off(_selected)
	else:
		_picker.open(_selected)


func _on_equip_chosen(character: GuildCharacter) -> void:
	var item := _selected
	_picker.close()
	hall.equip_item(item, character)


func _on_swap_chosen(character: GuildCharacter) -> void:
	var item := _selected
	_picker.close()
	_confirm.open_swap(item, character)


func _on_take_off_confirmed(item: StandardItem) -> void:
	_confirm.close()
	hall.unequip_item(item)


func _on_swap_confirmed(item_on: StandardItem, item_off: StandardItem, character: GuildCharacter) -> void:
	_confirm.close()
	hall.swap_gear(item_on, item_off, character)


static func _role_word(role: int) -> String:
	return str(GuildCharacter.CharacterRole.find_key(role)).capitalize()


static func _has_role(items: Array[StandardItem], role: int) -> bool:
	for item in items:
		if item.role == role:
			return true
	return false
