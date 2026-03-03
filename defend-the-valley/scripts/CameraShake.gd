extends Camera2D
class_name CameraShake

@export var decay: float = 2.8        # how fast shake fades
@export var max_offset: float = 22.0  # pixels
@export var max_roll: float = 0.05    # radians (~3 degrees)

var trauma: float = 0.0
var trauma_power: float = 2.0

var _base_offset: Vector2
var _base_rotation: float

func _ready() -> void:
	_base_offset = offset
	_base_rotation = rotation
	make_current()

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma <= 0.0:
		offset = _base_offset
		rotation = _base_rotation
		return

	trauma = maxf(0.0, trauma - decay * delta)
	var t := pow(trauma, trauma_power)

	# random shake each frame
	var ox := randf_range(-1.0, 1.0) * max_offset * t
	var oy := randf_range(-1.0, 1.0) * max_offset * t
	offset = _base_offset + Vector2(ox, oy)

	var r := randf_range(-1.0, 1.0) * max_roll * t
	rotation = _base_rotation + r
