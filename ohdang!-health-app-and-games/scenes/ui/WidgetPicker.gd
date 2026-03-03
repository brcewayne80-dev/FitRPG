extends Window

@export var prefs_key: String = ""
const PREFS_NODE_PATH := "/root/Prefs"

var grid: GridContainer
var btn_save: Button
var btn_cancel: Button

const AVAILABLE: Dictionary = {
	"Daily XP Card": "res://ui/widgets/DailyXPCard.tscn",
	"Objectives Card": "res://ui/widgets/ObjectivesSummaryCard.tscn",
	"Weighed In Today": "res://ui/widgets/DailyWeighInCard.tscn"
}

func _ready() -> void:
	grid       = find_child("Grid") as GridContainer
	btn_save   = find_child("BtnSave") as Button
	btn_cancel = find_child("BtnCancel") as Button
	if btn_save and not btn_save.is_connected("pressed", Callable(self, "_on_save")):
		btn_save.pressed.connect(_on_save)
	if btn_cancel and not btn_cancel.is_connected("pressed", Callable(self, "_on_cancel")):
		btn_cancel.pressed.connect(_on_cancel)
	_populate()

func _populate() -> void:
	for c in grid.get_children(): c.queue_free()
	for label in AVAILABLE.keys():
		var cb := CheckBox.new()
		cb.text = String(label)
		cb.name = String(label)
		grid.add_child(cb)

	var prefs: Node = get_node_or_null(PREFS_NODE_PATH)
	if prefs != null:
		var saved_var: Variant = prefs.call("read", prefs_key, [])
		var raw: Array = (saved_var as Array) if (saved_var is Array) else []
		var saved: Array[String] = []
		for v in raw: saved.append(String(v))
		for label2 in AVAILABLE.keys():
			var path_str: String = String(AVAILABLE[label2])
			if saved.has(path_str):
				var cb2: Node = grid.find_child(String(label2), true, false)
				if cb2 is CheckBox: (cb2 as CheckBox).button_pressed = true

func _on_save() -> void:
	var selected: Array[String] = []
	for child in grid.get_children():
		if child is CheckBox and (child as CheckBox).button_pressed:
			var label: String = (child as CheckBox).text
			if AVAILABLE.has(label):
				selected.append(String(AVAILABLE[label]))
	var prefs: Node = get_node_or_null(PREFS_NODE_PATH)
	if prefs != null:
		prefs.call("write", prefs_key, selected)
	hide()

func _on_cancel() -> void:
	hide()
