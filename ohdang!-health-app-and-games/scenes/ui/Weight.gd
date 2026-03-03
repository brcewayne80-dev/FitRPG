extends Control

const WEIGHT_NODE: String = "/root/Weight"

var spin: SpinBox = null
var unit: OptionButton = null
var btn: Button = null
var result: Label = null

func _ready() -> void:
	spin   = find_child("Spin", true, false) as SpinBox
	unit   = find_child("Unit", true, false) as OptionButton
	btn    = find_child("BtnSave", true, false) as Button
	result = find_child("Result", true, false) as Label

	# Seed units if empty
	if unit != null and unit.item_count == 0:
		unit.add_item("lb") # id auto-assigns
		unit.add_item("kg")

	# Default select first item if nothing selected
	if unit != null and unit.selected < 0 and unit.item_count > 0:
		unit.selected = 0

	if btn != null and not btn.is_connected("pressed", Callable(self, "_on_save")):
		btn.pressed.connect(_on_save)

func _on_save() -> void:
	var value_f: float = spin.value if spin != null else 0.0

	# In Godot 4, OptionButton: use .selected (index) to read text
	var idx: int = unit.selected if unit != null else 0
	var unit_s: String = unit.get_item_text(idx) if unit != null else "lb"

	var w: Node = get_node_or_null(WEIGHT_NODE)
	if w == null:
		_set_result("Could not access Weight model.")
		return

	var ok_any: Variant = w.call("add_entry", value_f, unit_s)
	var ok: bool = bool(ok_any)
	_set_result("Saved %.1f %s" % [value_f, unit_s] if ok else "Failed to save.")

func _set_result(msg: String) -> void:
	if result != null:
		result.text = msg
