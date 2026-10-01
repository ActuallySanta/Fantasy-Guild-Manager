extends Node

class_name MultiColumnLoader

static func _load_info_from_file(_file_path: String, _columns, col_idx) -> Array[String]:
	var arr: Array[String]
	
	# Open the file
	var file := FileAccess.open(_file_path, FileAccess.READ)

	# Check if the file opened successfully
	if not file:
		print("Error opening file: ", FileAccess.get_open_error())
		return arr

	while not file.eof_reached():
		var row: String = file.get_line().strip_edges()
		# Skip empty rows (often found at the end of a file)
		if row.is_empty():
			continue
		
		var columns: PackedStringArray = row.split("|")
		
		# Ensure the column index exists in this line to prevent crashes
		if col_idx < columns.size():
			arr.append(columns[col_idx])

	file.close()
	return arr
	pass
