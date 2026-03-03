extends Node
# (Removed: class_name ObjectivesModel)  // avoids global class-name collision

signal changed

const SAVE_PATH: String = "user://objectives.json"
const TODAY_FMT: String = "%Y-%m-%d"

var _today: String = ""
var _items: Array[Dictionary] = []  # { id, title, xp, completed(bool), completed_ts(String) }

func _ready() -> void:
	_today = _today_key()
	_load_or_seed()
	emit_signal("changed")
	print("[Objectives] Ready with %d items" % _items.size())

func list_today() -> Array:
	var copy: Array = _items.duplicate(true)
	return copy

func complete(id: String) -> bool:
	for i in range(_items.size()):
		var item: Dictionary = _items[i]
		if String(item.get("id", "")) == id:
			if bool(item.get("completed", false)):
				return false
			item["completed"] = true
			var ts: String = Time.get_datetime_string_from_system(true, true)
			item["completed_ts"] = ts
			_items[i] = item
			_save()

			var xp: Variant = get_node_or_null("/root/XP")
			if xp != null:
				var award: int = int(item.get("xp", 0))
				xp.call("earn_xp", award, "objective:%s" % id)
			emit_signal("changed")
			return true
	return false

# -----------------------
# Internals
# -----------------------
func _today_key() -> String:
	var iso: String = Time.get_datetime_string_from_system(true, true) # e.g. 2025-10-06T20:42:13Z
	return iso.substr(0, 10)  # "YYYY-MM-DD"

func _load_or_seed() -> void:
	_items.clear()

	# Try to load
	if FileAccess.file_exists(SAVE_PATH):
		var text: String = FileAccess.get_file_as_string(SAVE_PATH)
		if text.length() > 0:
			var data: Variant = JSON.parse_string(text)
			if data is Dictionary:
				var dict: Dictionary = data
				var date_str: String = String(dict.get("date", ""))
				if date_str == _today:
					var arr_var: Variant = dict.get("items")
					if arr_var is Array:
						var loaded: Array = (arr_var as Array).duplicate(true)
						for v in loaded:
							if v is Dictionary:
								_items.append(v as Dictionary)

	# Seed if empty or wrong day
	if _items.is_empty():
		var seed_items: Array[Dictionary] = [
			{"id":"walk",    "title":"Walk 20 minutes", "xp":50,  "completed":false, "completed_ts":""},
			{"id":"water",   "title":"Drink 8 glasses", "xp":30,  "completed":false, "completed_ts":""},
			{"id":"stretch", "title":"Stretch 10 min",  "xp":40,  "completed":false, "completed_ts":""},
		]
		_items = seed_items
		_save()

func _save() -> void:
	var f: Variant = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		var payload: Dictionary = {
			"date": _today,
			"items": _items
		}
		f.store_string(JSON.stringify(payload))
		f.close()
