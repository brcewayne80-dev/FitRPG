extends Node2D
class_name DebugDraw

var game: Node2D

@onready var tower: Node2D = $"../Tower"
@onready var muzzle_1: Marker2D = $"../Tower/Archer1Muzzle"
@onready var muzzle_2: Marker2D = $"../Tower/Archer2Muzzle"
@onready var muzzle_3: Marker2D = $"../Tower/Archer3Muzzle"
@onready var enemies_root: Node2D = $"../Enemies"
@onready var projectiles_root: Node2D = $"../Projectiles"

func _ready() -> void:
	game = get_parent()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_draw_lanes()
	_draw_tower_and_archers()
	_draw_wall()
	_draw_enemies()
	_draw_projectiles()

func _draw_lanes() -> void:
	if tower == null or muzzle_1 == null or muzzle_2 == null or muzzle_3 == null:
		return

	var left_x: float = tower.global_position.x - 1100.0
	var right_x: float = tower.global_position.x + 260.0

	var ys := [
		muzzle_1.global_position.y,
		muzzle_2.global_position.y,
		muzzle_3.global_position.y
	]

	for y in ys:
		draw_line(Vector2(left_x, y), Vector2(right_x, y), Color(0.28, 0.28, 0.28, 1.0), 10.0)
		draw_line(Vector2(left_x, y), Vector2(right_x, y), Color(0.42, 0.42, 0.42, 1.0), 2.0)

func _draw_tower_and_archers() -> void:
	if tower == null or muzzle_1 == null or muzzle_2 == null or muzzle_3 == null:
		return

	var tower_pos: Vector2 = tower.global_position
	var tower_size: Vector2 = Vector2(70.0, 110.0)
	var rect: Rect2 = Rect2(tower_pos - tower_size * 0.5, tower_size)

	# Tower block
	draw_rect(rect, Color(0.12, 0.12, 0.12, 1.0), true)
	draw_rect(rect, Color(0.7, 0.7, 0.7, 1.0), false, 2.0)

	# Archer dots (using muzzle markers)
	draw_circle(muzzle_1.global_position, 6.0, Color(0.95, 0.95, 0.95, 1.0))
	draw_circle(muzzle_2.global_position, 6.0, Color(0.95, 0.95, 0.95, 1.0))
	draw_circle(muzzle_3.global_position, 6.0, Color(0.95, 0.95, 0.95, 1.0))

	# Tower HP bar (above tower)
	var tower_hp: float = 0.0
	var tower_max: float = 0.0
	if game != null:
		# Safe-ish: assumes these vars exist on the parent script
		tower_hp = float(game.get("tower_hp"))
		tower_max = float(game.get("tower_max_hp"))

	if tower_max > 0.0:
		var hp_pct: float = clampf(tower_hp / tower_max, 0.0, 1.0)
		var bar_size: Vector2 = Vector2(tower_size.x, 8.0)
		var bar_pos: Vector2 = rect.position + Vector2(0.0, -14.0)

		draw_rect(Rect2(bar_pos, bar_size), Color(0.08, 0.08, 0.08, 1.0), true)
		draw_rect(Rect2(bar_pos, Vector2(bar_size.x * hp_pct, bar_size.y)),
			Color(0.9, 0.2 + 0.6 * hp_pct, 0.2, 1.0), true)

func _draw_wall() -> void:
	if tower == null:
		return

	# Read wall vars from DefendValley.gd
	var wall_hp: float = 0.0
	var wall_max: float = 0.0
	if game != null:
		wall_hp = float(game.get("wall_hp"))
		wall_max = float(game.get("wall_max_hp"))

	if wall_max <= 0.0:
		return

	var pct: float = clampf(wall_hp / wall_max, 0.0, 1.0)

	# Visual wall slab (in front of tower)
	var slab_pos: Vector2 = tower.global_position + Vector2(-60.0, 0.0)
	var slab_size: Vector2 = Vector2(22.0, 96.0)
	var slab_rect: Rect2 = Rect2(slab_pos - slab_size * 0.5, slab_size)

	var slab_col := Color(0.18, 0.18, 0.18, 1.0)
	if pct <= 0.05:
		slab_col = Color(0.10, 0.10, 0.10, 1.0)

	draw_rect(slab_rect, slab_col, true)
	draw_rect(slab_rect, Color(0.6, 0.6, 0.6, 1.0), false, 2.0)

	# Wall HP bar (next to tower)
	var base_pos: Vector2 = tower.global_position + Vector2(-90.0, 0.0)
	var size: Vector2 = Vector2(18.0, 90.0)
	var outer: Rect2 = Rect2(base_pos - size * 0.5, size)

	# Color shifts green -> red
	var col := Color(1.0 - pct, 0.25 + 0.6 * pct, 0.25, 1.0)

	draw_rect(outer, Color(0.08, 0.08, 0.08, 1.0), true)
	draw_rect(outer, Color(0.7, 0.7, 0.7, 1.0), false, 2.0)

	var fill_h: float = size.y * pct
	var fill: Rect2 = Rect2(
		outer.position.x,
		outer.position.y + (size.y - fill_h),
		size.x,
		fill_h
	)

	draw_rect(fill, col, true)

func _draw_enemies() -> void:
	if enemies_root == null:
		return

	for child in enemies_root.get_children():
		var e := child as Enemy
		if e == null:
			continue

		var col := _color_for_enemy(e)
		var r := _radius_for_enemy(e)
		draw_circle(e.global_position, r, col)
		draw_circle(e.global_position, r, Color(0.0, 0.0, 0.0, 0.85), false, 2.0)

func _draw_projectiles() -> void:
	if projectiles_root == null:
		return

	for child in projectiles_root.get_children():
		if child is Node2D:
			draw_circle(child.global_position, 2.5, Color(1.0, 0.95, 0.2, 1.0))

func _color_for_enemy(e: Enemy) -> Color:
	match e.kind:
		Enemy.Kind.BARBARIAN: return Color(0.85, 0.35, 0.35, 1.0)
		Enemy.Kind.ORC:      return Color(0.35, 0.8, 0.35, 1.0)
		Enemy.Kind.FLYER:    return Color(0.35, 0.55, 0.95, 1.0)
		Enemy.Kind.CATAPULT: return Color(0.8, 0.7, 0.25, 1.0)
	return Color(1.0, 1.0, 1.0, 1.0)

func _radius_for_enemy(e: Enemy) -> float:
	match e.kind:
		Enemy.Kind.BARBARIAN: return 10.0
		Enemy.Kind.ORC:      return 14.0
		Enemy.Kind.FLYER:    return 9.0
		Enemy.Kind.CATAPULT: return 12.0
	return 10.0
