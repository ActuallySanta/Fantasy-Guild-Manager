## One adventurer in Assign Party's picker: portrait, health, the four quest
## stats (favored one outlined), how much they'd add to the odds, and which
## quest they're already on. Tap to add / remove; "i" opens their details.
## Scene: MobileHall/Scenes/Rows/pick_row.tscn
extends "res://MobileHall/Scripts/tap_panel.gd"

const S := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- TEXT
const TEXT_ADD := "+%d%%"
const TEXT_ADD_SUB := "to odds"
const TEXT_IN := "Added"
const TEXT_IN_SUB := "in party"
const TEXT_ON_DRAFT := "Picked for %s"
const TEXT_ON_SENT := "Sent on %s"
const TEXT_ROLE := "the %s"
const TEXT_CANT := "Can't go"

# ---- NODES
@onready var _portrait = %Portrait
@onready var _name: Label = %Name
@onready var _role: Label = %Role
@onready var _health = %HealthChip
@onready var _stats = %Stats
@onready var _where: Label = %Where
@onready var _add: Label = %AddValue
@onready var _add_sub: Label = %AddSub
@onready var _info_button: Button = %InfoButton


func setup(main, e: Dictionary, c: GuildCharacter) -> void:
	pressed.connect(main.toggle_pick.bind(c))
	_info_button.pressed.connect(main.open_character.bind(c))
	_portrait.show_character(c)
	_name.text = c.name
	_role.text = TEXT_ROLE % S.role_name(c)
	_health.set_health(c)
	_stats.show_stats(c, S.favored_index(e.quest), false)
	_show_where(main, e, c)
	_show_pick(main, e, c)


## "Picked for Escort..." when they're in another quest's party.
func _show_where(main, e: Dictionary, c: GuildCharacter) -> void:
	var i: int = main.entry_index_of(c)
	var other: Dictionary = main.entries[i] if i >= 0 else {}
	_where.visible = i >= 0 and other != e
	if _where.visible:
		_where.text = (TEXT_ON_SENT if other.state == "ready" else TEXT_ON_DRAFT) % ("#%d %s" % [i + 1, other.quest.questTitle])
		S.color(_where, S.GREEN_TEXT if other.state == "ready" else S.BLUE_TEXT)


func _show_pick(main, e: Dictionary, c: GuildCharacter) -> void:
	var picked: bool = e.party.has(c)
	if picked:
		_add.text = TEXT_IN
		_add_sub.text = TEXT_IN_SUB
		S.color(_add, S.GREEN_TEXT)
		S.style_panel(self, Color("#E8F5E9"), S.GREEN, 4, 16)
	elif S.is_dead(c):
		_add.text = "-"
		_add_sub.text = TEXT_CANT
		S.color(_add, S.INK_SOFT)
		S.style_panel(self, Color("#EEEEEE"), S.LINE, 2, 16)
		modulate = Color(1, 1, 1, 0.6)
	else:
		var add: int = main.chance_added(e, c)
		_add.text = TEXT_ADD % mini(add, 100)
		_add_sub.text = TEXT_ADD_SUB
		S.color(_add, S.odds(add)[1])
		S.style_panel(self, S.CREAM, S.LINE, 2, 16)
