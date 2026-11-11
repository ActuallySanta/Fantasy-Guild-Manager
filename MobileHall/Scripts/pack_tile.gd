## One item on the Pack grid (tab_pack.gd), drawn as a goods tag like the
## Shop's: rarity seal, name and what it adds.
## A worn item shows who wears it twice over: the hero's round portrait pinned
## to the tag's corner, and a navy "ON GWEN" ribbon along its foot. A spare
## item says "SPARE" there instead.
## The picked one gets the gold-edged tag (GoodsTagSelected in hall_theme).
## Scene: MobileHall/Scenes/Rows/pack_tile.tscn
extends Button


## The tag's size (design px; width 0 = share the grid row). Grown with the
## font scale, like shop_tile.gd, so the seal, name and ribbon keep fitting.
const TILE_SIZE := Vector2(0, 268)

# ---- TEXT
const BONUS := "+%d %s"
const WORN_RIBBON := "On %s"
const SPARE_NOTE := "Spare"

# ---- NODES
@onready var _tag: PanelContainer = %Tag
@onready var _tag_text: Label = %TagText
@onready var _name: Label = %ItemName
@onready var _bonus: Label = %Bonus
@onready var _ribbon: PanelContainer = %Ribbon
@onready var _ribbon_text: Label = %RibbonText
@onready var _spare_note: Label = %SpareNote
@onready var _medallion: Control = %Medallion


## item: an owned StandardItem. is_selected: the picked tile (gold edge).
## on_pick: called when the tile is tapped.
func setup(item: StandardItem, is_selected: bool, on_pick: Callable) -> void:
	custom_minimum_size = HallFontScale.px_vec(TILE_SIZE)
	var look := HallStyle.item_look(item)
	HallStyle.style_tag(_tag, _tag_text, look.tag, look.color)
	_name.text = look.short
	var bonus := HallGear.item_bonus(item)
	_bonus.visible = bonus.x >= 0
	if bonus.x >= 0:
		_bonus.text = BONUS % [bonus.y, HallStyle.STATS[bonus.x].short]
		HallStyle.set_font_color(_bonus, HallStyle.STATS[bonus.x].color)

	var wearer: GuildCharacter = item.curr_user
	_ribbon.visible = wearer != null
	_spare_note.visible = wearer == null
	_medallion.visible = wearer != null
	_spare_note.text = SPARE_NOTE
	if wearer != null:
		_ribbon_text.text = WORN_RIBBON % wearer.name
		_medallion.show_character(wearer)
		tooltip_text = WORN_RIBBON % wearer.name

	theme_type_variation = &"GoodsTagSelected" if is_selected else &"GoodsTag"
	pressed.connect(on_pick)
