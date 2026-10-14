## Characters tab: "Your Guild" (the roster) and "For Hire" (today's recruits),
## as two clearly different halves switched by the buttons at the top.
## Scene: MobileLedger/Scenes/Pages/page_characters.tscn
extends VBoxContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")
const RosterCard := preload("res://MobileLedger/Scenes/Rows/roster_card.tscn")
const HireCard := preload("res://MobileLedger/Scenes/Rows/hire_card.tscn")
const EmptyBunk := preload("res://MobileLedger/Scenes/Rows/empty_bunk.tscn")

# ---- TEXT
const TEXT_GUILD_SEG := "Your Guild  %d/%d"
const TEXT_HIRE_SEG := "For Hire  ·  %d"
const TEXT_ROOM := "Hiring is free. Room for %d more. New faces arrive every morning."
const TEXT_FULL := "Your guild is full (%d/%d). Upgrade the Barracks for more room."

# ---- NODES
@onready var _guild_seg_button: Button = %GuildSegButton
@onready var _hire_seg_button: Button = %HireSegButton
@onready var _guild_page: Control = %GuildPage
@onready var _roster_list: Container = %RosterList
@onready var _empty_guild: Control = %EmptyGuild
@onready var _see_hires_button: Button = %SeeHiresButton
@onready var _bunks: Container = %Bunks
@onready var _hire_page: Control = %HirePage
@onready var _hire_note: Label = %HireNote
@onready var _hire_list: Container = %HireList
@onready var _hire_empty: Control = %HireEmpty

var ui: Main


func setup(main: Main) -> void:
	ui = main
	_guild_seg_button.pressed.connect(func(): ui.set_segment("guild"))
	_hire_seg_button.pressed.connect(func(): ui.set_segment("hire"))
	_see_hires_button.pressed.connect(func(): ui.set_segment("hire"))


func refresh() -> void:
	_show_switch()
	_guild_page.visible = ui.seg == "guild"
	_hire_page.visible = ui.seg != "guild"
	if ui.seg == "guild":
		_show_guild()
	else:
		_show_hires()


## The two halves' buttons: the open one is red, the other paper.
func _show_switch() -> void:
	_guild_seg_button.text = TEXT_GUILD_SEG % [CharacterContainer.active_characters.size(), CharacterContainer.max_characters]
	_hire_seg_button.text = TEXT_HIRE_SEG % CharacterContainer.hireable_characters.size()
	for pair in [[_guild_seg_button, "guild"], [_hire_seg_button, "hire"]]:
		var b: Button = pair[0]
		var on: bool = ui.seg == pair[1]
		S.style_button(b, "red" if on else "paper", 27)
		b.add_theme_constant_override("icon_max_width", 34)
		for s in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
			b.add_theme_color_override(s, S.WHITE if on else S.INK)


## Roster cards, then an "Empty bunk" per free place (or the empty-guild card).
func _show_guild() -> void:
	var roster: Array = CharacterContainer.active_characters
	S.clear(_roster_list)
	for c in roster:
		S.add_row(_roster_list, RosterCard).setup(ui, c)
	_empty_guild.visible = roster.is_empty()
	S.clear(_bunks)
	if roster.is_empty():
		return
	for i in maxi(0, CharacterContainer.max_characters - roster.size()):
		S.add_row(_bunks, EmptyBunk)


func _show_hires() -> void:
	var roster_size := CharacterContainer.active_characters.size()
	var cap := CharacterContainer.max_characters
	var full := roster_size >= cap
	_hire_note.text = TEXT_FULL % [roster_size, cap] if full else TEXT_ROOM % (cap - roster_size)
	var hires: Array = CharacterContainer.hireable_characters
	S.clear(_hire_list)
	for c in hires:
		S.add_row(_hire_list, HireCard).setup(ui, c, full)
	_hire_empty.visible = hires.is_empty()
