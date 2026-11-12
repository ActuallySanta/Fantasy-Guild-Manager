## End Day check: a sheet over the screen before the day ends, showing who goes
## out tonight and, if you can afford any, the upgrades worth buying first.
## (Upgrades were easy to forget in every earlier prototype.)
## Scene: MobileHall/Scenes/Overlays/overlay_end_day.tscn
extends Control

const PlanRowScene := preload("uid://c2ca1up8vmmc6")  # MobileHall/Scenes/Rows/plan_row.tscn
const SuggestRowScene := preload("uid://bdmft4ngc6x70")  # MobileHall/Scenes/Rows/suggest_row.tscn

# ---- TEXT
const TEXT_TITLE := "End Day %d?"
const TEXT_SUBTITLE := "%s going out tonight"
const TEXT_SUBTITLE_NONE := "Nobody is going out tonight"
const TEXT_DENIED := "Denied: %s"
const TEXT_UPGRADE_TITLE := "Upgrade first? · %d gold"
const BUTTON_BACK := "Not yet"
const BUTTON_END := "End Day"

## SIMPLIFIED: the "2 parties going out tonight" line under the title
## (the "Nobody is going out tonight" warning shows either way).
const SHOW_SUBTITLE := false
## SIMPLIFIED: "· 600 gold" after "Upgrade first?" (the header shows the gold).
const SHOW_UPGRADE_GOLD := false
const TEXT_UPGRADE_TITLE_PLAIN := "Upgrade first?"

# ---- NODES
@onready var _dim: Control = %Dim
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Sub
# Tonight's plan
@onready var _plan_list: VBoxContainer = %PlanList
@onready var _denied_label: Label = %Denied
# Upgrade suggestions
@onready var _upgrade_box: Control = %UpgradeBox
@onready var _upgrade_title: Label = %UpgradeTitle
@onready var _suggest_list: VBoxContainer = %SuggestList
# Buttons
@onready var _back_button: Button = %BackButton
@onready var _end_button: Button = %EndButton

## The main hall script (state + actions), set in setup().
var hall: HallMain


func setup(main: HallMain) -> void:
	hall = main
	_back_button.pressed.connect(hall.close_end_check)
	_end_button.pressed.connect(hall.end_day)
	_dim.gui_input.connect(_on_dim_input)
	_back_button.text = BUTTON_BACK
	_end_button.text = BUTTON_END
	HallStyle.style_button(_back_button, "paper", 28)
	HallStyle.style_button(_end_button, "green", 32)


func refresh() -> void:
	# End Day was pressed and the night has already played out, so the sheet
	# keeps tonight's plan as it was while the dusk falls over it
	if hall.is_night_falling:
		return
	_title.text = TEXT_TITLE % GameState.day
	_show_tonights_plan()
	_show_upgrade_suggestions()


## One row per party going out, then the denied quests on one line.
func _show_tonights_plan() -> void:
	var sent: Array = hall.sent_entries()
	if sent.is_empty():
		_subtitle.text = TEXT_SUBTITLE_NONE
	else:
		_subtitle.text = TEXT_SUBTITLE % HallStyle.count_text(sent.size(), "party", "parties")
	# "Nobody is going out tonight" still shows: it warns about a wasted day
	_subtitle.visible = SHOW_SUBTITLE or sent.is_empty()
	HallStyle.clear_children(_plan_list)
	for entry in sent:
		HallStyle.add_row(_plan_list, PlanRowScene).setup(hall, entry)

	var denied: Array = hall.denied_entries()
	var denied_titles := PackedStringArray()
	for entry in denied:
		denied_titles.append(entry.quest.questTitle)
	_denied_label.text = TEXT_DENIED % ", ".join(denied_titles)
	_denied_label.visible = not denied.is_empty()


## Buy buttons for every building that can be upgraded right now.
func _show_upgrade_suggestions() -> void:
	var affordable: Array = hall.affordable_buildings()
	_upgrade_box.visible = not affordable.is_empty()
	_upgrade_title.text = TEXT_UPGRADE_TITLE % GameState.gold if SHOW_UPGRADE_GOLD else TEXT_UPGRADE_TITLE_PLAIN
	HallStyle.clear_children(_suggest_list)
	for building in affordable:
		HallStyle.add_row(_suggest_list, SuggestRowScene).setup(hall, building)


## Tapping the dimmed background closes the sheet.
func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hall.close_end_check()
