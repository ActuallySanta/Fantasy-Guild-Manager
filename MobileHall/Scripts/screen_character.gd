## Character details: portrait, health, today's task, all five stats with the
## Armory, gear and Pluck bonuses shown, gear slots, and the full backstory.
## Recruits get a Hire button.
## Guild members (living or fallen) get a Release button. It opens a confirm
## sheet over the screen that says what releasing costs before anything happens.
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
const TEXT_PLUCK_BONUS := " (+%d Pluck)"
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
const TEXT_PLUCK_NOTE := "Pluck goes up every time this hero wins a quest: +1 at Strong odds, +2 at Fair, +3 when Risky, +4 for a Long shot. Each level adds 10% of their base Power, Defense, Wisdom and Sleaziness (rounded down), but never less than +1 per level."
const TEXT_RECRUIT := "Recruit · not hired yet"
const TEXT_RETURNING := "Former member · wants back in"
const TEXT_FREE := "Free today"
const TEXT_DIED_ON := "Died on Day %d · %s"
const TEXT_FALLEN := "Fallen"
const TEXT_ON_QUEST := "#%d %s (%s)"
const TEXT_TRAINING := "Training %s tonight (+%d)"
const TEXT_IN_BED := "In a Hospital bed · healthy in %s"
const BUTTON_BACK := "Back"
const BUTTON_HIRE := "Hire · free"
const BUTTON_HIRE_COST := "Hire · %dg"
const BUTTON_RELEASE := "Release"
# Release confirm sheet
const TEXT_RELEASE_TITLE := "Release %s?"
const TEXT_RELEASE_COST := "%s leaves the guild for good. Their gear goes back to your pack. Costs %d standing."
const TEXT_RELEASE_FALLEN := "Say goodbye to %s. Their gear goes back to your pack."
const TEXT_RELEASE_QUEST := " They'll leave %s."
const BUTTON_RELEASE_CONFIRM := "Release"

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
@onready var _release_button: Button = %ReleaseButton
# Release confirm sheet (top_level in the scene, so the VBox doesn't lay it out
# and it covers the whole hall like the other overlays)
@onready var _release_confirm: Control = %ReleaseConfirm
@onready var _release_dim: Control = %ReleaseDim
@onready var _release_title: Label = %ReleaseTitle
@onready var _release_sub: Label = %ReleaseSub
@onready var _release_cancel_button: Button = %ReleaseCancelButton
@onready var _release_confirm_button: Button = %ReleaseConfirmButton

## The main hall script (state + actions), set in setup().
var hall: HallMain
## The Equip pick list is open (view state; closes when another hero is shown).
var _is_picking_gear := false
var _gear_character: GuildCharacter
## The Release confirm sheet is open (view state; closes when another hero is shown).
var _is_confirming_release := false
var _release_character: GuildCharacter


func setup(main: HallMain) -> void:
	hall = main
	_back_button.pressed.connect(hall.close_screen)
	_hire_button.pressed.connect(_on_hire_pressed)
	_release_button.pressed.connect(_on_release_pressed)
	_release_cancel_button.pressed.connect(_on_release_cancelled)
	_release_confirm_button.pressed.connect(_on_release_confirmed)
	_release_dim.gui_input.connect(_on_release_dim_input)
	_back_button.text = BUTTON_BACK
	_hire_button.text = BUTTON_HIRE
	_release_button.text = BUTTON_RELEASE
	_release_cancel_button.text = BUTTON_CANCEL
	_release_confirm_button.text = BUTTON_RELEASE_CONFIRM
	_pluck_note.text = TEXT_PLUCK_NOTE
	Style.style_button(_back_button, "wood")
	Style.style_button(_hire_button, "gold")
	Style.style_button(_release_button, "wood")
	Style.style_button(_release_cancel_button, "paper")
	Style.style_button(_release_confirm_button, "wood")


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
	if character.cost > 0:
		_hire_button.text = BUTTON_HIRE_COST % character.cost
	else:
		_hire_button.text = BUTTON_HIRE
	_release_button.visible = not is_recruit
	_show_release_confirm(character, is_recruit)


## The character this screen is showing (set by hall.open_character).
func _shown_character() -> GuildCharacter:
	return hall.active_screen.character


## "Recruit", "Former member", "Free today", or "#2 Escort the Merchant (sent)".
func _show_task(character: GuildCharacter, is_recruit: bool) -> void:
	if is_recruit and CharacterContainer.released_characters.has(character):
		_task.text = TEXT_RETURNING
		return
	if is_recruit:
		_task.text = TEXT_RECRUIT
		return
	if Style.is_dead(character):
		if character.died_on_day >= 0:
			_task.text = TEXT_DIED_ON % [character.died_on_day, character.died_on_quest]
		else:
			_task.text = TEXT_FALLEN
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


## One line per stat: name and base value, then the Armory, gear and Pluck bonuses
## as separate tags ("5 (+1 Armory) (+2 gear)"), in that stat's ink inside an
## outline inked the same colour.
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

		# Pluck raises the quest stats (not itself); the amount comes from the character
		var pluck_bonus := 0
		if stat_index < Style.QUEST_STAT_COUNT:
			pluck_bonus = character.get_pluck_stat_bonus(stat_index)

		# the number is the stat before any bonus, like the stat chips; quests use the sum
		name_label.text = stat.name
		value_label.text = str(Style.quest_stat_value(character, stat_index) - Style.stat_bonus(character, stat_index))
		if armory_bonus > 0:
			value_label.text += TEXT_ARMORY_BONUS % armory_bonus
		if gear_bonus > 0:
			value_label.text += TEXT_GEAR_BONUS % gear_bonus
		if pluck_bonus > 0:
			value_label.text += TEXT_PLUCK_BONUS % pluck_bonus
		Style.set_font_color(name_label, stat.color)
		Style.set_font_color(value_label, stat.color)
		Style.tint_art(line, stat.color)


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


## The Release confirm sheet: "Release Mira?" plus what it costs and, if they're
## in a party, which quest they'll leave. Hidden for recruits and when not open.
func _show_release_confirm(character: GuildCharacter, is_recruit: bool) -> void:
	# a different hero (or a recruit) never opens with the sheet already up
	if character != _release_character or is_recruit:
		_release_character = character
		_is_confirming_release = false
	_release_confirm.visible = _is_confirming_release
	if not _is_confirming_release:
		return

	_release_title.text = TEXT_RELEASE_TITLE % character.name
	var standing_cost := hall.release_standing_cost(character)
	if standing_cost > 0:
		_release_sub.text = TEXT_RELEASE_COST % [character.name, standing_cost]
	else:
		_release_sub.text = TEXT_RELEASE_FALLEN % character.name
	var quest_index := hall.quest_index_of(character)
	if quest_index >= 0:
		_release_sub.text += TEXT_RELEASE_QUEST % hall.quest_entries[quest_index].quest.questTitle


## Footer Release button: open the confirm sheet (nothing happens yet).
func _on_release_pressed() -> void:
	_is_confirming_release = true
	hall.queue_refresh()


func _on_release_cancelled() -> void:
	_is_confirming_release = false
	hall.queue_refresh()


## Confirmed: the hall does the releasing, then the screen goes back to where it
## was opened from (this hero isn't in the guild anymore).
func _on_release_confirmed() -> void:
	_is_confirming_release = false
	hall.release(_shown_character())
	hall.close_screen()


## Tapping the dimmed background cancels, like the End Day sheet.
func _on_release_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_release_cancelled()
