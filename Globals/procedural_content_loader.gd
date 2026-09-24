extends Node
class_name ProceduralContentLoader

static func _load_info_from_file(file_path:String) -> Array:
	var arr :Array
	
	# Open the file
	var file := FileAccess.open(file_path,FileAccess.READ)
	
	# Check if the file opened successfully
	if not file:
		print("Error opening file: ", FileAccess.get_open_error())
		return arr
		
	while not file.eof_reached():
		var row : PackedStringArray = file.get_csv_line()
		# Skip empty rows (often found at the end of a file)
		if row.size() == 1 and row[0] == "":
			continue
		arr.append(row)
	
	file.close()
	return arr
	pass
