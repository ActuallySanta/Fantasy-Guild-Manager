## Settings tab: show the welcome again, plus the upgrades page's debug
## buttons (only when GuildUpgrades.SHOW_DEBUG_BUTTONS is on).
## Scene: MobileLedger/Scenes/Pages/page_settings.tscn
extends VBoxContainer

const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")

## What the debug buttons add.
const DEBUG_GOLD := 200
const DEBUG_STANDING := 1

@onready var _welcome_button: Button = %WelcomeButton
@onready var _debug: Control = %Debug
@onready var _add_gold_button: Button = %AddGoldButton
@onready var _add_standing_button: Button = %AddStandingButton
@onready var _reset_button: Button = %ResetButton

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_welcome_button.pressed.connect(func(): ui.open_welcome())
	_add_gold_button.pressed.connect(GuildUpgrades.add_gold.bind(DEBUG_GOLD))
	_add_standing_button.pressed.connect(GuildUpgrades.add_standing.bind(DEBUG_STANDING))
	_reset_button.pressed.connect(func(): ui.reset_upgrades())


func refresh() -> void:
	_debug.visible = GuildUpgrades.SHOW_DEBUG_BUTTONS
