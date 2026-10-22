## Character details: portrait, health, today's task, all five stats with the
## Armory bonus shown, and the full backstory. Recruits get a Hire button.
## Scene: MobileHall/Scenes/Screens/screen_character.tscn
extends VBoxContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_INJURIES := "%s taken"
const TEXT_NO_INJURIES := "No injuries yet"
const TEXT_BONUS := " (+%d Armory)"
const TEXT_PLUCK_NOTE := "Pluck isn't used by quests yet."
const TEXT_RECRUIT := "Recruit · not hired yet"
const TEXT_FREE := "Free today"
const TEXT_ON := "#%d %s (%s)"
const BUTTON_BACK := "Back"
const BUTTON_HIRE := "Hire · free"

# ---- NODES
@onready var _scroll: ScrollContainer = %Scroll
@onready var _portrait = %Portrait
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _health = %HealthChip
@onready var _injuries: Label = %Injuries
@onready var _task: Label = %Task
@onready var _stat_lines: VBoxContainer = %StatLines
@onready var _pluck_note: Label = %PluckNote
@onready var _story: Label = %Story
@onready var _back_button: Button = %BackButton
@onready var _hire_button: Button = %HireButton

var ui


func setup(main) -> void:
	ui = main
	_back_button.pressed.connect(ui.close_screen)
	_hire_button.pressed.connect(_on_hire)
	_back_button.text = BUTTON_BACK
	_hire_button.text = BUTTON_HIRE
	S.style_button(_back_button, "wood")
	S.style_button(_hire_button, "gold")


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	var c: GuildCharacter = ui.screen.character
	_portrait.show_character(c)
	_name.text = c.name
	_role.text = TEXT_ROLE % S.role_name(c)
	_health.set_health(c)
	_injuries.text = TEXT_INJURIES % S.count(c.injury_count, "injury", "injuries") if c.injury_count > 0 else TEXT_NO_INJURIES
	_show_task(c)
	_show_stats(c)
	_pluck_note.text = TEXT_PLUCK_NOTE
	_story.text = S.backstory(c)
	_hire_button.visible = CharacterContainer.hireable_characters.has(c)
	_hire_button.disabled = ui.roster_full()


func _show_task(c: GuildCharacter) -> void:
	if CharacterContainer.hireable_characters.has(c):
		_task.text = TEXT_RECRUIT
		return
	var i: int = ui.entry_index_of(c)
	if i < 0:
		_task.text = TEXT_FREE
	else:
		var e: Dictionary = ui.entries[i]
		_task.text = TEXT_ON % [i + 1, e.quest.questTitle, "sent" if e.state == "ready" else "picked"]


## One line per stat: name, value (+ Armory bonus).
func _show_stats(c: GuildCharacter) -> void:
	for i in 5:
		var line: PanelContainer = _stat_lines.get_child(i)
		var st: Dictionary = S.STATS[i]
		var label: Label = line.get_node("Row/Name")
		var value: Label = line.get_node("Row/Value")
		label.text = st.name
		S.color(label, st.color)
		var bonus := 0
		if i < 4:
			bonus = GuildUpgrades.get_stat_bonus(c, i)
		value.text = str(S.stat_value(c, i)) + (TEXT_BONUS % bonus if bonus > 0 else "")
		S.color(value, st.color)
		S.tint(line, st.color)


func _on_hire() -> void:
	var c: GuildCharacter = ui.screen.character
	ui.hire(c)
	ui.close_screen()
