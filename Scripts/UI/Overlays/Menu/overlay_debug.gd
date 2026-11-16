## Debug tools (Menu > Debug tools, only when GuildUpgrades.SHOW_DEBUG_BUTTONS):
## cheats for testing a run. The first time in a run the sheet only warns that
## the tools stop the run from being saved, with an Enable button
## (hall.enable_debug_tools). The "Save runs" dev checkbox sits above it, so
## saving can be turned on without making a debug run. Check for update sits
## under it for the same reason (it isn't a cheat): it asks the live site which
## build it serves (HallWebUpdate.check_latest) and toasts if this one is the
## newest, else opens the update popup (overlay_update_confirm: export the
## save, then Update or Cancel). After Enable the sheet
## lists the tools, grouped:
##   Time:   skip to the next day, jump to the Bone Drake / final battle day
##   Wallet: gold and standing steps (HallDebug.GOLD_STEPS / STANDING_STEPS)
##   Guild:  add a hero, add an item, heal everyone, max the buildings,
##           reset the upgrades
##   Run:    reroll today's quests and For Hire, skip the tutorial
## The rules live in HallDebug; every button calls a hall.debug_* action.
## Back returns to the Menu; tapping the dimmed background closes both.
## Scene: MobileHall/Scenes/Overlays/overlay_debug.tscn
extends Control

## Font size of the buttons (design px; HallFontScale grows them with everything else).
const BUTTON_FONT_SIZE := 26
## Height of a tool button (design px): big enough for a thumb.
const BUTTON_HEIGHT := 80

# ---- TEXT
const NOTE_WARNING := "Debug tools stop this run from being saved. Your last save stays as it is."
const NOTE_DEBUG_RUN := "Debug run: not saving"
const BUTTON_ENABLE := "Enable debug tools"
const BUTTON_SKIP_DAY := "Skip to next day"
const BUTTON_JUMP := "Jump to day %d"
const BUTTON_GOLD := "%+d gold"
const BUTTON_STANDING := "%+d standing"
const BUTTON_ADD_HERO := "Add hero"
const BUTTON_ADD_ITEM := "Add random item"
const BUTTON_HEAL := "Heal everyone"
const BUTTON_MAX := "Max all buildings"
const BUTTON_RESET := "Reset upgrades"
const BUTTON_REROLL := "Reroll quests and For Hire"
const BUTTON_TUTORIAL := "Skip tutorial"
const CHECK_SAVE := "Save runs"
const CHECK_SAVE_OFF := "Save runs (off for debug runs)"
const BUTTON_BACK := "Back"
const BUTTON_UPDATE := "Check for update"
const BUTTON_UPDATE_CHECKING := "Checking…"
const TOAST_UP_TO_DATE := "You're on the newest version"
const TOAST_NOT_WEB := "Update checks only work in the web build"
const TOAST_CHECK_FAILED := "Couldn't check for updates · are you online?"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _note: Label = %Note
@onready var _enable_button: Button = %EnableButton
@onready var _scroll: ScrollContainer = %Scroll
@onready var _skip_button: Button = %SkipButton
@onready var _jump_grid: GridContainer = %JumpGrid
@onready var _wallet_grid: GridContainer = %WalletGrid
@onready var _hero_button: Button = %HeroButton
@onready var _item_button: Button = %ItemButton
@onready var _heal_button: Button = %HealButton
@onready var _max_button: Button = %MaxButton
@onready var _reset_button: Button = %ResetButton
@onready var _reroll_button: Button = %RerollButton
@onready var _tutorial_button: Button = %TutorialButton
@onready var _save_check: CheckBox = %SaveCheckBox
@onready var _back_button: Button = %BackButton
@onready var _update_button: Button = %UpdateButton
@onready var _update_confirm: Control = %UpdateConfirm

## The main hall script (state + actions), set in setup().
var hall: HallMain
## One "Jump to day" button per HallDebug.JUMP_DAYS entry: {day (int): Button}.
var _jump_buttons := {}


