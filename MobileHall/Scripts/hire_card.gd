## One applicant on the Guild tab, written as a letter of introduction: who they
## are, all five stats in boxes, the first line of their backstory, Details and
## a wax-sealed Hire button with their price.
## Scene: MobileHall/Scenes/Rows/hire_card.tscn
extends PanelContainer


## Letter numbers start here so the first applicants aren't "No. I".
const FIRST_LETTER_NUMBER := 12

# ---- TEXT
const TEXT_NUMBER := "No. %s"
## Hiring costs the recruit's price (GuildCharacter.cost), in gold; it's free
## on the first days (cost 0).
const TEXT_HIRE := "Hire · %dg"
const TEXT_HIRE_FREE := "Hire · free"
const TEXT_NO_BEDS := "No beds left"

# ---- NODES
@onready var _number: Label = %Number
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _stat_columns: HBoxContainer = %Stats
@onready var _total: Label = %Total
@onready var _drop_cap: Label = %DropCap
@onready var _blurb: Label = %Blurb
@onready var _details_button: Button = %DetailsButton
@onready var _hire_button: Button = %HireButton


## The scene has one stat column; copy it for the other four.
func _ready() -> void:
	var template := _stat_columns.get_child(0)
	for copy_index in HallStyle.STAT_COUNT - 1:
		_stat_columns.add_child(template.duplicate())


## letter_index = place in today's applicants (for the letter number).
func setup(hall: HallMain, recruit: GuildCharacter, letter_index: int = 0) -> void:
	_details_button.pressed.connect(hall.open_character.bind(recruit))
	_hire_button.pressed.connect(_on_hire_pressed.bind(hall, recruit))

	# who they are
	_number.text = TEXT_NUMBER % HallStyle.roman_numeral(FIRST_LETTER_NUMBER + GameState.day * 3 + letter_index)
	_portrait.show_character(recruit)
	_name.text = recruit.name
	_role.text = HallStyle.role_name(recruit)
	for stat_index in HallStyle.STAT_COUNT:
		var column := _stat_columns.get_child(stat_index)
		column.get_node("Caps").text = HallStyle.STATS[stat_index].short
		column.get_node("Box/Value").text = str(HallStyle.stat_value(recruit, stat_index))
	_total.text = str(HallStyle.quest_stat_total(recruit))

	# first line of the backstory, with a red drop cap
	var story := HallStyle.clean_backstory(recruit).get_slice("\n", 0)
	_drop_cap.text = story.left(1)
	_blurb.text = story.substr(1)

	# Hire is disabled when every bed is taken
	var no_beds := hall.is_roster_full()
	if no_beds:
		_hire_button.text = TEXT_NO_BEDS
	elif recruit.cost > 0:
		_hire_button.text = TEXT_HIRE % recruit.cost
	else:
		_hire_button.text = TEXT_HIRE_FREE
	_hire_button.disabled = no_beds


## Hire, and if they joined, this letter flies off to the roster.
func _on_hire_pressed(hall: HallMain, recruit: GuildCharacter) -> void:
	if hall.hire(recruit):
		hall.send_hired_letter(self)
