extends Control
# Draws a circular gauge of "XP earned today" vs. a target.

@export var daily_target: int = 200
@export var ring_thickness: float = 14.0
@export var bg_color: Color = Color(0.90, 0.93, 0.97, 1.0)
@export var fg_color: Color = Color(0.23, 0.51, 0.96, 1.0) # accent blue
@export var text_color: Color = Color(0.10, 0.10, 0.10, 1.0)

const XP_NODE_PATH := "/root/XP"

var _today_xp: int = 0

func _ready() -> void:
	set_process(false)
	_refresh_from_model()
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null and not xp.is_connected("changed", Callable(self, "_on_xp_changed")):
		xp.connect("changed", Callable(self, "_on_xp_changed"))

func _on_xp_changed() -> void:
	_refresh_from_model()

func _refresh_from_model() -> void:
	var xp: Variant = get_node_or_null(XP_NODE_PATH)
	if xp != null and xp.has_method("get_today_earned"):
		var v: Variant = xp.call("get_today_earned")
		_today_xp = int(v)
	else:
		_today_xp = 0
	queue_redraw()

func _draw() -> void:
	var size_v: Vector2 = size
	var center: Vector2 = size_v * 0.5
	var radius: float = float(min(size_v.x, size_v.y)) * 0.5 - ring_thickness * 0.5 - 2.0
	if radius < 0.0:
		return

	# Background ring
	draw_arc(center, radius, 0.0, TAU, 96, bg_color, ring_thickness, true)

	# Foreground arc
	var ratio: float = 0.0
	if daily_target > 0:
		ratio = clamp(float(_today_xp) / float(daily_target), 0.0, 1.0)
	var start_angle: float = -PI * 0.5
	var end_angle: float = start_angle + TAU * ratio
	draw_arc(center, radius, start_angle, end_angle, 96, fg_color, ring_thickness, true)

	# Center text
	var pct: int = int(round(ratio * 100.0))
	var text: String = "%d XP\nToday (%d%%)" % [_today_xp, pct]
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	if font != null:
		var rect: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var top_left: Vector2 = center - rect * 0.5
		# Godot 4 signature: (font, pos, text, alignment, width, font_size, max_lines, modulate, ...)
		draw_multiline_string(font, top_left, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, -1, text_color)