func setup(main: HallMain) -> void:
	hall = main
	_enable_button.pressed.connect(hall.enable_debug_tools)
	_skip_button.pressed.connect(hall.debug_skip_day)
	_hero_button.pressed.connect(hall.debug_add_hero)
	_item_button.pressed.connect(hall.debug_add_item)
	_heal_button.pressed.connect(hall.debug_heal_everyone)
	_max_button.pressed.connect(hall.debug_max_buildings)
	_reset_button.pressed.connect(hall.reset_upgrades)
	_reroll_button.pressed.connect(hall.debug_reroll_today)
	_tutorial_button.pressed.connect(hall.debug_skip_tutorial)
	_save_check.toggled.connect(hall.set_save_enabled)
	_back_button.pressed.connect(hall.close_debug)
	_update_button.pressed.connect(_on_update_pressed)
	_dim.gui_input.connect(_on_dim_input)
	_update_confirm.setup(hall)
	# closing Debug tools takes the update popup with it
	visibility_changed.connect(func() -> void:
		if not visible:
			_update_confirm.close())

	# the step buttons come from HallDebug's tables, so a new step needs no scene change
	for day: int in HallDebug.JUMP_DAYS:
		var button := _make_button(_jump_grid, BUTTON_JUMP % day)
		button.pressed.connect(hall.debug_jump_to_day.bind(day))
		_jump_buttons[day] = button
	for amount: int in HallDebug.GOLD_STEPS:
		_make_button(_wallet_grid, BUTTON_GOLD % amount).pressed.connect(hall.debug_add_gold.bind(amount))
	for amount: int in HallDebug.STANDING_STEPS:
		_make_button(_wallet_grid, BUTTON_STANDING % amount).pressed.connect(hall.debug_add_standing.bind(amount))

	_enable_button.text = BUTTON_ENABLE
	_skip_button.text = BUTTON_SKIP_DAY
	_hero_button.text = BUTTON_ADD_HERO
	_item_button.text = BUTTON_ADD_ITEM
	_heal_button.text = BUTTON_HEAL
	_max_button.text = BUTTON_MAX
	_reset_button.text = BUTTON_RESET
	_reroll_button.text = BUTTON_REROLL
	_tutorial_button.text = BUTTON_TUTORIAL
	_back_button.text = BUTTON_BACK
	_update_button.text = BUTTON_UPDATE
	for button in [_update_button, _skip_button, _hero_button, _item_button, _heal_button, _max_button,
			_reset_button, _reroll_button, _tutorial_button, _save_check]:
		HallStyle.style_button(button, "paper", BUTTON_FONT_SIZE)
	HallStyle.style_button(_enable_button, "red", BUTTON_FONT_SIZE)
	HallStyle.style_button(_back_button, "wood", BUTTON_FONT_SIZE)


func refresh() -> void:
	# until the tools are turned on, only the warning and Enable show
	var is_enabled := hall.is_debug_run
	_note.text = NOTE_DEBUG_RUN if is_enabled else NOTE_WARNING
	_enable_button.visible = not is_enabled
	_scroll.visible = is_enabled
	# the checkbox shows on the warning too: turning saving on mustn't need a debug run
	# (no signal: this only mirrors the state, it mustn't write settings.cfg again)
	_save_check.set_pressed_no_signal(hall.is_save_enabled)
	# a debug run never saves, whatever the checkbox says
	_save_check.text = CHECK_SAVE_OFF if is_enabled else CHECK_SAVE
	if not is_enabled:
		return

	_skip_button.disabled = not HallDebug.can_skip_day(hall)
	for day: int in _jump_buttons:
		_jump_buttons[day].disabled = not HallDebug.can_jump_to(hall, day)
	_hero_button.disabled = not CharacterContainer.has_free_bed()
	_tutorial_button.disabled = not (hall.tutorial and hall.tutorial.is_running())


## A paper tool button added to `grid` (used for the step buttons built from
## HallDebug's tables). Returns the button so its signal can be connected.
func _make_button(grid: GridContainer, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = BUTTON_HEIGHT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HallStyle.style_button(button, "paper", BUTTON_FONT_SIZE)
	grid.add_child(button)
	return button


## Check for update: ask the live site which build it serves. The button
## reads "Checking…" (and can't be tapped again) until the answer comes back.
func _on_update_pressed() -> void:
	_update_button.disabled = true
	_update_button.text = BUTTON_UPDATE_CHECKING
	HallWebUpdate.check_latest(self, _on_update_checked)


## check_latest's answer: a toast, or the update popup for a newer build.
## result: a HallWebUpdate.CheckResult. latest_stamp: the site's build stamp.
func _on_update_checked(result: HallWebUpdate.CheckResult, latest_stamp: String) -> void:
	_update_button.disabled = false
	_update_button.text = BUTTON_UPDATE
	match result:
		HallWebUpdate.CheckResult.UP_TO_DATE:
			hall.show_toast(TOAST_UP_TO_DATE)
		HallWebUpdate.CheckResult.UPDATE_AVAILABLE:
			# Debug tools may have been closed while the check ran
			if is_visible_in_tree():
				_update_confirm.open(HallBuildInfo.stamp(), latest_stamp)
		HallWebUpdate.CheckResult.NOT_WEB:
			hall.show_toast(TOAST_NOT_WEB)
		_:
			hall.show_toast(TOAST_CHECK_FAILED)


## Tapping the dimmed background closes Debug tools and the Menu.
func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hall.close_debug(false)
