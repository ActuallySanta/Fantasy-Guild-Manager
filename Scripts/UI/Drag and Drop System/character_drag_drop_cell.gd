extends AnimatedButton

class_name DragDropCell

#Where the button is on the grid
var grid_position: Vector2i
signal dragged(from: Vector2i, to: Vector2i)


func _get_drag_data(_at_position: Vector2) -> Variant:
	#If there isn't an icon in the button, that means there isn't an item in the button, so you can't drag it
	if not icon:
		return null

	var preview := TextureRect.new()
	preview.texture = icon
	set_drag_preview(preview)

	return self


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	#Prevent from being able to drag non cell objects or dropping something onto itself
	if not data is DragDropCell or data == self:
		return false

	grab_focus()
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var temp: Texture2D = icon
	icon = data.icon
	data.icon = temp
	dragged.emit(data.grid_position, self.grid_position)
	pass
