## A recruit for hire: portrait, stats, Details + Hire buttons.
## Scene: MobileFlow/Scenes/Rows/recruit_card.tscn
extends PanelContainer

const S := preload("res://MobileFlow/Scripts/flow_style.gd")
const Main := preload("res://MobileFlow/Scripts/flow_main.gd")

# ---- TEXT
const TEXT_HIRE := "Hire (free)"
const TEXT_GUILD_FULL := "Guild full"

# ---- NODES
@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _role: Label = %Role
@onready var _stats = %Stats
@onready var _details_button: Button = %DetailsButton
@onready var _hire_button: Button = %HireButton


func setup(ui: Main, c: GuildCharacter, guild_full: bool) -> void:
	_portrait.show_character(c)
	_char_name.text = c.name
	_role.text = S.role_name(c)
	_stats.show_stats(c)
	_details_button.pressed.connect(ui.open_character.bind(c))
	_hire_button.text = TEXT_GUILD_FULL if guild_full else TEXT_HIRE
	_hire_button.disabled = guild_full
	_hire_button.pressed.connect(ui.hire.bind(c))
