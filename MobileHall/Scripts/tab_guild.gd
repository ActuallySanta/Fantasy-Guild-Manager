## Guild tab (the "Members" nav button): a folder with two tabs, "Your Guild"
## (the roster) and "Applicants" (today's recruits). Applicants come as a stack
## of letters: the top one is read in full, the ones under it peek out and
## come to the top when tapped. The Applicants tab shows how many are waiting.
## A line at the top shows beds used and links to the Barracks upgrade.
## Scene: MobileHall/Scenes/Tabs/tab_guild.tscn
extends VBoxContainer

const MemberCardScene := preload("uid://dls1bjn8gt2fe")  # MobileHall/Scenes/Rows/member_card.tscn
const HireCardScene := preload("uid://cy6d8ep8exxlt")  # MobileHall/Scenes/Rows/hire_card.tscn
const HirePeekScene := preload("uid://3jfkcim0fo7x")  # MobileHall/Scenes/Rows/hire_peek.tscn
const HeadingScene := preload("uid://bve0dglxrk3x4")  # MobileHall/Scenes/Rows/home_heading.tscn

## Cards of fallen heroes fade back, like faded rows elsewhere in the hall.
const FALLEN_OPACITY := 0.6

## How many letters peek out under the top one, and their small tilts (degrees).
const PEEK_COUNT := 2
const PEEK_TILTS := [0.6, -0.5]
## Where the next letter starts from after a hire (it slides up into place).
const NEXT_LETTER_SLIDE := Vector2(0, 48)
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
const BEDS_FULL := "All %d beds full"
const BEDS_BUTTON := "Barracks"
# Lists
const EMPTY_ROSTER := "Nobody here yet."
const NO_LIVING := "Nobody left standing."
const HEADING_FALLEN := "Fallen · %d"
const EMPTY_HIRE := "No applicants left. More tomorrow."
const LOW_STANDING := "Standing too low to attract applicants."
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
	HallStyle.clear_children(_card_list)
	HallStyle.clear_children(_letter_stack)
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
	_roster_section_button.text = SECTION_ROSTER % [CharacterContainer.living_count(), CharacterContainer.max_characters]
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
	var beds_used: int = CharacterContainer.living_count()
	var bed_count := CharacterContainer.max_characters
	var is_full := beds_used >= bed_count
	if is_full:
		_beds_label.text = BEDS_FULL % bed_count
	else:
		var barracks_level := GuildUpgrades.get_level(GuildUpgrades.Building.BARRACKS)
		_beds_label.text = BEDS % [beds_used, bed_count, barracks_level]
	HallStyle.set_font_color(_beds_label, BEDS_FULL_COLOR if is_full else HallStyle.CREAM)


# ---- lists

## Living heroes first, then the fallen under their own heading (they don't
## take a bed, but stay here so the Hospital can revive them).
func _show_roster() -> void:
	var living := hall.roster().filter(func(character): return not HallStyle.is_dead(character))
	var fallen := hall.roster().filter(func(character): return HallStyle.is_dead(character))

	for character in living:
		HallStyle.add_row(_card_list, MemberCardScene).setup(hall, character)
	if living.is_empty() and not fallen.is_empty():
		var no_living_note: Label = _empty_label.duplicate()
		no_living_note.text = NO_LIVING
		no_living_note.visible = true
		_card_list.add_child(no_living_note)

	if not fallen.is_empty():
		var heading: Label = HallStyle.add_row(_card_list, HeadingScene)
		heading.text = HEADING_FALLEN % fallen.size()
		heading.theme_type_variation = &"CapsLight"
		for character in fallen:
			var card: Control = HallStyle.add_row(_card_list, MemberCardScene)
			card.setup(hall, character)
			card.modulate = Color(1, 1, 1, FALLEN_OPACITY)
	_empty_label.text = EMPTY_ROSTER
	_empty_label.visible = hall.roster().is_empty()


## Recruits only come while standing is above GuildUpgrades.MINIMUM_STANDING.
## They're a stack of letters: one on top, the next few peeking out under it.
func _show_for_hire() -> void:
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
	var top_card := HallStyle.add_row(_letter_stack, HireCardScene)
	top_card.z_index = PEEK_COUNT + 1
	top_card.setup(hall, recruits[_top_letter], _top_letter)
	# the last letter was just hired: the next one slides up off the stack
	if hall.pending_fx.get("hire_next", false):
		HallFx.slide_in(top_card, NEXT_LETTER_SLIDE)

	# the next applicants peek out underneath, each a little further back
	for peek_index in mini(PEEK_COUNT, recruits.size() - 1):
		var recruit_index := (_top_letter + 1 + peek_index) % recruits.size()
		var recruit: GuildCharacter = recruits[recruit_index]
		var peek := HallStyle.add_row(_letter_stack, HirePeekScene)
		peek.z_index = PEEK_COUNT - peek_index
		peek.rotation_degrees = PEEK_TILTS[peek_index]
		peek.get_node("Text").text = PEEK % [recruit.name, HallStyle.role_name(recruit)]
		peek.pressed.connect(_bring_to_top.bind(recruit_index))


func _bring_to_top(recruit_index: int) -> void:
	_top_letter = recruit_index
	hall.queue_refresh()


## The "Your Guild" folder tab, where hired letters fly to (hall_main.send_hired_letter).
func roster_button() -> Control:
	return _roster_section_button
