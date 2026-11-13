## A small ink label, optionally with an icon and an outline.
## Used for stats, health, gold, rank, party size and other short facts.
## The outline is white art (Styles/pill.tres or ink_box.tres) tinted the ink colour.
## Stats and health are filled pills instead: the paper tint behind the ink.
## Scene: MobileHall/Scenes/Components/chip.tscn
extends PanelContainer


## Border of a filled pill, in pixels: the quest's favored stat gets a heavy
## one, every other filled chip a thin one.
const FILLED_BORDER := 2
const FAVORED_BORDER := 4

# ---- NODES
@onready var _icon: TextureRect = $Row/Icon
@onready var _label: Label = $Row/Text


## icon_name = a name from hall_style ICON_FILES ("" or unknown = no icon).
## outlined = a rounded outline in the text colour (the quest's favored stat).
## background is no longer drawn (chips are ink on paper); it's kept so older
## callers still work.
func set_chip(text: String, _background: Color, text_color: Color, icon_name: String = "", outlined: bool = false) -> void:
	_set_ink(text, text_color, icon_name, &"Pill" if outlined else &"")


## Text in a square ink outline ("RANK F", the report's totals).
func set_box(text: String, text_color: Color, icon_name: String = "") -> void:
	_set_ink(text, text_color, icon_name, &"InkBox")


## Text on a filled pill: `fill` behind, `ink` for the text, icon and border.
## border_width in pixels (FILLED_BORDER / FAVORED_BORDER).
func set_filled(text: String, fill: Color, ink: Color, icon_name: String = "", border_width: int = FILLED_BORDER) -> void:
	_set_ink(text, ink, icon_name, &"Pill")
	HallStyle.fill_art(self, HallStyle.PILL_STYLE, fill, ink, border_width)


func _set_ink(text: String, text_color: Color, icon_name: String, outline_look: StringName) -> void:
	HallStyle.clear_fill(self)
	_label.text = text
	HallStyle.set_font_color(_label, text_color)
	_icon.texture = HallStyle.icon_texture(icon_name)
	_icon.visible = _icon.texture != null
	_icon.modulate = text_color
	theme_type_variation = outline_look
	HallStyle.tint_art(self, text_color)


## Health from a character's injury level ("Healthy" in green, "Hurt"...),
## as a filled pill with its icon so it reads at a glance.
func set_health(character: GuildCharacter) -> void:
	var look := HallStyle.injury_look(character)
	set_filled(look.label, look.bg, look.text, look.icon)


## One stat as "Pow 6", or "Pow 5+3" when Armory, gear or Pluck add to it
## (quests use the sum), in the stat's ink on its paper tint (the same look as
## the Training Yard's stat buttons). The favored stat gets a heavy border.
func set_stat(character: GuildCharacter, stat_index: int, is_favored: bool = false) -> void:
	var stat: Dictionary = HallStyle.STATS[stat_index]
	var bonus := HallStyle.stat_bonus(character, stat_index)
	var text := "%s %d" % [stat.short, HallStyle.quest_stat_value(character, stat_index) - bonus]
	if bonus > 0:
		text += "+%d" % bonus
	set_filled(text, stat.bg, stat.color, "", FAVORED_BORDER if is_favored else FILLED_BORDER)
