extends TextureButton

@export var animation_time : float = 0.5
@export var final_scale : float = 1.5
@export var final_rotation:float = .15

var scale_tween : Tween
var rotation_tween:Tween

var initial_rotation:float

func _ready() -> void:
	initial_rotation = rotation
	pivot_offset = size/2

func _on_mouse_entered() -> void:
	scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_IN_OUT)
	scale_tween.set_trans(Tween.TRANS_ELASTIC)
	scale_tween.tween_property(self,"scale",Vector2.ONE*final_scale,animation_time)
	
	rotation_tween = create_tween()
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_ELASTIC)
	rotation_tween.tween_property(self,"rotation",initial_rotation + final_rotation,animation_time)
	
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_IN_OUT)
	scale_tween.set_trans(Tween.TRANS_ELASTIC)
	scale_tween.tween_property(self,"scale",Vector2.ONE,animation_time)
	
	rotation_tween = create_tween()
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_ELASTIC)
	rotation_tween.tween_property(self,"rotation",initial_rotation,animation_time)
	
	pass # Replace with function body.
