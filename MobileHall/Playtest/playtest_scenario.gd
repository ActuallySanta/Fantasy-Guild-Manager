## Playtest scenario loader for Mobile Hall.
## Scenes: MobileHall/Playtest/scenario_*.tscn
##
## Puts the game into a set state (day, standing, gold, a small hurt roster),
## then the Mobile Hall UI underneath starts from there. UI-only test setup:
## it only sets values on the existing autoloads (GameState, GuildUpgrades,
## CharacterContainer) and changes none of their scripts.
##
## Run a scenario: open its .tscn and press Run Current Scene (F6).
##
## Day / gold / standing are set in _enter_tree, which runs before the HallMain
## child's _ready, so the hall builds today's quests (including the Bone Drake
## on day 10) from this state.
##
## The roster is built in _ready instead: when a scene is run directly, its
## _enter_tree also runs BEFORE the autoloads' _ready, so ExternalContentContainer
## hasn't loaded the name/backstory CSVs yet and GuildCharacter.new() would fail.
extends Control

## Day to start on. HallMain.MILESTONE_DAY (10) = Bone Drake day.
@export var start_day: int = 8
## Guild standing. GuildUpgrades.MINIMUM_STANDING is -10; at or below it
## nobody new shows up For Hire.
@export var start_standing: int = -10
@export var start_gold: int = 120
## Injury level for each adventurer in the guild, one entry per member
## (0 Healthy, 1 Sore, 2 Lightly Injured, 3 Gravely Injured).
@export var member_injuries: Array[int] = [2, 3]
## Show the Mobile Hall welcome card at the start.
@export var show_welcome: bool = true
## Toast shown once the scenario loads ("" = none).
@export var intro_toast: String = ""

@onready var _hall: Control = $HallMain


func _enter_tree() -> void:
	GameState.day = start_day
	GuildUpgrades.reset()
	GuildUpgrades.gold = start_gold
	GuildUpgrades.standing = start_standing


func _ready() -> void:
	# autoloads are ready by now (they sit before the main scene in the tree)
	CharacterContainer.active_characters.clear()
	CharacterContainer.released_characters.clear()
	for injury in member_injuries:
		var character := GuildCharacter.new()
		character.injury_level = clampi(injury, 0, GuildCharacter.InjuryLevel.GRAVELY_INJURED) as GuildCharacter.InjuryLevel
		character.injury_count = character.injury_level
		CharacterContainer.active_characters.append(character)

	# re-roll For Hire with the new standing (empty at -10)
	CharacterContainer.refresh_hireable_characters()
	GuildUpgrades.sync_characters()

	_hall.is_welcome_open = show_welcome
	if intro_toast != "":
		_hall.show_toast(intro_toast)
	_hall.queue_refresh()
