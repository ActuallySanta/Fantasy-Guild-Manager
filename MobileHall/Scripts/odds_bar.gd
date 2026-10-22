## Success-chance bar: hatched fill in the odds ink over a paper track.
## Art: MobileHall/Art/Textures/odds_track.png (under), odds_fill.png (the fill,
## white so it can be tinted), odds_over.png (border and quarter ticks on top).
## Scene: MobileHall/Scenes/Components/odds_bar.tscn
extends TextureProgressBar

const S := preload("res://MobileHall/Scripts/hall_style.gd")


## chance = 0..100, or -1 for "no party yet".
func set_chance(chance: int) -> void:
	value = clampf(chance, 0.0, 100.0) if chance >= 0 else 0.0
	tint_progress = S.odds(chance)[1]
