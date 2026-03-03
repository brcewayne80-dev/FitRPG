extends Node
# Stores weight entries (append-only JSONL) and emits a signal when a new entry is added.

signal entry_added(date_str: String, value: float, unit: String)

const LOG_PATH: String = "user://weights.jsonl"

func _ready() -> void:
	print("[Weight] Ready. File:", LOG_PATH)

func add_entry(value: float, unit: String = "lb") -> bool:
	var now_iso: String = Time.get_datetime_string_from_system(true, true) # "YYYY-MM-DDTHH:MM:SS"
	var date_str: String = now_iso.substr(0, 10) # "YYYY-MM-DD"

	var obj: Dictionary = {
		"ts": now_iso,
		"date": date_str,
		"value": value,
		"unit": unit
	}

	# Explicit typing avoids Variant inference warnings
	var f: FileAccess = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
		if f == null:
			push_error("[Weight] Could not open file for writing.")
			return false

	f.seek_end()
	f.store_line(JSON.stringify(obj))
	f.flush()
	f.close()

	emit_signal("entry_added", date_str, value, unit)
	return true

func has_entry_on(date_str: String) -> bool:
	if not FileAccess.file_exists(LOG_PATH):
		return false

	var text: String = FileAccess.get_file_as_string(LOG_PATH)
	if text.is_empty():
		return false

	var lines: PackedStringArray = text.split("\n", false)
	for line in lines:
		var s: String = String(line)
		if s.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(s)
		if parsed is Dictionary:
			var d: Dictionary = parsed as Dictionary
			var d_date: String = String(d.get("date", ""))
			if d_date == date_str:
				return true
	return false

func has_entry_today() -> bool:
	var today: String = Time.get_datetime_string_from_system(true, true).substr(0, 10)
	return has_entry_on(today)
