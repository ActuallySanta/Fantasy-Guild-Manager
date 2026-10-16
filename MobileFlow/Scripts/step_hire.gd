## Step 1: Hire. Today's recruits, each with stats and a Hire button.
## Skippable; on Day 1 it's where the player has to start.
## Scene: MobileFlow/Scenes/Steps/step_hire.tscn
extends VBoxContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")
const RecruitCard := preload("res://MobileFlow/Scenes/Rows/recruit_card.tscn")
const Portrait := preload("res://MobileFlow/Scenes/Components/portrait.tscn")

# ---- TEXT
const TEXT_ROOM := "Hiring is free. Your guild has room for %d more (%d/%d)."
const TEXT_FULL := "Your guild is full (%d/%d). Upgrade the Barracks for more room."

# ---- NODES
@onready var _scroll: ScrollContainer = %Scroll
@onready var _subtitle: Label = %Subtitle
@onready var _guild_strip: Control = %GuildStrip
@onready var _guild_portraits: Container = %GuildPortraits
@onready var _recruits: Container = %Recruits
@onready var _low_standing: Control = %LowStanding
@onready var _no_recruits: Control = %NoRecruits
@onready var _footer: Control = %Footer
@onready var _footer_warning: Label = %FooterWarning
@onready var _next_button: Button = %NextButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_next_button.pressed.connect(func(): ui.go_step("quests"))


func footer_height() -> float:
	return _footer.size.y


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	var roster: Array = CharacterContainer.active_characters
	var cap: int = CharacterContainer.max_characters
	var room := cap - roster.size()
	_subtitle.text = TEXT_ROOM % [room, roster.size(), cap] if room > 0 else TEXT_FULL % [roster.size(), cap]
	
	if(GameState.standing > GuildUpgrades.MINIMUM_STANDING):
		_show_guild_strip(roster)
		_show_recruits(room <= 0)
		# nobody hired yet: warn, and don't make Next look like the obvious move
		_footer_warning.visible = roster.is_empty()
	
	_low_standing.visible = !(GameState.standing > GuildUpgrades.MINIMUM_STANDING)
	S.style_button(_next_button, "" if roster.is_empty() else "green")


## Current guild as a strip of small portraits.
func _show_guild_strip(roster: Array) -> void:
	_guild_strip.visible = not roster.is_empty()
	S.clear(_guild_portraits)
	for c in roster:
		S.add_row(_guild_portraits, Portrait).show_character(c)


func _show_recruits(guild_full: bool) -> void:
	var hires: Array = CharacterContainer.hireable_characters
	S.clear(_recruits)
	for c in hires:
		S.add_row(_recruits, RecruitCard).setup(ui, c, guild_full)
	_no_recruits.visible = hires.is_empty()
