## One quest slip on the Quests tab.
## Open quests show empty slots + Deny / Accept; accepted ones show the party
## + Edit / Cancel (and a gold "ready" frame).
## Scene: MobileLedger/Scenes/Rows/quest_card.tscn
extends PanelContainer

const S := preload("res://MobileLedger/Scripts/ledger_style.gd")
const Main := preload("res://MobileLedger/Scripts/ledger_main.gd")
const Portrait := preload("res://MobileLedger/Scenes/Components/portrait.tscn")
const SlotDashed := preload("res://MobileLedger/Scenes/Components/slot_dashed.tscn")

## Width given to each empty slot in the tappable slot area.
const SLOT_WIDTH := 90
const PARTY_PORTRAIT_SIZE := 76

# ---- TEXT
const TEXT_MILESTONE := "Milestone"
const TEXT_TYPE_GOLD := "[color=#6B5537]%s ·[/color] [b]%d Gold[/b]"
const TEXT_SOLO := "1 adventurer (solo)"
const TEXT_UP_TO := "Up to %d adventurers"
const TEXT_SUCCESS := "Success: [b][color=#%s]%s[/color][/b]"
const TEXT_CHANCE := "%d%% · %s"
const TEXT_NO_CHANCE := "--"

# ---- NODES
@onready var _seal = %Seal
@onready var _quest_title: Label = %QuestTitle
@onready var _type_gold: RichTextLabel = %TypeGold
@onready var _party_size: Label = %PartySize
@onready var _fav_chip = %FavChip
@onready var _success: RichTextLabel = %Success
@onready var _picture: TextureRect = %Picture
# accepted
@onready var _ready_group: Control = %ReadyGroup
@onready var _party_portraits: Container = %PartyPortraits
@onready var _party_names: Label = %PartyNames
@onready var _edit_button: Button = %EditButton
@onready var _cancel_button: Button = %CancelButton
# still open
@onready var _open_group: Control = %OpenGroup
@onready var _pick_tap: Button = %PickTap
@onready var _slots: Container = %Slots
@onready var _deny_button: Button = %DenyButton
@onready var _accept_button: Button = %AcceptButton


func setup(ui: Main, e: Dictionary) -> void:
	var accepted: bool = e.state == "ready"
	add_theme_stylebox_override("panel", S.panel_box("ready" if accepted else "card", Vector4(22, 20, 22, 18)))
	_show_quest(ui, e)
	_ready_group.visible = accepted
	_open_group.visible = not accepted
	if accepted:
		_show_party(ui, e)
	else:
		_show_open(ui, e)


func _show_quest(ui: Main, e: Dictionary) -> void:
	var q: CreatedQuest = e.quest
	var key := S.type_key(e)
	var n: int = ui.slot_count(e)
	_seal.set_rank(S.rank_letter(q), e.milestone)
	_quest_title.text = q.questTitle
	S.color(_quest_title, S.TYPE_COLORS[key])
	var type_name: String = TEXT_MILESTONE if e.milestone else S.TYPE_NAMES.get(int(q.type), "Quest")
	_type_gold.text = TEXT_TYPE_GOLD % [type_name, q.goldReward]
	_party_size.text = TEXT_SOLO if n == 1 else TEXT_UP_TO % n
	var st: Dictionary = S.STATS[S.favored_index(q)]
	_fav_chip.set_icon_chip(st.icon, st.name, st.bg, st.color)
	var chance: int = ui.chance_for(e, e.party)
	var o: Array = S.odds(chance)
	var chance_text := TEXT_NO_CHANCE if chance < 0 else TEXT_CHANCE % [mini(chance, 100), o[0]]
	_success.text = TEXT_SUCCESS % [o[1].to_html(false), chance_text]
	_picture.texture = S.tex(S.TYPE_SCENES[key])


func _show_party(ui: Main, e: Dictionary) -> void:
	for c in e.party:
		var p := Portrait.instantiate()
		p.custom_minimum_size = Vector2.ONE * PARTY_PORTRAIT_SIZE
		_party_portraits.add_child(p)
		p.show_character(c)
	_party_names.text = S.names(e.party)
	_edit_button.pressed.connect(ui.open_charter.bind(e))
	_cancel_button.pressed.connect(ui.cancel.bind(e))


## One dashed "+" slot per adventurer; tapping them opens the charter too.
func _show_open(ui: Main, e: Dictionary) -> void:
	var n: int = ui.slot_count(e)
	for i in n:
		_slots.add_child(SlotDashed.instantiate())
	_pick_tap.custom_minimum_size.x = n * SLOT_WIDTH
	_pick_tap.pressed.connect(ui.open_charter.bind(e))
	_deny_button.pressed.connect(ui.deny.bind(e))
	_accept_button.pressed.connect(ui.open_charter.bind(e))
