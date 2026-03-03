extends Node2D
class_name CatapultRock

@export var gravity: float = 1200.0
@export var max_lifetime: float = 6.0

@export var aoe_radius: float = 110.0
@export var aoe_damage: float = 30.0

# How close to floor counts as impact (helps avoid flicker)
@export var floor_hit_epsilon: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion: AnimatedSprite2D = $Explosion

var _vel: Vector2 = Vector2.ZERO
var _life: float = 0.0
var _floor_y: float = 0.0
var _exploded: bool = false

func configure(start_pos: Vector2, initial_velocity: Vector2, floor_y: float, damage: float, radius: float) -> void:
	global_position = start_pos
	_vel = initial_velocity
	_floor_y = floor_y
	aoe_damage = damage
	aoe_radius = radius
	_life = 0.0
	_exploded = false

	if sprite:
		sprite.visible = true
	if explosion:
		explosion.visible = false

func _process(delta: float) -> void:
	if _exploded:
		return

	_life += delta
	if _life >= max_lifetime:
		queue_free()
		return

	# ballistic flight
	_vel.y += gravity * delta
	global_position += _vel * delta
	rotation = _vel.angle()

	# impact check: boulder hits the ground (floor_y)
	if global_position.y >= (_floor_y - floor_hit_epsilon):
		global_position.y = _floor_y
		_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	rotation = 0.0

	# Hide boulder, show explosion
	if sprite:
		sprite.visible = false

	if explosion:
		explosion.rotation = 0.0
		explosion.visible = true
		explosion.play()

	# Apply AOE damage to enemies inside radius
	_apply_aoe_damage()

	# Wait for explosion anim to finish (or fallback timer)
	if explosion and explosion.sprite_frames and explosion.animation != "":
		await explosion.animation_finished
	else:
		await get_tree().create_timer(0.4).timeout

	queue_free()

func _apply_aoe_damage() -> void:
	# Query physics space for colliders in a circle around impact point.
	# This requires enemies to have ANY CollisionShape2D on them (recommended).
	var space := get_world_2d().direct_space_state
	if space == null:
		return

	var shape := CircleShape2D.new()
	shape.radius = aoe_radius

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = true

	# Optional: restrict to a collision mask (set if you use layers)
	# params.collision_mask = 1 << 2  # example: enemies on layer 3

	var results := space.intersect_shape(params, 64)

	for r in results:
		var collider: Node = r.get("collider") as Node
		if collider == null:
			continue

		# If collider is a child (CollisionShape2D), walk up to a parent with take_damage
		var n: Node = collider
		var tries := 0
		while n != null and tries < 4 and not n.has_method("take_damage"):
			n = n.get_parent()
			tries += 1

		if n != null and n.has_method("take_damage"):
			n.call("take_damage", aoe_damage)
