## Recruit card face: big portrait, stats, first line of backstory.
## Swipe right to hire, left to pass.
## Scene: MobileDeck/Scenes/Cards/card_hire.tscn
extends VBoxContainer

const S := preload("res://MobileDeck/Scripts/deck_style.gd")
const Main := preload("res://MobileDeck/Scripts/deck_main.gd")

# ---- TEXT
const TEXT_ROLE := "the %s"
const TEXT_HINT := "Swipe right to hire, left to pass.\nRoom for %d more in your guild."

# ---- NODES
@onready var _portrait = %Portrait
@onready var _char_name: Label = %CharName
@onready var _role: Label = %Role
@onready var _stats = %Stats
@onready var _story: Label = %Story
@onready var _hint: Label = %Hint
@onready var _full_note: Label = %FullNote

var ui: Main


func setup(main: Main) -> void:
	ui = main


func refresh() -> void:
	var c: GuildCharacter = ui.current().character
	_portrait.show_character(c)
	_char_name.text = c.name
	_role.text = TEXT_ROLE % S.role_name(c)
	_stats.show_stats(c)
	_story.text = c.description.strip_edges().split("\n")[0]
	# room left: swipe hint; guild full: the "swipe left to pass" note instead
	_hint.visible = ui.room() > 0
	_full_note.visible = ui.room() <= 0
	_hint.text = TEXT_HINT % ui.room()
