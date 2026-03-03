extends VBoxContainer
# Generic container that loads child widget scenes based on Prefs keys

@export var prefs_key: String = ""   # "daily_widgets" or "weekly_widgets"
const PREFS_NODE_PATH := "/root/Prefs"

func _ready() -> void:
	_load_widgets()
	var prefs: Variant = get_node_or_null(PREFS_NODE_PATH)
	if prefs and not prefs.is_connected("changed", Callable(self, "_load_widgets")):
		prefs.connect("changed", Callable(self, "_load_widgets"))

func _load_widgets() -> void:
	if prefs_key == "":
		return

	# Clear old children
	for c in get_children():
		c.queue_free()

	var prefs: Variant = get_node_or_null(PREFS_NODE_PATH)
	if prefs == null:
		_add_placeholder()
		return

	# Read array from Prefs and strongly type it to Array[String]
	var arr_var: Variant = prefs.call("read", prefs_key, [])
	var raw: Array = (arr_var as Array) if (arr_var is Array) else []
	var paths: Array[String] = []
	for v in raw:
		paths.append(String(v))

	if paths.is_empty():
		_add_placeholder()
		return

	for path in paths:
		var path_str: String = path  # <-- explicit type retained
		if ResourceLoader.exists(path_str):
			var scene: PackedScene = load(path_str)
			if scene:
				var inst: Control = scene.instantiate() as Control
				add_child(inst)

func _add_placeholder() -> void:
	var placeholder := Label.new()
	placeholder.text = "(No widgets selected)"
	add_child(placeholder)
