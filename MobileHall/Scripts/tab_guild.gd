## Guild tab: two clearly separate halves, "Your Guild" (the roster) and
## "For Hire" (today's recruits), switched with the buttons at the top. The
## For Hire button shows how many recruits are waiting. A line under them
## shows beds used and links to the Barracks upgrade.
## Scene: MobileHall/Scenes/Tabs/tab_guild.tscn
extends VBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const MemberCardScene := preload("res://MobileHall/Scenes/Rows/member_card.tscn")
const HireCardScene := preload("res://MobileHall/Scenes/Rows/hire_card.tscn")

# ---- TEXT
# Section buttons
const SECTION_ROSTER := "Your Guild %d/%d"
const SECTION_HIRE := "For Hire"
# Beds line
const BEDS := "Beds: %d of %d used · Barracks level %d"
const BEDS_FULL := "All %d beds are taken. Upgrade the Barracks for more."
const BEDS_BUTTON := "Barracks"
# Lists
const EMPTY_ROSTER := "Nobody here yet. Hire someone from For Hire."
const EMPTY_HIRE := "No recruits left today. New faces arrive every morning."
const HIRE_NOTE := "Hiring is free. New recruits arrive every morning."
const LOW_STANDING := "Your guild is too unpopular, and has thus failed to attract new talent"

# ---- NODES
# Section buttons
@onready var _roster_section_button: Button = %SegRoster
@onready var _hire_section_button: Button = %SegHire
@onready var _hire_badge: Control = %HireBadge
@onready var _hire_badge_text: Label = %HireBadgeText
# Beds line
@onready var _beds_label: Label = %Beds
@onready var _barracks_button: Button = %BedsButton
# Lists
@onready var _scroll: ScrollContainer = %Scroll
@onready var _note: Label = %Note
@onready var _card_list: VBoxContainer = %List
@onready var _empty_label: Label = %Empty

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_roster_section_button.pressed.connect(func(): hall.show_guild_section(HallMain.GUILD_SECTION_ROSTER))
	_hire_section_button.pressed.connect(func(): hall.show_guild_section(HallMain.GUILD_SECTION_HIRE))
	_barracks_button.pressed.connect(func(): hall.open_tab("upgrades"))
	_barracks_button.text = BEDS_BUTTON
	Style.style_button(_barracks_button, "paper", 22)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	_show_section_buttons()
	_show_beds()
	Style.clear_children(_card_list)
	if _is_hire_section():
		_show_for_hire()
	else:
		_show_roster()


func _is_hire_section() -> bool:
	return hall.guild_section == HallMain.GUILD_SECTION_HIRE


# ---- top of the tab

## The open section's button is filled; For Hire gets a count badge while closed.
func _show_section_buttons() -> void:
	var on_hire := _is_hire_section()
	_roster_section_button.text = SECTION_ROSTER % [hall.roster().size(), CharacterContainer.max_characters]
	_hire_section_button.text = SECTION_HIRE
	Style.style_button(_roster_section_button, "paper" if on_hire else "wood", 26)
	Style.style_button(_hire_section_button, "blue" if on_hire else "paper", 26)

	var recruit_count := CharacterContainer.hireable_characters.size()
	_hire_badge.visible = not on_hire and recruit_count > 0 and not hall.is_roster_full()
	_hire_badge_text.text = str(recruit_count)


## "Beds: 3 of 5 used", or a red warning when they're all taken.
func _show_beds() -> void:
	var beds_used: int = hall.roster().size()
	var bed_count := CharacterContainer.max_characters
	var is_full := beds_used >= bed_count
	if is_full:
		_beds_label.text = BEDS_FULL % bed_count
	else:
		var barracks_level := GuildUpgrades.get_level(GuildUpgrades.Building.BARRACKS)
		_beds_label.text = BEDS % [beds_used, bed_count, barracks_level]
	Style.set_font_color(_beds_label, Style.RED if is_full else Style.TEXT_SOFT)


# ---- lists

func _show_roster() -> void:
	_note.visible = false
	for character in hall.roster():
		Style.add_row(_card_list, MemberCardScene).setup(hall, character)
	_empty_label.text = EMPTY_ROSTER
	_empty_label.visible = hall.roster().is_empty()


## Recruits only come while standing is above GuildUpgrades.MINIMUM_STANDING.
func _show_for_hire() -> void:
	_note.visible = true
	_note.text = HIRE_NOTE
	if GameState.standing > GuildUpgrades.MINIMUM_STANDING:
		for character in CharacterContainer.hireable_characters:
			Style.add_row(_card_list, HireCardScene).setup(hall, character)
		_empty_label.text = EMPTY_HIRE
	else:
		_empty_label.text = LOW_STANDING
	_empty_label.visible = CharacterContainer.hireable_characters.is_empty()
