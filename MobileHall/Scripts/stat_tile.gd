## One number in an ink box with a caption under it ("1240" / "gold earned").
## Used on the Game Over ledger's stat grid and for its big Days tile.
## Scene: MobileHall/Scenes/Components/stat_tile.tscn
extends PanelContainer

const Style := preload("res://MobileHall/Scripts/hall_style.gd")

# ---- NODES
@onready var _value: Label = %Value
@onready var _caption: Label = %Caption


## value_text = the big number or word, caption_text = what it counts,
## ink = the box outline and number colour. value_font_size 0 keeps the scene's.
func setup(value_text: String, caption_text: String, ink: Color, value_font_size: int = 0) -> void:
	_value.text = value_text
	_caption.text = caption_text
	Style.set_font_color(_value, ink)
	Style.tint_art(self, ink)
	if value_font_size > 0:
		_value.add_theme_font_size_override("font_size", value_font_size)
