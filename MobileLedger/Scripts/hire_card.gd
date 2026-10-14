## A recruit on the Characters tab's For Hire half.
## Scene: MobileLedger/Scenes/Rows/hire_card.tscn
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

const TEXT_SUB := "the %s · stat total %d"
const TEXT_HIRE := "Hire %s (free)"
const TEXT_GUILD_FULL := "Guild full · upgrade Barracks"

@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _sub: Label = %Sub
@onready var _codex_button: Button = %CodexButton
@onready var _stats = %Stats
@onready var _blurb: Label = %Blurb
@onready var _hire_button: Button = %HireButton


func setup(ui: Main, c: GuildCharacter, guild_full: bool) -> void:
	_portrait.show_character(c)
	_char_name.text = c.name
	_sub.text = TEXT_SUB % [S.role_name(c), S.stat_total(c)]
	_codex_button.pressed.connect(ui.open_codex.bind(c))
	_stats.show_stats(c)
	# first line of the backstory only
	_blurb.text = c.description.strip_edges().split("\n")[0]
	_hire_button.text = TEXT_GUILD_FULL if guild_full else TEXT_HIRE % c.name
	_hire_button.disabled = guild_full
	_hire_button.pressed.connect(ui.hire.bind(c))
