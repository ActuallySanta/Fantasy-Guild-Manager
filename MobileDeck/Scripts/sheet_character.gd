## Character bottom sheet: portrait, health, all five stats (with Armory
## bonuses) and backstory.
## Scene: MobileDeck/Scenes/Sheets/sheet_character.tscn
##
## The five stat lines are fixed nodes in the scene (%Stat0..%Stat4, in
## deck_style.gd STATS order), each with "Value" and "Bonus" labels.
extends ColorRect

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const Main := preload("res://MobileDeck/Scripts/deck_main.gd")

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_ON_QUEST := "On quest: %s"
const TEXT_BONUS := "+%d"
const TEXT_ARMORY_NOTE := "+N = Armory bonus (level %d), already counted in quest odds."

# ---- NODES
@onready var _close_button: Button = %CloseButton
@onready var _sheet_title: Label = %SheetTitle
@onready var _portrait = %Portrait
@onready var _role: Label = %Role
@onready var _injury = %Injury
@onready var _injury_count: Label = %InjuryCount
@onready var _on_quest: Label = %OnQuest
@onready var _stat_rows: Array = [%Stat0, %Stat1, %Stat2, %Stat3, %Stat4]
@onready var _armory_note: Label = %ArmoryNote
@onready var _backstory: Label = %Backstory

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_close_button.pressed.connect(func(): ui.close_sheet())


func refresh() -> void:
	var c: GuildCharacter = ui.sheet.character
	var hired: bool = CharacterContainer.active_characters.has(c)
	_sheet_title.text = c.name
	_portrait.show_character(c)
	_role.text = TEXT_ROLE % S.role_name(c)
	_injury.set_injury(c.injury_level)
	_injury_count.text = S.injuries_taken(c)
	var e: Dictionary = ui.entry_of(c)
	_on_quest.visible = not e.is_empty()
	if not e.is_empty():
		_on_quest.text = TEXT_ON_QUEST % e.quest.questTitle
	_show_stats(c, hired)
	_backstory.text = S.backstory(c)


## Base value, plus the Armory bonus shown separately as "+N".
func _show_stats(c: GuildCharacter, hired: bool) -> void:
	for i in 5:
		var bonus := GuildUpgrades.get_stat_bonus(c, i) if hired and i < 4 else 0
		_stat_rows[i].get_node("Value").text = str(S.stat_value(c, i) - bonus)
		_stat_rows[i].get_node("Bonus").text = TEXT_BONUS % bonus if bonus > 0 else ""
	_armory_note.visible = hired
	_armory_note.text = TEXT_ARMORY_NOTE % GuildUpgrades.get_level(GuildUpgrades.Building.ARMORY)
