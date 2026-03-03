extends Node2D

signal died(enemy)
signal attacking_tower(enemy, damage)

enum State { WALK, ATTACK, DIE }

@export var base_move_speed = 40.0
@export var base_max_hp = 60.0
@export var base_attack_damage = 8.0
@export var attack_interval = 0.9

@export var anim_walk = "walk"
@export var anim_attack = "attack"
@export var anim_die = "die"
@export var sprite_faces_right = true
@export var show_hp_bar = true
@export var hp_bar_size = Vector2(40.0, 6.0)
@export var hp_bar_offset = Vector2(-20.0, -72.0)

@onready var anim = get_node_or_null("Anim")

var move_speed = 0.0
var max_hp = 0.0
var attack_damage = 0.0
var hp = 0.0

var state = State.WALK
var contact_x = 0.0
var floor_y = 0.0
var _attack_timer = 0.0

func _ready():
	if anim:
		if anim.has_signal("animation_finished"):
			anim.animation_finished.connect(_on_anim_finished)
		if anim.has_method("play"):
			anim.play(anim_walk)

func configure_spawn(spawn_pos, contact_x_in, floor_y_in, hp_scale = 1.0, speed_scale = 1.0, dmg_scale = 1.0):
	global_position = spawn_pos
	contact_x = float(contact_x_in)
	floor_y = float(floor_y_in)

	move_speed = float(base_move_speed) * float(speed_scale)
	max_hp = float(base_max_hp) * float(hp_scale)
	attack_damage = float(base_attack_damage) * float(dmg_scale)
	hp = max_hp

	state = State.WALK
	_attack_timer = 0.0
	global_position.y = floor_y

	if anim and anim.has_method("play"):
		anim.play(anim_walk)

func take_damage(amount):
	if state == State.DIE:
		return
	hp -= float(amount)
	if hp <= 0.0:
		_die()

func retarget_contact(new_contact_x):
	contact_x = float(new_contact_x)
	if state == State.DIE:
		return
	if state == State.ATTACK:
		state = State.WALK
		_attack_timer = 0.0
		if anim and anim.has_method("play"):
			anim.play(anim_walk)

func _process(delta):
	global_position.y = floor_y

	match state:
		State.WALK:
			global_position.x -= move_speed * delta
			if anim:
				anim.set("flip_h", sprite_faces_right)
			if global_position.x <= contact_x:
				state = State.ATTACK
				_attack_timer = 0.15
				if anim and anim.has_method("play"):
					anim.play(anim_attack)

		State.ATTACK:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_timer = attack_interval
				emit_signal("attacking_tower", self, attack_damage)

		State.DIE:
			pass

	queue_redraw()

func _draw():
	if not show_hp_bar:
		return
	if max_hp <= 0.0:
		return
	if state == State.DIE:
		return

	var pct := clampf(hp / max_hp, 0.0, 1.0)
	var bg_rect := Rect2(hp_bar_offset, hp_bar_size)
	var fill_rect := Rect2(hp_bar_offset + Vector2(1.0, 1.0), Vector2((hp_bar_size.x - 2.0) * pct, hp_bar_size.y - 2.0))

	draw_rect(bg_rect, Color(0.05, 0.05, 0.05, 0.8), true)
	draw_rect(fill_rect, Color(0.88, 0.18, 0.18, 0.95), true)
	draw_rect(bg_rect, Color(0.95, 0.95, 0.95, 0.9), false, 1.0)

func _die():
	if state == State.DIE:
		return

	state = State.DIE
	if anim and anim.has_method("play"):
		anim.play(anim_die)

	emit_signal("died", self)
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _on_anim_finished():
	pass
