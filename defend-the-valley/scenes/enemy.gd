extends CharacterBody2D

signal died(enemy: Enemy)
signal attacking_tower(enemy: Enemy, damage: float)

enum State { WALK, ATTACK, DIE }

@export var move_speed: float = 80.0
@export var max_hp: float = 60.0

# How much damage each "attack tick" deals
@export var attack_damage: float = 8.0

# How often damage is applied while attacking (seconds)
@export var attack_interval: float = 0.9

# Animation names (must match your AnimatedSprite2D SpriteFrames animations)
@export var anim_walk: StringName = &"walk"
@export var anim_attack: StringName = &"attack"
@export var anim_die: StringName = &"die"

@onready var anim: AnimatedSprite2D = $Anim

var hp: float
var state: State = State.WALK

# Targeting
var tower_x: float = 0.0
var lane_y: float = 0.0

# Attack timing
var _attack_timer: float = 0.0

func _ready() -> void:
	hp = max_hp
	if anim:
		anim.animation_finished.connect(_on_anim_finished)
		_play(anim_walk)

func configure(tower_x_in: float, lane_y_in: float, hp_scale: float = 1.0, speed_scale: float = 1.0, dmg_scale: float = 1.0) -> void:
	tower_x = tower_x_in
	lane_y = lane_y_in

	max_hp *= hp_scale
	hp = max_hp
	move_speed *= speed_scale
	attack_damage *= dmg_scale

	# Lock to lane
	global_position.y = lane_y

func take_damage(amount: float) -> void:
	if state == State.DIE:
		return

	hp -= amount
	if hp <= 0.0:
		_die()

func _physics_process(delta: float) -> void:
	# Keep the orc in its lane (no drifting)
	global_position.y = lane_y

	match state:
		State.WALK:
			_walk_step(delta)
		State.ATTACK:
			_attack_step(delta)
		State.DIE:
			velocity = Vector2.ZERO

func _walk_step(_delta: float) -> void:
	# Move right -> left toward the tower on the left
	velocity = Vector2(-move_speed, 0.0)
	move_and_slide()

	# When we reach/past the tower x, start attacking
	if global_position.x <= tower_x:
		state = State.ATTACK
		velocity = Vector2.ZERO
		_attack_timer = 0.15  # tiny delay so the attack doesn't hit instantly on contact
		_play(anim_attack)

func _attack_step(delta: float) -> void:
	velocity = Vector2.ZERO

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		emit_signal("attacking_tower", self, attack_damage)

func _die() -> void:
	state = State.DIE
	velocity = Vector2.ZERO
	_play(anim_die)

func _play(anim_name: StringName) -> void:
	if anim == null:
		return
	if anim.animation != anim_name:
		anim.play(anim_name)
	else:
		# replay (useful if you call play on same anim)
		anim.play()

func _on_anim_finished() -> void:
	# Only free when the die animation finishes
	if state == State.DIE and anim.animation == anim_die:
		emit_signal("died", self)
		queue_free()
