extends GridContainer

class_name DragDropGrid

signal on_dragged(from: Vector2i, to: Vector2i)

var cells: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in columns:
		cells.append([])
	var _curr_row: int = 0
	var _curr_column: int = 0

	#Attack all the children to the 2D array
	for cell in get_children():
		cells[_curr_column].append(cell)
		_curr_column += 1

		#Set the information of that specific button
		var cell_button := cell as DragDropCell
		cell_button.grid_position = Vector2i(_curr_column, _curr_row)
		cell_button.dragged.connect(on_dragged.emit)

		#If we've reached the end of the grid container's column, loop back to the next row and repeat
		if _curr_column >= columns:
			_curr_column = 0
			_curr_row += 1
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
