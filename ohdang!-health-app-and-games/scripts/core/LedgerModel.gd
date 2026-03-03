extends Node
class_name LedgerModel

signal entry_appended(entry)

# One-JSON-per-line (JSONL) file in the app's user data folder
var path: String = "user://xp_ledger.jsonl"

func _ready() -> void:
	# Ensure the file exists so later appends won't fail.
	if not FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.close()
	print("[Ledger] Ready. File:", path)

## Append an entry as a single line of JSON. Immutable / append-only.
## Expected keys (we’ll standardize next step): 
##   type: "earn"|"spend", delta: int, source: String, ts: String (optional)
func append_entry(entry: Dictionary) -> void:
	var e := entry.duplicate()
	if not e.has("ts"):
		# ISO-ish timestamp with timezone
		e["ts"] = Time.get_datetime_string_from_system(true, true)  # e.g. 2025-10-06T20:42:13Z

	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f:
		f.seek_end()                      # append to end of file
		f.store_line(JSON.stringify(e))   # write one JSON object per line
		f.close()
		emit_signal("entry_appended", e)
	else:
		push_error("[Ledger] Could not open ledger file for append: " + path)
