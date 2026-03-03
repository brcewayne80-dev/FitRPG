extends Node2D
class_name Catapult

signal fired(muzzle_pos: Vector2)

@export var anim_fire: StringName = &"fire"
@export var rearm_time: float = 0.6
@export var fire_frame_index: int = 2 # frame 3 (0-based)

@onready var anim: AnimatedSprite2D = $Anim
@onready var muzzle: Marker2D = $Muzzle

var _armed := true
var _pending_shot := false

func _ready() -> void:
	if anim and not anim.frame_changed.is_connected(_on_anim_frame_changed):
		anim.frame_changed.connect(_on_anim_frame_changed)

func fire() -> void:
	if not _armed:
		return
	_armed = false
	_pending_shot = true

	if anim:
		anim.frame = 0
		anim.play(anim_fire)
	else:
		emit_signal("fired", muzzle.global_position)
		_pending_shot = false

	# Rearm on a fixed timer so firing works even if the fire animation loops.
	await get_tree().create_timer(rearm_time).timeout
	_armed = true

func _on_anim_frame_changed() -> void:
	if not _pending_shot:
		return
	if anim == null:
		return
	if anim.animation != anim_fire:
		return
	if anim.frame != fire_frame_index:
		return

	emit_signal("fired", muzzle.global_position)
	_pending_shot = false
