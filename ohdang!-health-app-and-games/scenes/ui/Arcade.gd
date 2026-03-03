extends Control

const XP_NODE_PATH := "/root/XP"
const COST: int = 20

var avail_val: Label = null
var btn_start: Button = null
var status_lbl: Label = null

func _find_node(node_name: String) -> Node:
	var n: Variant = find_child(node_name, true, false) # recursive search
	return n as Node

func _ready() -> void:
	avail_val  = _find_node("AvailVal") as Label
	btn_start  = _find_node("BtnStart") as Button
	status_lbl = _find_node("Status") as Label

	_update_available()

	# keep available XP live
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null and not xp.is_connected("changed", Callable(self, "_update_available")):
		xp.connect("changed", Callable(self, "_update_available"))

	# wire the start button
	if btn_start and not btn_start.is_connected("pressed", Callable(self, "_on_start_pressed")):
		btn_start.pressed.connect(_on_start_pressed)

func _update_available() -> void:
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null and avail_val != null:
		var a: int = int(xp.get("available_xp"))
		avail_val.text = str(a)

func _on_start_pressed() -> void:
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp == null:
		_set_status("XP system not ready.")
		return

	var a: int = int(xp.get("available_xp"))
	if a < COST:
		_set_status("Not enough XP. You need %d XP but only have %d." % [COST, a])
		return

	# spend via XP model (this writes to ledger and updates labels)
	var ok_var: Variant = xp.call("spend_xp", COST, "arcade:start")
	var ok: bool = bool(ok_var)
	if ok:
		_set_status("Mini-game started! (Spent %d XP)" % COST)
		# Here’s where a real game scene would load. For now we just succeed.
	else:
		_set_status("Could not spend XP. Try again.")

func _set_status(msg: String) -> void:
	if status_lbl:
		status_lbl.text = msg
