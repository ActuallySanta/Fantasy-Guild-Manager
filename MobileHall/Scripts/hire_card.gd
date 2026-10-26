## One recruit in the Guild tab's For Hire list: who they are, all five stats,
## the first line of their backstory, and a big Hire button.
## Scene: MobileHall/Scenes/Rows/hire_card.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")

# ---- TEXT
const TEXT_ROLE := "the %s · stat total %d"
var TEXT_HIRE := "WHy you no chsnge"
const TEXT_NO_BEDS := "No beds"

# ---- NODES
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _stats = %Stats                  # stat_strip.gd
@onready var _blurb: Label = %Blurb
@onready var _details_button: Button = %DetailsButton
@onready var _hire_button: Button = %HireButton



func setup(hall: HallMain, recruit: GuildCharacter) -> void:
	_details_button.pressed.connect(hall.open_character.bind(recruit))
	_hire_button.pressed.connect(hall.hire.bind(recruit))
	
	TEXT_HIRE = str("Hire ($", recruit.cost, ")")
	# who they are
	_portrait.show_character(recruit)
	_name.text = recruit.name
	_role.text = TEXT_ROLE % [Style.role_name(recruit), _quest_stat_total(recruit)]
	_stats.show_stats(recruit)
	_blurb.text = Style.clean_backstory(recruit).get_slice("\n", 0)

	# buttons (Hire is disabled when every bed is taken)
	var no_beds := hall.is_roster_full()
	_hire_button.text = TEXT_NO_BEDS if no_beds else TEXT_HIRE
	_hire_button.disabled = no_beds
	Style.style_button(_details_button, "paper", 24)
	Style.style_button(_hire_button, "green", 28)


## Sum of the four stats quests use (Pluck left out), a quick "how good" number.
func _quest_stat_total(character: GuildCharacter) -> int:
	var total := 0
	for stat_index in Style.QUEST_STAT_COUNT:
		total += Style.stat_value(character, stat_index)
	return total
