## Action bar: one torn banner over the nav with a title, an optional hint, and
## one big gold button for the next thing to do (hire someone -> decide the
## next quest -> end the day). Hidden on screens, which put their own buttons
## in this spot, and on the Shop tab, whose Buy bar sits here.
## Scene: MobileHall/Scenes/Shell/hall_action_bar.tscn
class_name HallActionBar
extends PanelContainer


# ============================================================ TEXT

const ACTION_HIRE := "Hire your first adventurer"
const ACTION_HIRE_BUTTON := "For Hire"
const ACTION_DECIDE := "%s to decide"
const ACTION_DECIDE_BUTTON := "Next Quest"
const ACTION_END := "Ready to end Day %d"
const ACTION_END_HINT := "%s going out tonight"
const ACTION_END_HINT_NONE := "No parties going out tonight"
const ACTION_END_BUTTON := "End Day"


# ============================================================ STATE

## The main hall script (state + actions), set in setup().
var hall: HallMain

## The last title shown (the text fades in and the button pops when it changes).
var _shown_title := ""


# ============================================================ NODES

@onready var _title: Label = %ActionTitle
@onready var _hint: Label = %ActionHint
@onready var _button: Button = %ActionButton


# ============================================================ SETUP AND REFRESH

func setup(main: HallMain) -> void:
	hall = main
	_button.pressed.connect(hall.do_next_step)


## The big button, for Pip to point at.
func button() -> Button:
	return _button


func refresh() -> void:
	# screens put their own buttons in this spot (Deny / Send, Back / Hire),
	# and so does the Shop tab (its Buy bar)
	visible = hall.active_screen.is_empty() and hall.active_tab != HallMain.TAB_SHOP

	if hall.roster().is_empty() and hall.can_hire_anyone():
		_set_action(ACTION_HIRE, "", ACTION_HIRE_BUTTON)
	elif hall.undecided_count() > 0:
		var title := ACTION_DECIDE % HallStyle.count_text(hall.undecided_count(), "quest", "quests")
		_set_action(title, "", ACTION_DECIDE_BUTTON)
	else:
		var parties_going := hall.sent_entries().size()
		var hint := ACTION_END_HINT % HallStyle.count_text(parties_going, "party", "parties") if parties_going > 0 else ACTION_END_HINT_NONE
		_set_action(ACTION_END % GameState.day, hint, ACTION_END_BUTTON)


## The torn banner's title, hint ("" hides it) and gold button (its look is set
## in the scene). When the next step changes, its text fades in and the button pops.
func _set_action(title: String, hint: String, button_text: String) -> void:
	_title.text = title
	_hint.text = hint
	_hint.visible = hint != ""
	_button.text = button_text
	if title != _shown_title:
		if _shown_title != "" and visible:
			HallFx.fade_in(_title.get_parent(), 0.0, 0.25)
			HallFx.pop(_button, 1.1)
		_shown_title = title
