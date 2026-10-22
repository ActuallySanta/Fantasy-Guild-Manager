## Guild tab: a folder with two tabs, "Your Guild" (the roster) and
## "Applicants" (today's recruits). Applicants come as a stack of letters: the
## top one is read in full, the ones under it peek out and come to the top
## when tapped. The Applicants tab shows how many arrived this morning. A line
## at the top shows beds used and links to the Barracks upgrade.
## Scene: MobileHall/Scenes/Tabs/tab_guild.tscn
extends VBoxContainer

const S := preload("res://MobileHall/Scripts/hall_style.gd")
const MemberCard := preload("res://MobileHall/Scenes/Rows/member_card.tscn")
const HireCard := preload("res://MobileHall/Scenes/Rows/hire_card.tscn")
const HirePeek := preload("res://MobileHall/Scenes/Rows/hire_peek.tscn")

## How many letters peek out under the top one, and their small tilts (degrees).
const PEEKS := 2
const PEEK_TILT := [0.6, -0.5]

# ---- TEXT
const SEG_ROSTER := "Your Guild · %d/%d"
const SEG_HIRE := "Applicants"
const BEDS := "Beds %d of %d · Barracks Lv %d"
const BEDS_FULL := "All %d beds are taken. Upgrade the Barracks for more."
const BEDS_BUTTON := "Barracks"
const EMPTY_ROSTER := "Nobody here yet. Hire someone from Applicants."
const EMPTY_HIRE := "No applicants left today. New faces arrive every morning."
const HIRE_NOTE := "Hiring is free. New applicants arrive every morning."
const LOW_STANDING := "Your guild is too unpopular, and has thus failed to attract new talent"
const PEEK := "%s · %s"

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
@onready var _stack: VBoxContainer = %Stack
@onready var _empty: Label = %Empty

var ui
## Which applicant's letter is on top of the stack.
var _top := 0


func setup(main) -> void:
	ui = main
	_seg_roster.pressed.connect(func(): ui.set_guild_seg("roster"))
	_seg_hire.pressed.connect(func(): ui.set_guild_seg("hire"))
	_beds_button.pressed.connect(func(): ui.open_tab("upgrades"))
	_beds_button.text = BEDS_BUTTON


func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func refresh() -> void:
	_show_segments()
	_show_beds()
	S.clear(_list)
	S.clear(_stack)
	if ui.guild_seg == "hire":
		_show_hire()
	else:
		_show_roster()


## The open folder tab is the lighter one that joins the folder below.
func _show_segments() -> void:
	var hire: bool = ui.guild_seg == "hire"
	_seg_roster.text = SEG_ROSTER % [ui.roster().size(), CharacterContainer.max_characters]
	_seg_hire.text = SEG_HIRE
	_seg_roster.theme_type_variation = &"FolderTab" if hire else &"FolderTabActive"
	_seg_hire.theme_type_variation = &"FolderTabActive" if hire else &"FolderTab"
	_seg_roster.custom_minimum_size.y = 72 if hire else 80
	_seg_hire.custom_minimum_size.y = 80 if hire else 72
	var n := CharacterContainer.hireable_characters.size()
	_hire_badge.visible = not hire and n > 0 and not ui.roster_full()
	_hire_badge_text.text = str(n)


func _show_beds() -> void:
	var used: int = ui.roster().size()
	var beds := CharacterContainer.max_characters
	_beds.text = BEDS_FULL % beds if used >= beds else BEDS % [used, beds, GuildUpgrades.get_level(GuildUpgrades.Building.BARRACKS)]
	S.color(_beds, Color("#F2B8A8") if used >= beds else S.CREAM)


func _show_roster() -> void:
	_note.visible = false
	for c in ui.roster():
		S.add_row(_list, MemberCard).setup(ui, c)
	_empty.text = EMPTY_ROSTER
	_empty.visible = ui.roster().is_empty()


func _show_hire() -> void:
	_note.visible = true
	_note.text = HIRE_NOTE
	var hireable: Array = CharacterContainer.hireable_characters
	_empty.visible = hireable.is_empty()
	_empty.text = EMPTY_HIRE
	if GameState.standing <= GuildUpgrades.MINIMUM_STANDING:
		_empty.text = LOW_STANDING
		_empty.visible = true
		return
	if hireable.is_empty():
		return
	_top = clampi(_top, 0, hireable.size() - 1)
	var top_card := S.add_row(_stack, HireCard)
	top_card.z_index = PEEKS + 1
	top_card.setup(ui, hireable[_top], _top)
	# the next applicants peek out underneath, each a little further back
	for k in mini(PEEKS, hireable.size() - 1):
		var i := (_top + 1 + k) % hireable.size()
		var c: GuildCharacter = hireable[i]
		var peek := S.add_row(_stack, HirePeek)
		peek.z_index = PEEKS - k
		peek.rotation_degrees = PEEK_TILT[k]
		peek.get_node("Text").text = PEEK % [c.name, S.role_name(c)]
		peek.pressed.connect(_bring_to_top.bind(i))


func _bring_to_top(i: int) -> void:
	_top = i
	ui.queue_refresh()
