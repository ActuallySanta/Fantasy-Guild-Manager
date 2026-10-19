## Guild tab: two clearly separate halves, "Your Guild" (the roster) and
## "For Hire" (today's recruits), switched with the buttons at the top. The
## For Hire button shows how many new recruits arrived this morning. A line
## under them shows beds used and links to the Barracks upgrade.
## Scene: MobileHall/Scenes/Tabs/tab_guild.tscn
extends VBoxContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const MemberCard := preload("res://MobileHall/Scenes/Rows/member_card.tscn")
const HireCard := preload("res://MobileHall/Scenes/Rows/hire_card.tscn")

# ---- TEXT
const SEG_ROSTER := "Your Guild %d/%d"
const SEG_HIRE := "For Hire"
const BEDS := "Beds: %d of %d used · Barracks level %d"
const BEDS_FULL := "All %d beds are taken. Upgrade the Barracks for more."
const BEDS_BUTTON := "Barracks"
const EMPTY_ROSTER := "Nobody here yet. Hire someone from For Hire."
const EMPTY_HIRE := "No recruits left today. New faces arrive every morning."
const HIRE_NOTE := "Hiring is free. New recruits arrive every morning."
const LOW_STANDING := "Your guild is too unpopular, and has thus failed to attract new talent"

# ---- NODES
@onready var _seg_roster: Button = %SegRoster
@onready var _seg_hire: Button = %SegHire
@onready var _hire_badge: Control = %HireBadge
@onready var _hire_badge_text: Label = %HireBadgeText
@onready var _scroll: ScrollContainer = %Scroll
@onready var _beds: Label = %Beds
@onready var _beds_button: Button = %BedsButton
@onready var _note: Label = %Note
@onready var _list: VBoxContainer = %List
@onready var _empty: Label = %Empty

var ui


func setup(main) -> void:
	ui = main
	_seg_roster.pressed.connect(func(): ui.set_guild_seg("roster"))
	_seg_hire.pressed.connect(func(): ui.set_guild_seg("hire"))
	_beds_button.pressed.connect(func(): ui.open_tab("upgrades"))
	S.style_button(_beds_button, "paper", 22)


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	_show_segments()
	_show_beds()
	S.clear(_list)
	if ui.guild_seg == "hire":
		_show_hire()
	else:
		_show_roster()


func _show_segments() -> void:
	var hire: bool = ui.guild_seg == "hire"
	_seg_roster.text = SEG_ROSTER % [ui.roster().size(), CharacterContainer.max_characters]
	_seg_hire.text = SEG_HIRE
	S.style_button(_seg_roster, "paper" if hire else "wood", 26)
	S.style_button(_seg_hire, "blue" if hire else "paper", 26)
	var n := CharacterContainer.hireable_characters.size()
	_hire_badge.visible = not hire and n > 0 and not ui.roster_full()
	_hire_badge_text.text = str(n)


func _show_beds() -> void:
	var used: int = ui.roster().size()
	var beds := CharacterContainer.max_characters
	_beds.text = BEDS_FULL % beds if used >= beds else BEDS % [used, beds, GuildUpgrades.get_level(GuildUpgrades.Building.BARRACKS)]
	S.color(_beds, S.WAX if used >= beds else S.INK_SOFT)
	_beds_button.text = BEDS_BUTTON


func _show_roster() -> void:
	_note.visible = false
	for c in ui.roster():
		S.add_row(_list, MemberCard).setup(ui, c)
	_empty.text = EMPTY_ROSTER
	_empty.visible = ui.roster().is_empty()


func _show_hire() -> void:
	_note.visible = true
	_note.text = HIRE_NOTE
	if (GameState.standing > GuildUpgrades.MINIMUM_STANDING):
		for c in CharacterContainer.hireable_characters:
			S.add_row(_list, HireCard).setup(ui, c)
		_empty.text = EMPTY_HIRE
	else:
		_empty.text = LOW_STANDING

	_empty.visible = CharacterContainer.hireable_characters.is_empty()
