## One hero in the Equip picker (overlay_equip_picker.gd): round portrait,
## name and role, how full their gear slots are, what the item would change
## ("Sleaziness 28 → 58"), and Equip (a free slot) or Swap… (slots full).
## Scene: MobileHall/Scenes/Rows/equip_pick_row.tscn
extends PanelContainer


# ---- TEXT
const NAME_LINE := "%s · %s"
const SLOTS_LINE := "%d of %d gear slots used"
const SLOTS_FULL := "Gear slots full"
const CHANGE_LINE := "%s %d → %d"

# ---- NODES
@onready var _portrait: Control = %Portrait
@onready var _name: Label = %HeroName
@onready var _slots: Label = %Slots
@onready var _change: Label = %Change
@onready var _button: Button = %ActionButton


## character: a hero who can wear the item. change: one entry of
## HallGear.preview() for putting the item on ({} = it changes no stat).
## button_text / button_kind: HallStyle.style_button. on_press: the button's action.
func setup(character: GuildCharacter, change: Dictionary, button_text: String, button_kind: String, on_press: Callable) -> void:
	_portrait.show_character(character)
	_name.text = NAME_LINE % [character.name, HallStyle.role_name(character)]
	var used := character.equipped_items.size()
	_slots.text = SLOTS_LINE % [used, character.max_items] if HallGear.has_free_slot(character) else SLOTS_FULL
	_change.visible = not change.is_empty()
	if not change.is_empty():
		_change.text = CHANGE_LINE % [HallStyle.STATS[change.stat].name, change.before, change.after]
		HallStyle.set_font_color(_change, HallStyle.GREEN_TEXT if change.after > change.before else HallStyle.RED)
	_button.text = button_text
	HallStyle.style_button(_button, button_kind, 26)
	_button.pressed.connect(on_press)
