## Character details: portrait, health, today's task, all five stats with the
## Armory and gear bonuses shown, gear slots, and the full backstory.
## Recruits get a Hire button.
## Gear: one row per equipped item (Take off) and per empty slot (Equip). Equip
## opens a pick list of owned items this hero's role can use; items worn by
## another hero can be taken from them. Rules live in the ItemShop autoload.
## Scene: MobileHall/Scenes/Screens/screen_character.tscn
extends VBoxContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const HallMain := preload("res://MobileHall/Scripts/hall_main.gd")
const GearRowScene := preload("res://MobileHall/Scenes/Rows/gear_row.tscn")

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_INJURIES := "%s taken"
const TEXT_NO_INJURIES := "No injuries yet"
const TEXT_ARMORY_BONUS := " (+%d Armory)"
const TEXT_GEAR_BONUS := " (+%d gear)"
const TEXT_EMPTY_SLOT := "Empty slot"
const TEXT_EMPTY_HINT := "%s gear only"
const TEXT_GEAR_NOTE := "Holds %s. Buy gear in the Shop."
const TEXT_PICK_NOTE := "Pick something for %s to wear."
const TEXT_PICK_NONE := "No %s gear in your pack. Buy some in the Shop."
const TEXT_GEAR_DEAD := "%s can't use gear anymore. Take it off for someone else."
const TEXT_WORN_BY := " · on %s"
const BUTTON_EQUIP := "Equip"
const BUTTON_TAKE := "Take"
const BUTTON_TAKE_OFF := "Take off"
const BUTTON_CANCEL := "Cancel"
const TEXT_PLUCK_NOTE := "Pluck isn't used by quests yet."
const TEXT_RECRUIT := "Recruit · not hired yet"
const TEXT_FREE := "Free today"
const TEXT_ON_QUEST := "#%d %s (%s)"
const TEXT_TRAINING := "Training %s tonight (+%d)"
const TEXT_IN_BED := "In a Hospital bed · healthy in %s"
const BUTTON_BACK := "Back"
const BUTTON_HIRE := "Hire (free)"

# ---- NODES
# Identity
@onready var _scroll: ScrollContainer = %Scroll
@onready var _portrait = %Portrait            # portrait.gd
@onready var _name: Label = %Name
@onready var _role: Label = %Role
# Health and task
@onready var _health_chip = %HealthChip       # chip.gd
@onready var _injuries: Label = %Injuries
@onready var _task: Label = %Task
# Stats and story
@onready var _stat_lines: VBoxContainer = %StatLines
@onready var _pluck_note: Label = %PluckNote
@onready var _backstory: Label = %Story
# Gear
@onready var _gear_heading: Label = %GearHeading
@onready var _gear_lines: VBoxContainer = %GearLines
@onready var _gear_note: Label = %GearNote
# Footer
@onready var _back_button: Button = %BackButton
@onready var _hire_button: Button = %HireButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The Equip pick list is open (view state; closes when another hero is shown).
var _is_picking_gear := false
var _gear_character: GuildCharacter


func setup(main: HallMain) -> void:
	hall = main
	_back_button.pressed.connect(hall.close_screen)
	_hire_button.pressed.connect(_on_hire_pressed)
	_back_button.text = BUTTON_BACK
	_hire_button.text = BUTTON_HIRE
	_pluck_note.text = TEXT_PLUCK_NOTE
	Style.style_button(_back_button, "paper", 28)
	Style.style_button(_hire_button, "green", 30)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	var character := _shown_character()
	var is_recruit := CharacterContainer.hireable_characters.has(character)

	_portrait.show_character(character)
	_name.text = character.name
	_role.text = TEXT_ROLE % Style.role_name(character)
	_health_chip.set_health(character)
	if character.injury_count > 0:
		_injuries.text = TEXT_INJURIES % Style.count_text(character.injury_count, "injury", "injuries")
	else:
		_injuries.text = TEXT_NO_INJURIES
	_show_task(character, is_recruit)
	_show_stats(character)
	_show_gear(character, is_recruit)
	_backstory.text = Style.clean_backstory(character)

	_hire_button.visible = is_recruit
	_hire_button.disabled = hall.is_roster_full()


## The character this screen is showing (set by hall.open_character).
func _shown_character() -> GuildCharacter:
	return hall.active_screen.character


