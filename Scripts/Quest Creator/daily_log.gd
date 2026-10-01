extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func changeText(_accepted_Quests : Array[String]) -> void :
	add_theme_color_override("default_color", Color.BLACK)
	text = "\n"
	for i in _accepted_Quests.size() :
		append_text(str("[b]Quest ", i + 1, " of the day:\n[/b]"))
		append_text(_accepted_Quests[i])
		append_text("\n")
	pass
