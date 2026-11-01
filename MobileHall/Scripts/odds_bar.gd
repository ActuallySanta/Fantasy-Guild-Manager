## Success-chance bar: hatched fill in the odds ink over a paper track, with
## quarter ticks on top.
## Art: MobileHall/Art/Textures/odds_track.png (under), odds_fill.png (the fill,
## white so it can be tinted), odds_over.png (border and quarter ticks on top).
## Scene: MobileHall/Scenes/Components/odds_bar.tscn
extends TextureProgressBar

const Style := preload("res://MobileHall/Scripts/hall_style.gd")
const Fx := preload("res://MobileHall/Scripts/hall_fx.gd")

## Seconds the fill takes to slide to a new chance (when animated).
const SLIDE_SECONDS := 0.4

var _slide_tween: Tween


## chance = 0..100, or -1 for "no party yet" (empty bar).
## animate = slide the fill there (Assign Party, when the party changes).
func set_chance(chance: int, animate := false) -> void:
	var target := clampf(chance, 0.0, 100.0) if chance >= 0 else 0.0
	tint_progress = Style.odds_look(chance).bar_color
	if _slide_tween:
		_slide_tween.kill()
	if not animate or Fx.reduce_motion:
		value = target
		return
	_slide_tween = create_tween()
	_slide_tween.tween_property(self, "value", target, SLIDE_SECONDS) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
