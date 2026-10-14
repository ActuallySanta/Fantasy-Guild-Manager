## Settings tab: help, plus the upgrades page's debug buttons (when enabled).
extends VBoxContainer

var ui


func setup(main) -> void:
	ui = main
	%WelcomeButton.pressed.connect(func():
		ui.show_welcome = true
		ui.queue_refresh())
	%AddGoldButton.pressed.connect(GuildUpgrades.add_gold.bind(200))
	%AddStandingButton.pressed.connect(GuildUpgrades.add_standing.bind(1))
	%ResetButton.pressed.connect(func():
		GuildUpgrades.reset()
		ui.toast("Upgrades reset"))


func refresh() -> void:
	%Debug.visible = GuildUpgrades.SHOW_DEBUG_BUTTONS
