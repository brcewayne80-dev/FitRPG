extends Control

const XP_NODE_PATH  := "/root/XP"
const OBJ_NODE_PATH := "/root/Objectives"

var list_box: VBoxContainer = null

func _find_node(node_name: String) -> Node:
	var n: Variant = find_child(node_name, true, false) # recursive search by name
	if n == null:
		push_error("[Objectives] Couldn't find node named: %s" % node_name)
		_debug_tree()
	return n as Node

func _ready() -> void:
	# Get the List container safely (no Unique Name required)
	list_box = _find_node("List") as VBoxContainer
	if list_box == null:
		push_error("[Objectives] List container missing. Make sure there's a VBoxContainer named 'List'.")
		return

	_rebuild()

	var obj: Variant = get_node_or_null(OBJ_NODE_PATH)
	if obj != null and not obj.is_connected("changed", Callable(self, "_rebuild")):
		obj.connect("changed", Callable(self, "_rebuild"))

func _rebuild() -> void:
	if list_box == null:
		return

	# Clear previous rows
	for c in list_box.get_children():
		c.queue_free()

	var obj: Variant = get_node_or_null(OBJ_NODE_PATH)
	if obj == null:
		_add_info("Objectives system not found. (Is Autoload 'Objectives' added?)")
		return

	var items_var: Variant = obj.call("list_today")
	if not (items_var is Array):
		_add_info("No objectives for today.")
		return

	var items: Array = items_var as Array
	if items.is_empty():
		_add_info("No objectives for today.")
		return

	for entry_var in items:
		if entry_var is Dictionary:
			var entry: Dictionary = entry_var as Dictionary
			_add_row(entry)

func _add_info(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	list_box.add_child(lbl)

func _add_row(entry: Dictionary) -> void:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 36)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = String(entry.get("title","(untitled)"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(title)

	var xp_val: int = int(entry.get("xp", 0))
	var xp_tag := Label.new()
	xp_tag.text = "+%d XP" % xp_val
	xp_tag.custom_minimum_size = Vector2(80, 0)
	xp_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(xp_tag)

	var btn := Button.new()
	var already: bool = bool(entry.get("completed", false))
	btn.text = "Completed" if already else "Complete"
	btn.disabled = already
	btn.pressed.connect(func():
		_on_complete_pressed(String(entry.get("id",""))))
	h.add_child(btn)

	list_box.add_child(h)

func _on_complete_pressed(id: String) -> void:
	var obj: Variant = get_node_or_null(OBJ_NODE_PATH)
	if obj != null:
		var ok_var: Variant = obj.call("complete", id)
		var ok: bool = bool(ok_var)
		if ok:
			_rebuild()

func _debug_tree(node: Node = self, indent: int = 0) -> void:
	var pad := "  ".repeat(indent)
	print("%s- %s (%s)" % [pad, node.name, node.get_class()])
	for c in node.get_children():
		_debug_tree(c, indent + 1)
