extends Control

const XP_NODE_PATH      := "/root/XP"
const OBJ_NODE_PATH     := "/root/Objectives"
const PREFS_NODE_PATH   := "/root/Prefs"
const LEDGER_FILE_PATH  := "user://xp_ledger.jsonl"
const OBJECTIVES_PATH   := "user://objectives.json"

var btn_open: Button = null
var btn_reset: Button = null
var lbl_result: Label = null
var toggle_qa: CheckButton = null

func _find_node(node_name: String) -> Node:
	var n: Variant = find_child(node_name, true, false) # recursive search
	if n == null:
		push_error("[Settings] Missing node: " + node_name)
	return n as Node

func _ready() -> void:
	print("[Settings] _ready()")
	btn_open   = _find_node("BtnOpenData") as Button
	btn_reset  = _find_node("BtnReset") as Button
	lbl_result = _find_node("Result") as Label
	toggle_qa  = _find_node("ToggleQuickActions") as CheckButton
	print("[Settings] found BtnOpenData?", btn_open != null, " BtnReset?", btn_reset != null, " Result?", lbl_result != null, " ToggleQuickActions?", toggle_qa != null)

	if btn_open and not btn_open.is_connected("pressed", Callable(self, "_on_open_data_pressed")):
		btn_open.pressed.connect(_on_open_data_pressed)
	if btn_reset and not btn_reset.is_connected("pressed", Callable(self, "_on_reset_pressed")):
		btn_reset.pressed.connect(_on_reset_pressed)
	if toggle_qa and not toggle_qa.is_connected("toggled", Callable(self, "_on_toggle_qa")):
		toggle_qa.toggled.connect(_on_toggle_qa)

	_init_toggle_from_prefs()
	_set_result("")

func _init_toggle_from_prefs() -> void:
	var prefs: Variant = get_node_or_null(PREFS_NODE_PATH)
	print("[Settings] init: Prefs present?", prefs != null)
	if prefs != null and toggle_qa:
		var current: bool = bool(prefs.call("get_bool", "show_quick_actions", true))
		print("[Settings] init toggle show_quick_actions=", current)
		toggle_qa.button_pressed = current

func _on_open_data_pressed() -> void:
	var user_abs: String = ProjectSettings.globalize_path("user://")
	var ok: bool = OS.shell_open(user_abs)
	_set_result("Opened data folder:\n" + user_abs if ok else "Could not open folder: " + user_abs)

func _on_reset_pressed() -> void:
	if FileAccess.file_exists(LEDGER_FILE_PATH):
		var err_ledger: int = DirAccess.remove_absolute(ProjectSettings.globalize_path(LEDGER_FILE_PATH))
		if err_ledger != OK:
			_set_result("Failed to remove ledger file."); return
	if FileAccess.file_exists(OBJECTIVES_PATH):
		var err_obj: int = DirAccess.remove_absolute(ProjectSettings.globalize_path(OBJECTIVES_PATH))
		if err_obj != OK:
			_set_result("Failed to remove objectives file."); return

	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null: xp.call("_recalculate_from_ledger")
	var obj: Variant = get_node_or_null(OBJ_NODE_PATH)
	if obj != null: obj.call("_ready")

	_set_result("All data cleared.\nLedger and objectives reset for today.")

func _on_toggle_qa(_pressed: bool) -> void:
	var desired: bool = toggle_qa != null and toggle_qa.button_pressed
	print("[Settings] toggle clicked -> ", desired)

	var prefs: Variant = get_node_or_null(PREFS_NODE_PATH)
	print("[Settings] saving to Prefs present?", prefs != null)
	if prefs != null:
		prefs.call("set_bool", "show_quick_actions", desired)

	var dash := get_tree().root.find_child("Dashboard", true, false)
	print("[Settings] found Dashboard?", dash != null)
	if dash != null and dash.has_method("_apply_prefs_to_ui"):
		dash.call("_apply_prefs_to_ui")

	# (Fixed) add a space before enabled/disabled
	_set_result("Quick Actions " + ( "enabled" if desired else "disabled" ) + " on Dashboard.")

func _set_result(msg: String) -> void:
	if lbl_result:
		lbl_result.text = msg
