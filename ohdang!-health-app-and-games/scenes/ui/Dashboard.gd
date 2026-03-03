extends Control

const XP_NODE_PATH  := "/root/XP"
const OBJ_NODE_PATH := "/root/Objectives"
const PREFS_NODE_PATH := "/root/Prefs"

func _find_node(node_name: String) -> Node:
	var n: Variant = find_child(node_name, true, false)
	if n == null:
		push_error("[Dashboard] Couldn't find node named: %s" % node_name)
		_debug_tree()
	return n as Node

var btn_play: Button       = null
var btn_objectives: Button = null
var btn_stats: Button      = null
var btn_settings: Button   = null

var total_label: Label     = null
var avail_label: Label     = null
var today_val: Label       = null

# Quick Actions
var quick_box: HBoxContainer = null
var qa_add50: Button = null

func _ready() -> void:
	# lookups
	btn_play        = _find_node("BtnPlay") as Button
	btn_objectives  = _find_node("BtnObjectives") as Button
	btn_stats       = _find_node("BtnStats") as Button
	btn_settings    = _find_node("BtnSettings") as Button

	total_label     = _find_node("TotalXPVal") as Label
	avail_label     = _find_node("AvailXPVal") as Label
	today_val       = _find_node("TodayVal") as Label

	quick_box       = _find_node("QuickActions") as HBoxContainer
	qa_add50        = _find_node("QAAdd50") as Button

	# nav wiring
	if btn_play:        btn_play.pressed.connect(func(): _go("res://scenes/ui/Arcade.tscn"))
	if btn_objectives:  btn_objectives.pressed.connect(func(): _go("res://scenes/ui/Objectives.tscn"))
	if btn_stats:       btn_stats.pressed.connect(func(): _go("res://scenes/ui/Stats.tscn"))
	if btn_settings:    btn_settings.pressed.connect(func(): _go("res://scenes/ui/Settings.tscn"))

	# XP hooks
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	_update_xp_labels()
	if xp != null and not xp.is_connected("changed", Callable(self, "_update_xp_labels")):
		xp.connect("changed", Callable(self, "_update_xp_labels"))

	# Objectives hooks
	var obj: Variant = get_node_or_null(OBJ_NODE_PATH)
	_update_today_recaps()
	if obj != null and not obj.is_connected("changed", Callable(self, "_update_today_recaps")):
		obj.connect("changed", Callable(self, "_update_today_recaps"))

	# Prefs hooks (controls Quick Actions visibility)
	_apply_prefs_to_ui()
	var prefs: Variant = get_node_or_null(PREFS_NODE_PATH)
	if prefs != null and not prefs.is_connected("changed", Callable(self, "_apply_prefs_to_ui")):
		prefs.connect("changed", Callable(self, "_apply_prefs_to_ui"))

	# Quick action wiring
	if qa_add50 and not qa_add50.is_connected("pressed", Callable(self, "_on_qa_add50")):
		qa_add50.pressed.connect(_on_qa_add50)

func _on_qa_add50() -> void:
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null:
		xp.call("add_xp", 50, "quick_action:add50")
		_update_xp_labels()

func _apply_prefs_to_ui() -> void:
	var prefs: Variant = get_node_or_null(PREFS_NODE_PATH)
	var want_visible: bool = true
	if prefs != null:
		want_visible = bool(prefs.call("get_bool", "show_quick_actions", true))
	else:
		push_error("[Dashboard] Prefs autoload not found at /root/Prefs")

	if quick_box == null:
		push_error("[Dashboard] QuickActions node not found. Make sure HBoxContainer is named 'QuickActions'.")
		return

	quick_box.visible = want_visible
	print("[Dashboard] QuickActions visible = ", want_visible)



func _update_xp_labels() -> void:
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null and total_label != null and avail_label != null:
		total_label.text = str(int(xp.get("total_xp")))
		avail_label.text = str(int(xp.get("available_xp")))

func _update_today_recaps() -> void:
	var obj: Variant = get_node_or_null(OBJ_NODE_PATH)
	if obj == null or today_val == null:
		return
	var items_var: Variant = obj.call("list_today")
	if items_var is Array:
		var items: Array = items_var as Array
		var total: int = items.size()
		var done: int = 0
		for entry_var in items:
			if entry_var is Dictionary:
				var entry: Dictionary = entry_var as Dictionary
				if bool(entry.get("completed", false)):
					done += 1
		today_val.text = "%d / %d" % [done, total]

func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _debug_tree(node: Node = self, indent: int = 0) -> void:
	var pad := "  ".repeat(indent)
	print("%s- %s (%s)" % [pad, node.name, node.get_class()])
	for c in node.get_children():
		_debug_tree(c, indent + 1)
