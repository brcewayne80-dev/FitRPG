extends Button
func _ready() -> void:
	if not is_connected("pressed", Callable(self, "_on_back")):
		pressed.connect(_on_back)
func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Home.tscn")
