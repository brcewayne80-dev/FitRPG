extends Area2D
class_name Projectile

@export var projectile_gravity: float = 1200.0        # px/s^2 (tune)
@export var max_lifetime: float = 3.0      # safety cleanup
@export var stick_lifetime: float = 1.0
@export var floor_y: float = 578.0
@export var hit_radius_debug: float = 0.0  # leave 0

var _damage: float = 0.0
var _vel: Vector2 = Vector2.ZERO
var _life: float = 0.0
var _stuck: bool = false
var _stick_time_left: float = 0.0

func _ready() -> void:
	# Cover both possibilities (enemy might be body or area later)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func configure_ballistic(start_pos: Vector2, initial_velocity: Vector2, damage: float) -> void:
	global_position = start_pos
	_vel = initial_velocity
	_damage = damage
	_life = 0.0
	_stuck = false
	_stick_time_left = 0.0
	rotation = _vel.angle()

func _physics_process(delta: float) -> void:
	if _stuck:
		_stick_time_left -= delta
		if _stick_time_left <= 0.0:
			queue_free()
		return

	_life += delta
	if _life >= max_lifetime:
		queue_free()
		return

	# ballistic arc
	_vel.y += projectile_gravity * delta
	global_position += _vel * delta
	rotation = _vel.angle()
	if global_position.y >= floor_y:
		_stick_in_floor()

func _try_hit(node: Node) -> void:
	if _stuck:
		return
	if node != null and node.has_method("take_damage"):
		node.take_damage(_damage)
		queue_free()

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _stick_in_floor() -> void:
	_stuck = true
	_stick_time_left = stick_lifetime
	monitoring = false
	monitorable = false
	_vel = Vector2.ZERO
	global_position.y = floor_y
