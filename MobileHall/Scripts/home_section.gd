## One building's card on the Upgrades tab's Tonight half: the Training Yard
## (heroes in a slot, plus "+ Add a hero" to pick more) or the Hospital
## (heroes in a bed, hurt heroes, fallen heroes). Rows are home_row.tscn.
## Scene: MobileHall/Scenes/Rows/home_section.tscn
extends PanelContainer

const HomeRowScene := preload("uid://br273xs77xnj3")  # MobileHall/Scenes/Rows/home_row.tscn
const HeadingScene := preload("uid://bve0dglxrk3x4")  # MobileHall/Scenes/Rows/home_heading.tscn

# ---- TEXT
const TEXT_LEVEL := "Lv %d"
const TEXT_TRAINING_SUMMARY := "%d of %d %s · +%d a night"
const TEXT_HOSPITAL_WAITING := "%d hurt, not in a bed"
const TEXT_HOSPITAL_IN_BED := "%d in a bed"
const TEXT_HOSPITAL_CALM := "Nobody is hurt"
const HEADING_PICK := "PICK A HERO"
const HEADING_CANT_TRAIN := "CAN'T TRAIN"
const HEADING_IN_BED := "IN A BED"
const HEADING_NEEDS_CARE := "NEEDS CARE"
const HEADING_FALLEN := "FALLEN"
const TEXT_EMPTY_TRAINING := "Nobody is training. Heroes in a slot get stronger each night."
const TEXT_EMPTY_HOSPITAL := "Hurt heroes show up here after a quest."
const BUTTON_ADD := "+ Add a hero"
const BUTTON_DONE_PICKING := "Done picking"
const BUTTON_FULL := "All slots are full"

# ---- NODES
@onready var _tag_box: PanelContainer = %TagBox
@onready var _tag: Label = %Tag
@onready var _name: Label = %Name
@onready var _level: Label = %Level
@onready var _summary: Label = %Summary
@onready var _list: VBoxContainer = %List
@onready var _empty_label: Label = %Empty
@onready var _add_button: Button = %AddButton

var hall: HallMain
## GuildUpgrades.Building.TRAINING_YARD or HOSPITAL.
var building := 0


func setup(main: HallMain, section_building: int) -> void:
	hall = main
	building = section_building
	var tag_color: Color = GuildUpgrades.get_building_color(building).darkened(0.25)
	HallStyle.style_tag(_tag_box, _tag, HallStyle.BUILDING_TAGS.get(building, "?"), tag_color)
	_name.text = GuildUpgrades.get_building_name(building)
	_add_button.pressed.connect(hall.toggle_training_picker)
	HallStyle.style_panel(self, HallStyle.CARD_BG, HallStyle.BORDER, 2, 16)


func refresh() -> void:
	_level.text = TEXT_LEVEL % GuildUpgrades.get_level(building)
	HallStyle.clear_children(_list)
	if building == GuildUpgrades.Building.TRAINING_YARD:
		_show_training()
	else:
		_show_hospital()


func _add_heading(text: String) -> void:
	HallStyle.add_row(_list, HeadingScene).text = text


func _add_row() -> Node:
	return HallStyle.add_row(_list, HomeRowScene)

# ---- Training Yard


func _show_training() -> void:
	var slots := GuildUpgrades.get_training_slots()
	var roster: Array = hall.roster()
	var trainees := roster.filter(func(character): return GuildUpgrades.is_training(character))
	_summary.text = TEXT_TRAINING_SUMMARY % [trainees.size(), slots, HallStyle.pick_plural(slots, "slot", "slots"), GuildUpgrades.get_training_gain()]
	HallStyle.set_font_color(_summary, HallStyle.BLUE_TEXT if GuildUpgrades.has_free_training_slot() else HallStyle.TEXT_SOFT)

	for character in trainees:
		_add_row().show_training_slot(hall, character)

	var is_picking := hall.training_picker_open and GuildUpgrades.has_free_training_slot()
	if is_picking:
		var can_train := roster.filter(func(character):
			return not GuildUpgrades.is_training(character) and GuildUpgrades.can_train(character))
		var cant_train := roster.filter(func(character):
			return not GuildUpgrades.can_train(character) and not HallStyle.is_dead(character))
		_add_heading(HEADING_PICK)
		for character in can_train:
			_add_row().show_can_train(hall, character)
		if not cant_train.is_empty():
			_add_heading(HEADING_CANT_TRAIN)
			for character in cant_train:
				_add_row().show_cant_train(hall, character)

	_empty_label.text = TEXT_EMPTY_TRAINING
	_empty_label.visible = trainees.is_empty() and not is_picking

	_add_button.visible = not roster.is_empty()
	if not GuildUpgrades.has_free_training_slot():
		_add_button.text = BUTTON_FULL
		_add_button.disabled = true
		HallStyle.style_button(_add_button, "paper", 24)
	else:
		_add_button.text = BUTTON_DONE_PICKING if is_picking else BUTTON_ADD
		_add_button.disabled = false
		HallStyle.style_button(_add_button, "paper" if is_picking else "blue", 24)

# ---- Hospital


func _show_hospital() -> void:
	_add_button.visible = false
	var roster: Array = hall.roster()
	var patients := roster.filter(func(character): return GuildUpgrades.is_patient(character))
	var waiting := roster.filter(func(character):
		return GuildUpgrades.needs_care(character) and not GuildUpgrades.is_patient(character))
	var fallen := roster.filter(func(character): return HallStyle.is_dead(character))

	if not waiting.is_empty():
		_summary.text = TEXT_HOSPITAL_WAITING % waiting.size()
		HallStyle.set_font_color(_summary, HallStyle.RED)
	elif not patients.is_empty():
		_summary.text = TEXT_HOSPITAL_IN_BED % patients.size()
		HallStyle.set_font_color(_summary, HallStyle.TEXT_SOFT)
	else:
		_summary.text = TEXT_HOSPITAL_CALM
		HallStyle.set_font_color(_summary, HallStyle.TEXT_SOFT)

	if not patients.is_empty():
		_add_heading(HEADING_IN_BED)
		for character in patients:
			_add_row().show_patient(hall, character)
	if not waiting.is_empty():
		_add_heading(HEADING_NEEDS_CARE)
		for character in waiting:
			_add_row().show_needs_care(hall, character)
	if not fallen.is_empty():
		_add_heading(HEADING_FALLEN)
		for character in fallen:
			_add_row().show_fallen(hall, character)
	_empty_label.text = TEXT_EMPTY_HOSPITAL
	_empty_label.visible = patients.is_empty() and waiting.is_empty() and fallen.is_empty()
