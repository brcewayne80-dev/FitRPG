extends Node
class_name XPModel

signal changed

var total_xp: int = 0
var available_xp: int = 0

const LEDGER_PATH_NODE := "/root/Ledger"  # Autoload name from Step 7

func _ready() -> void:
	_recalculate_from_ledger()
	print("[XP] Ready. total=%s avail=%s" % [total_xp, available_xp])

func add_xp(amount: int, source: String = "manual") -> void:
	earn_xp(amount, source)

func earn_xp(amount: int, source: String = "manual") -> void:
	if amount <= 0:
		return
	var entry: Dictionary = {
		"type": "earn",
		"delta": amount,
		"source": source
	}
	_append_to_ledger(entry)
	total_xp += amount
	available_xp += amount
	emit_signal("changed")

func spend_xp(amount: int, source: String = "spend") -> bool:
	if amount <= 0 or amount > available_xp:
		return false
	var entry: Dictionary = {
		"type": "spend",
		"delta": amount,
		"source": source
	}
	_append_to_ledger(entry)
	available_xp -= amount
	emit_signal("changed")
	return true

func reset() -> void:
	total_xp = 0
	available_xp = 0
	emit_signal("changed")

# --------------------
# Internals
# --------------------

func _ledger() -> Variant:
	# Nullable return; Variant avoids "nullable type" warnings.
	return get_node_or_null(LEDGER_PATH_NODE)

func _append_to_ledger(entry: Dictionary) -> void:
	var led: Variant = _ledger()
	if led != null:
		led.call("append_entry", entry)
	else:
		push_error("[XP] Ledger autoload not found at %s" % LEDGER_PATH_NODE)

func _recalculate_from_ledger() -> void:
	total_xp = 0
	available_xp = 0
	var path: String = "user://xp_ledger.jsonl"
	if not FileAccess.file_exists(path):
		emit_signal("changed")
		return

	var f: Variant = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("[XP] Could not open ledger file for read: " + path)
		emit_signal("changed")
		return

	while not f.eof_reached():
		var line: String = f.get_line()
		if line.is_empty():
			continue
		var obj: Variant = JSON.parse_string(line)
		if obj is Dictionary:
			var dict: Dictionary = obj
			var t: String = String(dict.get("type", ""))
			var d: int = int(dict.get("delta", 0))
			if t == "earn":
				total_xp += d
				available_xp += d
			elif t == "spend":
				available_xp -= d
	f.close()
	emit_signal("changed")
func get_today_earned() -> int:
	var path: String = "user://xp_ledger.jsonl"
	if not FileAccess.file_exists(path):
		return 0
	var today_prefix: String = Time.get_datetime_string_from_system(true, true).substr(0, 10) # "YYYY-MM-DD"

	var f: Variant = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0

	var sum: int = 0
	while not f.eof_reached():
		var line: String = f.get_line()
		if line.is_empty():
			continue
		var obj: Variant = JSON.parse_string(line)
		if obj is Dictionary:
			var d: Dictionary = obj
			var ts: String = String(d.get("ts", ""))
			var typ: String = String(d.get("type", ""))
			if ts.begins_with(today_prefix) and typ == "earn":
				sum += int(d.get("delta", 0))
	f.close()
	return sum
