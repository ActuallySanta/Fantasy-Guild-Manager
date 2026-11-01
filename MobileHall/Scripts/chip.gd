## A small ink label, optionally with an icon and an outline.
## Used for stats, health, gold, rank, party size and other short facts.
## The outline is white art (Styles/pill.tres or ink_box.tres) tinted the ink colour.
## Scene: MobileHall/Scenes/Components/chip.tscn
extends PanelContainer


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


func _set_ink(text: String, text_color: Color, icon_name: String, outline_look: StringName) -> void:
	_label.text = text
	HallStyle.set_font_color(_label, text_color)
	_icon.texture = HallStyle.icon_texture(icon_name)
	_icon.visible = _icon.texture != null
	_icon.modulate = text_color
	theme_type_variation = outline_look
	HallStyle.tint_art(self, text_color)


## Health from a character's injury level ("Healthy" in green, "Hurt"...).
func set_health(character: GuildCharacter) -> void:
	var look := HallStyle.injury_look(character)
	set_chip(look.label, look.bg, look.text)


## One stat as "Pow 6", or "Pow 5+3" when Armory, gear or Pluck add to it
## (quests use the sum). The favored stat gets a pill in its colour.
func set_stat(character: GuildCharacter, stat_index: int, is_favored: bool = false) -> void:
	var stat: Dictionary = HallStyle.STATS[stat_index]
	var bonus := HallStyle.stat_bonus(character, stat_index)
	var text := "%s %d" % [stat.short, HallStyle.quest_stat_value(character, stat_index) - bonus]
	if bonus > 0:
		text += "+%d" % bonus
	set_chip(text, stat.bg, stat.color if is_favored else HallStyle.TEXT_MAIN, "", is_favored)
