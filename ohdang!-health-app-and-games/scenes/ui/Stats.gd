extends Control

const XP_NODE_PATH  := "/root/XP"
const LEDGER_PATH   := "user://xp_ledger.jsonl"

var total_val: Label = null
var avail_val: Label = null
var list_box: VBoxContainer = null

func _find_node(node_name: String) -> Node:
	var n: Variant = find_child(node_name, true, false)
	return n as Node

func _ready() -> void:
	total_val = _find_node("TotalVal") as Label
	avail_val = _find_node("AvailVal") as Label
	list_box  = _find_node("List")     as VBoxContainer

	_update_totals()
	_build_recent()

	# Keep totals live when XP changes
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null and not xp.is_connected("changed", Callable(self, "_update_totals")):
		xp.connect("changed", Callable(self, "_update_totals"))

func _update_totals() -> void:
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null and total_val != null and avail_val != null:
		var t: int = int(xp.get("total_xp"))
		var a: int = int(xp.get("available_xp"))
		total_val.text = str(t)
		avail_val.text = str(a)

func _build_recent() -> void:
	if list_box == null:
		return

	# Clear old
	for c in list_box.get_children():
		c.queue_free()

	# Read last up-to-10 lines from ledger (tail)
	var lines: Array[String] = _read_ledger_tail(10)

	if lines.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No entries yet."
		list_box.add_child(empty_lbl)
		return

	for line in lines:
		var obj: Variant = JSON.parse_string(line)
		if obj is Dictionary:
			var d: Dictionary = obj
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 28)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var ts  := Label.new()
			ts.text = String(d.get("ts", ""))
			ts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(ts)

			var typ := Label.new()
			typ.text = String(d.get("type", ""))
			typ.custom_minimum_size = Vector2(70, 0)
			row.add_child(typ)

			var delta := Label.new()
			delta.text = "+" + str(int(d.get("delta", 0))) if String(d.get("type","")) == "earn" else "-" + str(int(d.get("delta", 0)))
			delta.custom_minimum_size = Vector2(70, 0)
			row.add_child(delta)

			var src := Label.new()
			src.text = String(d.get("source", ""))
			src.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(src)

			list_box.add_child(row)

func _read_ledger_tail(max_count: int) -> Array[String]:
	var out: Array[String] = []
	if not FileAccess.file_exists(LEDGER_PATH):
		return out

	# Simple approach: read all, return last N (OK for MVP)
	var text: String = FileAccess.get_file_as_string(LEDGER_PATH)
	if text.is_empty():
		return out

	var all_lines: PackedStringArray = text.split("\n", false)
	# filter out empties
	var filtered: Array[String] = []
	for l in all_lines:
		var s: String = String(l)
		if not s.is_empty():
			filtered.append(s)

	var start: int = max(0, filtered.size() - max_count)
	for i in range(start, filtered.size()):
		out.append(filtered[i])

	return out
