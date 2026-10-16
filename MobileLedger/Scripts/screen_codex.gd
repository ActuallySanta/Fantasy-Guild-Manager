## Adventurer Codex: one character's portrait, health, backstory and stats.
## Scene: MobileLedger/Scenes/Screens/screen_codex.tscn
##
## The five stat lines are fixed nodes in the scene (%Stat0..%Stat4, in
## ledger_style.gd STATS order), each with "Value" and a "BonusBox" holding
## "Bonus" (+N) and "None" (—).
extends TextureRect

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

const BONUS_BG := Color("#E3EFD2")
const BONUS_BORDER := Color("#4F7A3A")

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_QUESTING := "Questing: %s"
const TEXT_BONUS := "+%d"
const TEXT_ARMORY_NOTE := "Green bonuses come from the Armory (level %d) and already count toward quest odds."
const TEXT_HIRE := "Hire %s (free)"
const TEXT_GUILD_FULL := "Guild full"

# ---- NODES
@onready var _top_bar = %TopBar
@onready var _page_scroll: ScrollContainer = %PageScroll
@onready var _oval: Panel = %Oval
@onready var _art: TextureRect = %Art
@onready var _char_name: Label = %CharName
@onready var _role: Label = %Role
@onready var _ribbon: PanelContainer = %Ribbon
@onready var _ribbon_text: Label = %RibbonText
@onready var _injury_count: Label = %InjuryCount
@onready var _questing: Label = %Questing
@onready var _story_toggle: Button = %StoryToggle
@onready var _chevron: TextureRect = %Chevron
@onready var _backstory: Label = %Backstory
@onready var _stat_rows: Array = [%Stat0, %Stat1, %Stat2, %Stat3, %Stat4]
@onready var _armory_note: Label = %ArmoryNote
@onready var _assign_button: Button = %AssignButton
@onready var _hire_button: Button = %HireButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_top_bar.back_pressed.connect(func(): ui.close_page())
	_story_toggle.pressed.connect(func(): ui.toggle_story())
	_assign_button.pressed.connect(func(): ui.open_tab("quests"))
	_hire_button.pressed.connect(func():
		ui.hire(ui.page.character)
		ui.close_page())


func scroll_to_top() -> void:
	_page_scroll.scroll_vertical = 0


func refresh() -> void:
	var c: GuildCharacter = ui.page.character
	var hired: bool = CharacterContainer.active_characters.has(c)
	_show_header(c)
	_show_backstory(c)
	_show_stats(c, hired)
	_show_actions(c, hired)


## Portrait in the oval frame, name, role, health ribbon.
func _show_header(c: GuildCharacter) -> void:
	var ground: StyleBoxFlat = _oval.get_theme_stylebox("panel").duplicate()
	ground.bg_color = S.ROLE_GROUNDS[clampi(c.role, 0, 3)]
	_oval.add_theme_stylebox_override("panel", ground)
	_art.texture = ExternalContentContainer.get_character_icon(c.role)
	_char_name.text = c.name
	_role.text = TEXT_ROLE % S.role_name(c)
	var injury: Array = S.INJURY[clampi(c.injury_level, 0, 4)]
	_ribbon.add_theme_stylebox_override("panel", S.flat(injury[1], 4, 3, injury[2].darkened(0.1), Vector4(26, 4, 26, 6)))
	_ribbon_text.text = injury[0]
	S.color(_ribbon_text, injury[2])
	_injury_count.text = S.injuries_taken(c)
	var e: Dictionary = ui.entry_of(c)
	_questing.visible = not e.is_empty()
	if not e.is_empty():
		_questing.text = TEXT_QUESTING % e.quest.questTitle


## Collapsible: tap the header to open / close.
func _show_backstory(c: GuildCharacter) -> void:
	_chevron.texture = S.icon_tex("chev_up" if ui.story_open else "chev_down")
	_backstory.visible = ui.story_open
	_backstory.text = S.backstory(c)


## Base value, plus the Armory bonus in a green box ("—" when there's none).
func _show_stats(c: GuildCharacter, hired: bool) -> void:
	for i in 5:
		var bonus := GuildUpgrades.get_stat_bonus(c, i) if hired and i < 4 else 0
		var row: Node = _stat_rows[i]
		var box: PanelContainer = row.get_node("BonusBox")
		row.get_node("Value").text = str(S.stat_value(c, i) - bonus)
		box.get_node("Bonus").text = TEXT_BONUS % bonus
		box.get_node("Bonus").visible = bonus > 0
		box.get_node("None").visible = bonus <= 0
		if bonus > 0:
			box.add_theme_stylebox_override("panel", S.flat(BONUS_BG, 8, 2, BONUS_BORDER, Vector4(4, 0, 4, 2)))
		else:
			box.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_armory_note.visible = hired
	_armory_note.text = TEXT_ARMORY_NOTE % GuildUpgrades.get_level(GuildUpgrades.Building.ARMORY)


## Guild members: "Assign to Quest". Recruits: "Hire <name> (free)".
func _show_actions(c: GuildCharacter, hired: bool) -> void:
	_assign_button.visible = hired
	_hire_button.visible = not hired
	var full: bool = CharacterContainer.active_characters.size() >= CharacterContainer.max_characters
	_hire_button.text = TEXT_GUILD_FULL if full else TEXT_HIRE % c.name
	_hire_button.disabled = full
