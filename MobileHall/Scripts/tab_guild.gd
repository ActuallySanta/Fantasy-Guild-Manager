## Guild tab (the "Members" nav button): a folder with two tabs, "Your Guild"
## (the roster) and "Applicants" (today's recruits). Applicants come as a stack
## of letters: the top one is read in full, the ones under it peek out and
## come to the top when tapped. The Applicants tab shows how many are waiting.
## A line at the top shows beds used and links to the Barracks upgrade.
## Scene: MobileHall/Scenes/Tabs/tab_guild.tscn
extends VBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const MemberCardScene := preload("res://MobileHall/Scenes/Rows/member_card.tscn")
const HireCardScene := preload("res://MobileHall/Scenes/Rows/hire_card.tscn")
const HirePeekScene := preload("res://MobileHall/Scenes/Rows/hire_peek.tscn")

## How many letters peek out under the top one, and their small tilts (degrees).
const PEEK_COUNT := 2
const PEEK_TILTS := [0.6, -0.5]
## Folder tab heights: the open one stands taller and joins the folder.
const FOLDER_TAB_HEIGHT := 72
const FOLDER_TAB_HEIGHT_OPEN := 80
## Beds line ink when every bed is taken (light red, readable on the folder).
const BEDS_FULL_COLOR := Color("#F2B8A8")

# ---- TEXT
# Folder tabs
const SECTION_ROSTER := "Your Guild · %d/%d"
const SECTION_HIRE := "Applicants"
# Beds line
const BEDS := "Beds %d of %d · Barracks Lv %d"
const BEDS_FULL := "All %d beds are taken. Upgrade the Barracks for more."
const BEDS_BUTTON := "Barracks"
# Lists
const EMPTY_ROSTER := "Nobody here yet. Hire someone from Applicants."
const EMPTY_HIRE := "No applicants left today. New faces arrive every morning."
const HIRE_NOTE := "Hiring is free. New applicants arrive every morning."
const LOW_STANDING := "Your guild is too unpopular, and has thus failed to attract new talent"
const PEEK := "%s · %s"

# ---- NODES
# Folder tabs
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
@onready var _letter_stack: VBoxContainer = %Stack
@onready var _empty_label: Label = %Empty

## The main hall script (state + actions), set in setup().
var hall: HallMain
## Index into CharacterContainer.hireable_characters of the letter on top.
var _top_letter := 0


func setup(main: HallMain) -> void:
	hall = main
	_roster_section_button.pressed.connect(func(): hall.show_guild_section(HallMain.GUILD_SECTION_ROSTER))
	_hire_section_button.pressed.connect(func(): hall.show_guild_section(HallMain.GUILD_SECTION_HIRE))
	_barracks_button.pressed.connect(func(): hall.open_tab("upgrades", HallMain.UPGRADES_SECTION_BUILD))
	_barracks_button.text = BEDS_BUTTON


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	_show_section_buttons()
	_show_beds()
	Style.clear_children(_card_list)
	Style.clear_children(_letter_stack)
	if _is_hire_section():
		_show_for_hire()
	else:
		_show_roster()


func _is_hire_section() -> bool:
	return hall.guild_section == HallMain.GUILD_SECTION_HIRE


# ---- top of the tab

## The open folder tab is the lighter one that joins the folder below;
## Applicants gets a count badge while closed.
func _show_section_buttons() -> void:
	var on_hire := _is_hire_section()
	_roster_section_button.text = SECTION_ROSTER % [hall.roster().size(), CharacterContainer.max_characters]
	_hire_section_button.text = SECTION_HIRE
	_roster_section_button.theme_type_variation = &"FolderTab" if on_hire else &"FolderTabActive"
	_hire_section_button.theme_type_variation = &"FolderTabActive" if on_hire else &"FolderTab"
	_roster_section_button.custom_minimum_size.y = FOLDER_TAB_HEIGHT if on_hire else FOLDER_TAB_HEIGHT_OPEN
	_hire_section_button.custom_minimum_size.y = FOLDER_TAB_HEIGHT_OPEN if on_hire else FOLDER_TAB_HEIGHT

	var recruit_count := CharacterContainer.hireable_characters.size()
	_hire_badge.visible = not on_hire and recruit_count > 0 and not hall.is_roster_full()
	_hire_badge_text.text = str(recruit_count)


## "Beds 3 of 5 · Barracks Lv 1", or a red warning when they're all taken.
func _show_beds() -> void:
	var beds_used: int = hall.roster().size()
	var bed_count := CharacterContainer.max_characters
	var is_full := beds_used >= bed_count
	if is_full:
		_beds_label.text = BEDS_FULL % bed_count
	else:
		var barracks_level := GuildUpgrades.get_level(GuildUpgrades.Building.BARRACKS)
		_beds_label.text = BEDS % [beds_used, bed_count, barracks_level]
	Style.set_font_color(_beds_label, BEDS_FULL_COLOR if is_full else Style.CREAM)


# ---- lists

func _show_roster() -> void:
	_note.visible = false
	for character in hall.roster():
		Style.add_row(_card_list, MemberCardScene).setup(hall, character)
	_empty_label.text = EMPTY_ROSTER
	_empty_label.visible = hall.roster().is_empty()


## Recruits only come while standing is above GuildUpgrades.MINIMUM_STANDING.
## They're a stack of letters: one on top, the next few peeking out under it.
func _show_for_hire() -> void:
	_note.visible = true
	_note.text = HIRE_NOTE
	var recruits: Array = CharacterContainer.hireable_characters
	if GameState.standing <= GuildUpgrades.MINIMUM_STANDING:
		_empty_label.text = LOW_STANDING
		_empty_label.visible = true
		return
	_empty_label.text = EMPTY_HIRE
	_empty_label.visible = recruits.is_empty()
	if recruits.is_empty():
		return

	_top_letter = clampi(_top_letter, 0, recruits.size() - 1)
	var top_card := Style.add_row(_letter_stack, HireCardScene)
	top_card.z_index = PEEK_COUNT + 1
	top_card.setup(hall, recruits[_top_letter], _top_letter)

	# the next applicants peek out underneath, each a little further back
	for peek_index in mini(PEEK_COUNT, recruits.size() - 1):
		var recruit_index := (_top_letter + 1 + peek_index) % recruits.size()
		var recruit: GuildCharacter = recruits[recruit_index]
		var peek := Style.add_row(_letter_stack, HirePeekScene)
		peek.z_index = PEEK_COUNT - peek_index
		peek.rotation_degrees = PEEK_TILTS[peek_index]
		peek.get_node("Text").text = PEEK % [recruit.name, Style.role_name(recruit)]
		peek.pressed.connect(_bring_to_top.bind(recruit_index))


func _bring_to_top(recruit_index: int) -> void:
	_top_letter = recruit_index
	hall.queue_refresh()
