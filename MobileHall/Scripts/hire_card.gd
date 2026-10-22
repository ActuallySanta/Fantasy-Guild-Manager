## One applicant on the Guild tab, written as a letter of introduction: who they
## are, all five stats in boxes, the first line of their backstory, Details and
## a wax-sealed Hire button.
## Scene: MobileHall/Scenes/Rows/hire_card.tscn
extends PanelContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

## Letter numbers start here so the first applicants aren't "No. I".
const FIRST_LETTER := 12

# ---- TEXT
const TEXT_NUMBER := "No. %s"
const TEXT_HIRE := "Hire · free"
const TEXT_FULL := "No beds left"

# ---- NODES
@onready var _number: Label = %Number
@onready var _portrait = %Portrait
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _stats: HBoxContainer = %Stats
@onready var _total: Label = %Total
@onready var _drop_cap: Label = %DropCap
@onready var _blurb: Label = %Blurb
@onready var _details_button: Button = %DetailsButton
@onready var _hire_button: Button = %HireButton


## The scene has one stat column; copy it for the other four.
func _ready() -> void:
	var template := _stats.get_child(0)
	for i in 4:
		_stats.add_child(template.duplicate())


## index = place in today's applicants (for the letter number).
func setup(main, c: GuildCharacter, index: int = 0) -> void:
	_details_button.pressed.connect(main.open_character.bind(c))
	_hire_button.pressed.connect(main.hire.bind(c))
	_number.text = TEXT_NUMBER % S.roman(FIRST_LETTER + GameState.day * 3 + index)
	_portrait.show_character(c)
	_name.text = c.name
	_role.text = S.role_name(c)
	for i in 5:
		var col := _stats.get_child(i)
		col.get_node("Caps").text = S.STATS[i].short
		col.get_node("Box/Value").text = str(S.stat_value(c, i))
	_total.text = str(S.stat_total(c))
	var story := S.backstory(c).get_slice("\n", 0)
	_drop_cap.text = story.left(1)
	_blurb.text = story.substr(1)
	var full: bool = main.roster_full()
	_hire_button.text = TEXT_FULL if full else TEXT_HIRE
	_hire_button.disabled = full
