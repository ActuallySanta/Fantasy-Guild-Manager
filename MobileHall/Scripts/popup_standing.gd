## Standing popup: drops from the header's shield when it's tapped. Shows the
## guild's standing, what rank of quests it brings, what standing is, and a
## two-way meter: the red half fills as standing nears the floor where
## recruits stop coming (GuildUpgrades.MINIMUM_STANDING), the green half fills
## toward the next milestone (a quest rank or a building level, HallWallet).
## A red note shows once standing is close to that floor.
## Scene: MobileHall/Scenes/Shell/popup_standing.tscn
extends HeaderPopup


# ============================================================ TEXT

const TITLE := "STANDING"
const RANK_LINE := "Quests center on rank %s"
const DESCRIPTION := "How the realm sees your guild. Winning quests raises it; denying quests or letting heroes go lowers it."
## Under the red half: how much standing can be lost before recruits stop.
const LOSS_AMOUNT := "-%d"
const LOSS_LINE := "until recruits stop"
const LOSS_AMOUNT_GONE := "0"
const LOSS_LINE_GONE := "No recruits will come"
## Under the green half: how much more is needed, and what it unlocks.
const GAIN_AMOUNT := "+%d"
const GAIN_AMOUNT_DONE := "Top"
const GAIN_LINE_DONE := "Every milestone reached"
## What each kind of milestone unlocks (see HallWallet.standing_milestones).
const MILESTONE_RANK_APPEARS := "Rank %s quests appear"
const MILESTONE_RANK := "Rank %s quests"
const MILESTONE_UPGRADE := "Level %d upgrades"
## The red note near the floor (see HallLedger.is_standing_near_floor).
const WARNING_NEAR := "Lose %s more and no new recruits will come."
const WARNING_GONE := "Standing is too low: no new recruits will come until it rises above %d."


# ============================================================ NODES

@onready var _title: Label = %Title
@onready var _value: Label = %Value
@onready var _rank: Label = %Rank
@onready var _description: Label = %Description
@onready var _loss_bar: ProgressBar = %LossBar
@onready var _gain_bar: ProgressBar = %GainBar
@onready var _loss_amount: Label = %LossAmount
@onready var _loss_text: Label = %LossText
@onready var _gain_amount: Label = %GainAmount
@onready var _gain_text: Label = %GainText
@onready var _warning: PanelContainer = %Warning
@onready var _warning_text: Label = %WarningText
@onready var _mark: ColorRect = %Mark


func _ready() -> void:
	super()
	_title.text = TITLE
	_description.text = DESCRIPTION
	_mark.color = HallStyle.TEXT_MAIN
	_style_bar(_loss_bar, HallStyle.RED)
	_style_bar(_gain_bar, HallStyle.GREEN)
	for label in [_loss_amount, _loss_text]:
		HallStyle.set_font_color(label, HallStyle.RED)
	for label in [_gain_amount, _gain_text]:
		HallStyle.set_font_color(label, HallStyle.GREEN_TEXT)
	_warning.add_theme_stylebox_override("panel", HallStyle.flat_box(HallStyle.RED_BG, 6))
	HallStyle.set_font_color(_warning_text, HallStyle.RED)


func refresh() -> void:
	var standing: int = GameState.standing
	_value.text = str(standing)
	_rank.text = RANK_LINE % HallWallet.standing_rank_letter(standing)

	# red half: room left above the floor
	var room := HallWallet.standing_above_floor(standing)
	_loss_bar.value = HallWallet.loss_fill(standing)
	_loss_amount.text = LOSS_AMOUNT % room if room > 0 else LOSS_AMOUNT_GONE
	_loss_text.text = LOSS_LINE if room > 0 else LOSS_LINE_GONE

	# green half: toward the next milestone
	var next := HallWallet.next_standing_milestone(standing)
	_gain_bar.value = HallWallet.gain_fill(standing)
	_gain_amount.text = GAIN_AMOUNT_DONE if next.is_empty() else GAIN_AMOUNT % (next.at - standing)
	_gain_text.text = GAIN_LINE_DONE if next.is_empty() else _milestone_text(next)

	_warning.visible = HallLedger.is_standing_near_floor()
	if room > 0:
		_warning_text.text = WARNING_NEAR % HallStyle.count_text(room, "point", "points")
	else:
		_warning_text.text = WARNING_GONE % GuildUpgrades.MINIMUM_STANDING


## What a milestone from HallWallet.standing_milestones unlocks, in words.
func _milestone_text(milestone: Dictionary) -> String:
	match milestone.kind:
		"rank_appears":
			return MILESTONE_RANK_APPEARS % HallWallet.rank_name(milestone.value)
		"rank":
			return MILESTONE_RANK % HallWallet.rank_name(milestone.value)
		_:
			return MILESTONE_UPGRADE % milestone.value


## A meter half: a parchment track with a solid `fill` color, 0..1.
func _style_bar(bar: ProgressBar, fill: Color) -> void:
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", HallStyle.flat_box(HallStyle.NEUTRAL_BG, 8, 2, HallStyle.BORDER, Vector4.ZERO))
	bar.add_theme_stylebox_override("fill", HallStyle.flat_box(fill, 8, 0, fill, Vector4.ZERO))
