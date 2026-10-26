@abstract class_name ActiveItem extends StandardItem

@export var max_uses : int

signal on_item_used

func use_item()-> void:
	max_uses -=1
	on_item_used.emit()
