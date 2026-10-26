## Success-chance bar: hatched fill in the odds ink over a paper track, with
## quarter ticks on top.
## Art: MobileHall/Art/Textures/odds_track.png (under), odds_fill.png (the fill,
## white so it can be tinted), odds_over.png (border and quarter ticks on top).
## Scene: MobileHall/Scenes/Components/odds_bar.tscn
extends TextureProgressBar

const Style := preload("res://MobileHall/Scripts/hall_style.gd")


## chance = 0..100, or -1 for "no party yet" (empty bar).
func set_chance(chance: int) -> void:
	value = clampf(chance, 0.0, 100.0) if chance >= 0 else 0.0
	tint_progress = Style.odds_look(chance).bar_color
