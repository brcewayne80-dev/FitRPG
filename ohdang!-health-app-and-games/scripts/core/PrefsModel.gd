extends Node
# No class_name to avoid namespace conflicts

signal changed

const SAVE_PATH: String = "user://prefs.json"

var _data: Dictionary = {}

func _ready() -> void:
	_load()
	if not _data.has("show_quick_actions"):
		_data["show_quick_actions"] = true
		_save()
	emit_signal("changed")
	print("[Prefs] Ready. show_quick_actions=", _data.get("show_quick_actions"))

# -------- Public API (typed, no name collisions with Node) --------
func get_bool(key: String, default_value: bool) -> bool:
	if _data.has(key):
		return bool(_data[key])
	return default_value

func set_bool(key: String, value: bool) -> void:
	_data[key] = value
	print("[Prefs] set_bool ", key, " -> ", value)
	_save()
	emit_signal("changed")

func read(key: String, default_value: Variant = null) -> Variant:
	# Safe dictionary-style read with default
	return _data.get(key, default_value)

func write(key: String, value: Variant) -> void:
	_data[key] = value
	print("[Prefs] write ", key, " -> ", value)
	_save()
	emit_signal("changed")

# -------- Internals --------
func _load() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var text: String = FileAccess.get_file_as_string(SAVE_PATH)
		print("[Prefs] _load text len=", text.length())
		if text.length() > 0:
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				_data = parsed as Dictionary
				print("[Prefs] _load ok: ", _data)
				return
			else:
				print("[Prefs] _load parse failed; resetting.")
	# fallback
	_data = {}
	print("[Prefs] _load fallback -> empty dict")

func _save() -> void:
	var f: Variant = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		var s := JSON.stringify(_data)
		f.store_string(s)
		f.flush()
		f.close()
		print("[Prefs] _save wrote: ", s)
