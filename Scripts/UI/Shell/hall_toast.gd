## Toast: a short message just above the action bar that fades out.
## Starts hidden; hall_main.gd show_toast() puts messages up.
## Scene: MobileHall/Scenes/Shell/hall_toast.tscn
class_name HallToast
extends PanelContainer


# ============================================================ SETTINGS

## Seconds a toast stays fully visible, then how long it takes to fade.
const SHOW_SECONDS := 2.2
const FADE_SECONDS := 0.4


# ============================================================ STATE

## The fade of the toast showing now (killed when a new one replaces it).
var _tween: Tween


# ============================================================ NODES

@onready var _label: Label = %ToastLabel


# ============================================================ SHOWING

## Show `message`, replacing any toast already up, then fade it out.
func show_message(message: String) -> void:
	_label.text = message
	modulate.a = 1.0
	visible = true
	HallFx.appear(self, 0.8, 0.0, 0.25)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(SHOW_SECONDS)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(hide)
