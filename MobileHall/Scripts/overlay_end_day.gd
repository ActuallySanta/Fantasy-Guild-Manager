## End Day check: a sheet over the screen before the day ends, showing who goes
## out tonight and, if you can afford any, the upgrades worth buying first.
## (Upgrades were easy to forget in every earlier prototype.)
## Scene: MobileHall/Scenes/Overlays/overlay_end_day.tscn
extends Control

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const PlanRow := preload("res://MobileHall/Scenes/Rows/plan_row.tscn")
const SuggestRow := preload("res://MobileHall/Scenes/Rows/suggest_row.tscn")

# ---- TEXT
const TEXT_TITLE := "End Day %d?"
const TEXT_SUB := "%s going out tonight"
const TEXT_SUB_NONE := "Nobody is going out tonight"
const TEXT_DENIED := "Denied: %s"
const TEXT_UPGRADE_TITLE := "Before you go: you have %d gold"
const BUTTON_BACK := "Not yet"
const BUTTON_END := "End Day"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _plan: VBoxContainer = %PlanList
@onready var _denied: Label = %Denied
@onready var _upgrade_box: Control = %UpgradeBox
@onready var _upgrade_title: Label = %UpgradeTitle
@onready var _suggest: VBoxContainer = %SuggestList
@onready var _back_button: Button = %BackButton
@onready var _end_button: Button = %EndButton

var ui


func setup(main) -> void:
	ui = main
	_back_button.pressed.connect(ui.close_end_check)
	_end_button.pressed.connect(ui.end_day)
	_dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: ui.close_end_check())
	_back_button.text = BUTTON_BACK
	_end_button.text = BUTTON_END
	S.style_button(_back_button, "paper")
	S.style_button(_end_button, "gold")


func refresh() -> void:
	var going: Array = ui.ready_entries()
	_title.text = TEXT_TITLE % GameState.day
	_sub.text = TEXT_SUB % S.count(going.size(), "party", "parties") if not going.is_empty() else TEXT_SUB_NONE
	S.clear(_plan)
	for e in going:
		S.add_row(_plan, PlanRow).setup(ui, e)
	var denied: Array = ui.denied_entries()
	var names := PackedStringArray()
	for e in denied:
		names.append(e.quest.questTitle)
	_denied.text = TEXT_DENIED % ", ".join(names)
	_denied.visible = not denied.is_empty()

	var ups: Array = ui.upgradable()
	_upgrade_box.visible = not ups.is_empty()
	_upgrade_title.text = TEXT_UPGRADE_TITLE % GameState.gold
	S.clear(_suggest)
	for b in ups:
		S.add_row(_suggest, SuggestRow).setup(ui, b)
