## Gold popup: drops from the header's coin when it's tapped. Shows the
## guild's gold, what gold is, what tonight's quests could pay (if they all
## win, and about how much at today's odds), and where gold can be spent:
## hiring, gear and building upgrades, each with a price tag that's green
## when the guild can pay it. A red note shows when tomorrow's recruits cost
## more than the gold in hand (HallLedger.is_short_of_recruit_gold).
## Scene: MobileHall/Scenes/Shell/popup_gold.tscn
extends HeaderPopup


# ============================================================ TEXT

const TITLE := "GOLD"
const DESCRIPTION := "Your guild's purse. Quests pay it at dawn; spend it to grow the guild."
## The earnings box.
const EARN_LABEL := "Tonight, if every quest wins"
const EARN_LABEL_NONE := "Tonight"
const EARN_VALUE := "+%d"
const EARN_SENT := "%s sent · about +%d at today's odds"
const EARN_OPEN := " · %d still on the board"
const EARN_NONE_OPEN := "No quests sent yet. %s on the board could pay up to %d."
const EARN_NONE := "No quests are going out tonight."
## The spending rows: what, where (the tab), and price tags.
const SPEND_HEADING := "WHERE TO SPEND IT"
const HIRE_NAME := "Hire a hero"
const HIRE_WHERE := "Guild tab · more hands for more quests"
const HIRE_WHERE_BLOCKED := "Guild tab · none will come at this standing"
const GEAR_NAME := "Buy gear"
const GEAR_WHERE := "Shop tab · raises a hero's quest stats"
const GEAR_WHERE_SOLD_OUT := "Shop tab · sold out until tomorrow"
const UPGRADE_NAME := "Upgrade a building"
const UPGRADE_WHERE := "Upgrades tab · training, healing, more room"
const UPGRADE_WHERE_STANDING := "Upgrades tab · needs more standing first"
const UPGRADE_WHERE_DONE := "Upgrades tab · every building is maxed"
const PRICE := "%d"
const PRICE_FROM := "from %d"
const PRICE_FREE := "free"
const PRICE_NONE := "—"
## The red note when recruits are out of reach.
const WARNING_SHORT := "Recruits cost %d gold and you have %d. Lose your last hero and the guild falls."


# ============================================================ NODES

@onready var _title: Label = %Title
@onready var _value: Label = %Value
@onready var _description: Label = %Description
@onready var _earn_box: PanelContainer = %EarnBox
@onready var _earn_label: Label = %EarnLabel
@onready var _earn_value: Label = %EarnValue
@onready var _earn_detail: Label = %EarnDetail
@onready var _warning: PanelContainer = %Warning
@onready var _warning_text: Label = %WarningText
@onready var _spend_heading: Label = %SpendHeading
@onready var _hire_name: Label = %HireName
@onready var _hire_where: Label = %HireWhere
@onready var _hire_price: Label = %HirePrice
@onready var _gear_name: Label = %GearName
@onready var _gear_where: Label = %GearWhere
@onready var _gear_price: Label = %GearPrice
@onready var _upgrade_name: Label = %UpgradeName
@onready var _upgrade_where: Label = %UpgradeWhere
@onready var _upgrade_price: Label = %UpgradePrice


func _ready() -> void:
	super()
	_title.text = TITLE
	_description.text = DESCRIPTION
	_spend_heading.text = SPEND_HEADING
	_hire_name.text = HIRE_NAME
	_gear_name.text = GEAR_NAME
	_upgrade_name.text = UPGRADE_NAME
	_earn_box.add_theme_stylebox_override("panel", HallStyle.flat_box(HallStyle.NEUTRAL_BG, 8, 2, HallStyle.BORDER, Vector4(16, 10, 16, 10)))
	_warning.add_theme_stylebox_override("panel", HallStyle.flat_box(HallStyle.RED_BG, 6))
	HallStyle.set_font_color(_warning_text, HallStyle.RED)


func refresh() -> void:
	var gold: int = GameState.gold
	_value.text = str(gold)
	_refresh_earnings()

	var recruit_price := HallWallet.recruit_price()
	var tomorrow_price := GuildCharacter.recruit_cost_for_day(GameState.day + 1)
	_warning.visible = HallLedger.is_short_of_recruit_gold()
	_warning_text.text = WARNING_SHORT % [tomorrow_price, gold]

	# hire: today's recruit price (none come once standing hits the floor)
	var is_blocked := HallWallet.are_recruits_blocked()
	_hire_where.text = HIRE_WHERE_BLOCKED if is_blocked else HIRE_WHERE
	_set_price(_hire_price, PRICE_FREE if recruit_price == 0 else PRICE % recruit_price, not is_blocked and gold >= recruit_price)

	# gear: the cheapest item still in today's stock
	var gear_price := HallWallet.cheapest_gear_price()
	_gear_where.text = GEAR_WHERE if gear_price >= 0 else GEAR_WHERE_SOLD_OUT
	_set_price(_gear_price, PRICE_FROM % gear_price if gear_price >= 0 else PRICE_NONE, gear_price >= 0 and gold >= gear_price)

	# upgrades: the cheapest next building level
	var upgrade := HallWallet.cheapest_upgrade()
	if upgrade.is_empty():
		_upgrade_where.text = UPGRADE_WHERE_DONE
		_set_price(_upgrade_price, PRICE_NONE, false)
	else:
		_upgrade_where.text = UPGRADE_WHERE_STANDING if upgrade.standing_short else UPGRADE_WHERE
		_set_price(_upgrade_price, PRICE_FROM % upgrade.gold, not upgrade.standing_short and gold >= upgrade.gold)


## The earnings box: what the sent quests pay if they all win, about how much
## at today's odds, and how many quests still wait on the board.
func _refresh_earnings() -> void:
	var earnings := HallWallet.tonight_earnings(hall.quest_entries)
	var has_sent: bool = earnings.sent_count > 0
	_earn_label.text = EARN_LABEL if has_sent else EARN_LABEL_NONE
	_earn_value.text = EARN_VALUE % earnings.best
	HallStyle.set_font_color(_earn_value, HallStyle.GREEN_TEXT if has_sent else HallStyle.TEXT_SOFT)
	var quest_count := HallStyle.count_text(earnings.sent_count, "quest", "quests")
	if has_sent:
		_earn_detail.text = EARN_SENT % [quest_count, earnings.expected]
		if earnings.open_count > 0:
			_earn_detail.text += EARN_OPEN % earnings.open_count
	elif earnings.open_count > 0:
		_earn_detail.text = EARN_NONE_OPEN % [HallStyle.count_text(earnings.open_count, "quest", "quests"), earnings.open_best]
	else:
		_earn_detail.text = EARN_NONE


## A price tag: green when the guild can pay it, plain otherwise.
func _set_price(tag: Label, text: String, can_pay: bool) -> void:
	tag.text = text
	var panel := tag.get_parent() as PanelContainer
	panel.add_theme_stylebox_override("panel", HallStyle.flat_box(HallStyle.GREEN_BG if can_pay else HallStyle.NEUTRAL_BG, 6, 0, HallStyle.BORDER, Vector4(12, 2, 12, 2)))
	HallStyle.set_font_color(tag, HallStyle.GREEN_TEXT if can_pay else HallStyle.TEXT_SOFT)
