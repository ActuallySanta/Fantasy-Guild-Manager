## Small rounded label, optionally with an icon.
## Used for stats, health, gold, rank, party size and other short facts.
## Scene: MobileHall/Scenes/Components/chip.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

## Corner radius of every chip.
const CORNER_RADIUS := 16
## Border width when `outlined` is on (the quest's favored stat).
const OUTLINE_WIDTH := 3

# ---- NODES
@onready var _icon: TextureRect = $Row/Icon
@onready var _label: Label = $Row/Text


## icon_name = a name from hall_style ICON_FILES ("" or unknown = no icon).
## outlined = heavier border in the text colour (the quest's favored stat).
func set_chip(text: String, background: Color, text_color: Color, icon_name: String = "", outlined: bool = false) -> void:
	_label.text = text
	Style.set_font_color(_label, text_color)
	_icon.texture = Style.icon_texture(icon_name)
	_icon.visible = _icon.texture != null

	# less left padding when the icon is there, so it sits close to the edge
	var left_padding := 8 if _icon.visible else 12
	var border_width := OUTLINE_WIDTH if outlined else 0
	var box := Style.flat_box(background, CORNER_RADIUS, border_width, text_color, Vector4(left_padding, 2, 12, 3))
	add_theme_stylebox_override("panel", box)


## Health chip from a character's injury level ("Healthy", "Hurt", ...).
func set_health(character: GuildCharacter) -> void:
	var look := Style.injury_look(character)
	var icon_name := "heart" if character.injury_level == 0 else "injury"
	set_chip(look.label, look.bg, look.text, icon_name)


## One stat as "Pow 6" in that stat's colours.
func set_stat(character: GuildCharacter, stat_index: int, is_favored: bool = false) -> void:
	var stat: Dictionary = Style.STATS[stat_index]
	var text := "%s %d" % [stat.short, Style.stat_value(character, stat_index)]
	set_chip(text, stat.bg, stat.color, "", is_favored)