## "Recruit", "Free today", or "#2 Escort the Merchant (sent)".
func _show_task(character: GuildCharacter, is_recruit: bool) -> void:
	if is_recruit:
		_task.text = TEXT_RECRUIT
		return
	var quest_index := hall.quest_index_of(character)
	if quest_index < 0 and GuildUpgrades.is_patient(character):
		var nights := GuildUpgrades.get_nights_until_healthy(character, true)
		_task.text = TEXT_IN_BED % Style.count_text(nights, "night", "nights")
		return
	if quest_index < 0 and GuildUpgrades.is_training(character):
		var stat_name: String = Style.STATS[GuildUpgrades.get_training_stat(character)].name
		_task.text = TEXT_TRAINING % [stat_name, GuildUpgrades.get_training_gain()]
		return
	if quest_index < 0:
		_task.text = TEXT_FREE
		return
	var entry: Dictionary = hall.quest_entries[quest_index]
	var party_state := "sent" if entry.state == Style.QUEST_STATE_SENT else "picked"
	_task.text = TEXT_ON_QUEST % [quest_index + 1, entry.quest.questTitle, party_state]


## One line per stat: name and value (+ Armory bonus), in that stat's colours.
## The StatLines node has one authored line per stat, each with Row/Name and Row/Value.
func _show_stats(character: GuildCharacter) -> void:
	for stat_index in Style.STAT_COUNT:
		var stat: Dictionary = Style.STATS[stat_index]
		var line: PanelContainer = _stat_lines.get_child(stat_index)
		var name_label: Label = line.get_node("Row/Name")
		var value_label: Label = line.get_node("Row/Value")

		# the Armory only boosts the quest stats, not Pluck
		var armory_bonus := 0
		if stat_index < Style.QUEST_STAT_COUNT:
			armory_bonus = GuildUpgrades.get_stat_bonus(character, stat_index)

		var gear_bonus := 0
		if stat_index < Style.QUEST_STAT_COUNT:
			gear_bonus = ItemShop.get_item_bonus(character, stat_index)

		name_label.text = stat.name
		value_label.text = str(Style.stat_value(character, stat_index))
		if armory_bonus > 0:
			value_label.text += TEXT_ARMORY_BONUS % armory_bonus
		if gear_bonus > 0:
			value_label.text += TEXT_GEAR_BONUS % gear_bonus
		Style.set_font_color(name_label, stat.color)
		Style.set_font_color(value_label, stat.color)
		line.add_theme_stylebox_override("panel", Style.flat_box(stat.bg, 12))


## Worn items, empty slots, and (while picking) the owned items that fit.
func _show_gear(character: GuildCharacter, is_recruit: bool) -> void:
	_gear_heading.visible = not is_recruit
	_gear_lines.visible = not is_recruit
	_gear_note.visible = not is_recruit
	if character != _gear_character:
		_gear_character = character
		_is_picking_gear = false
	Style.clear_children(_gear_lines)
	if is_recruit:
		return

	var is_dead := Style.is_dead(character)
	var role_name := Style.role_name(character)
	if is_dead:
		_is_picking_gear = false

	for item in character.equipped_items:
		Style.add_row(_gear_lines, GearRowScene).setup(
			Style.item_look(item), BUTTON_TAKE_OFF, "paper", hall.unequip_item.bind(item))

	var free_slots := maxi(character.max_items - character.equipped_items.size(), 0)
	for slot in free_slots:
		var button_text := ""
		if not is_dead and slot == 0:
			button_text = BUTTON_CANCEL if _is_picking_gear else BUTTON_EQUIP
		Style.add_row(_gear_lines, GearRowScene).setup_empty(
			TEXT_EMPTY_SLOT, TEXT_EMPTY_HINT % role_name, button_text,
			"paper" if _is_picking_gear else "blue", _toggle_gear_picker)
	if free_slots == 0:
		_is_picking_gear = false

	var choices: Array[StandardItem] = []
	if _is_picking_gear:
		choices = ItemShop.items_for(character)
	for item in choices:
		var look := Style.item_look(item)
		var button_text := BUTTON_EQUIP
		if item.curr_user != null:
			look.effect += TEXT_WORN_BY % item.curr_user.name
			button_text = BUTTON_TAKE
		Style.add_row(_gear_lines, GearRowScene).setup(
			look, button_text, "green", _on_gear_picked.bind(item), true)

	if is_dead:
		_gear_note.text = TEXT_GEAR_DEAD % character.name
	elif _is_picking_gear and choices.is_empty():
		_gear_note.text = TEXT_PICK_NONE % role_name
	elif _is_picking_gear:
		_gear_note.text = TEXT_PICK_NOTE % character.name
	else:
		_gear_note.text = TEXT_GEAR_NOTE % Style.count_text(character.max_items, "item", "items")


func _toggle_gear_picker() -> void:
	_is_picking_gear = not _is_picking_gear
	hall.queue_refresh()


func _on_gear_picked(item: StandardItem) -> void:
	_is_picking_gear = false
	hall.equip_item(item, _shown_character())


func _on_hire_pressed() -> void:
	hall.hire(_shown_character())
	hall.close_screen()
