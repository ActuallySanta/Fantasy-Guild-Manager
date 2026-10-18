## One recruit in the Guild tab's For Hire list: who they are, all five stats,
## the first line of their backstory, and a big Hire button.
## Scene: MobileHall/Scenes/Rows/hire_card.tscn
extends PanelContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_ROLE := "the %s · stat total %d"
const TEXT_HIRE := "Hire (free)"
const TEXT_FULL := "No beds"

# ---- NODES
@onready var _portrait = %Portrait
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _stats = %Stats
@onready var _blurb: Label = %Blurb
@onready var _details_button: Button = %DetailsButton
@onready var _hire_button: Button = %HireButton


func setup(main, c: GuildCharacter) -> void:
	_details_button.pressed.connect(main.open_character.bind(c))
	_hire_button.pressed.connect(main.hire.bind(c))
	_portrait.show_character(c)
	_name.text = c.name
	var total := 0
	for i in 4:
		total += S.stat_value(c, i)
	_role.text = TEXT_ROLE % [S.role_name(c), total]
	_stats.show_stats(c)
	_blurb.text = S.backstory(c).get_slice("\n", 0)
	var full: bool = main.roster_full()
	_hire_button.text = TEXT_FULL if full else TEXT_HIRE
	_hire_button.disabled = full
	S.style_button(_details_button, "paper", 24)
	S.style_button(_hire_button, "green", 28)
