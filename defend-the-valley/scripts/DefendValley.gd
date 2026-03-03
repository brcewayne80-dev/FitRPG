extends Node2D

@export var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
@export var projectile_scene: PackedScene = preload("res://scenes/Projectile.tscn")
const CameraShakeScript = preload("res://scripts/CameraShake.gd")

# Tower HP
@export var tower_max_hp: float = 250.0
var tower_hp: float
@export var outpost_max_hp: float = 140.0
var outpost_hp: float = 0.0

# Floor (single lane)
@export var floor_y: float = 578.0
@export var floor_jitter_px: float = 10.0

# Waves
@export var seconds_between_waves: float = 2.0
@export var wave_send_countdown_seconds: float = 10.0
@export var enemies_per_wave_base: int = 5
@export var enemies_per_wave_growth: float = 1.12
@export var spawn_interval: float = 0.30

# Scaling
@export var enemy_hp_growth: float = 1.08
@export var enemy_speed_growth: float = 1.01
@export var enemy_damage_growth: float = 1.03

# ✅ Make orcs easier to kill (multiply final HP)
@export var orc_hp_multiplier: float = 0.55
@export var large_enemy_start_wave: int = 25
@export var large_enemy_spawn_chance: float = 0.35
@export var large_enemy_scale_multiplier: float = 1.25
@export var large_enemy_hp_multiplier: float = 1.4

# Spawn placement (right side)
@export var spawn_x_offset: float = 300.0

# Archer shooting
@export var archer_damage: float = 8.0
@export var archer_fire_rate: float = 0.7
@export var archer_accuracy: float = 1.0
@export var arrow_spawn_x_nudge: float = 8.0

# Upgrade tuning
@export var damage_upgrade_step: float = 2.0
@export var speed_upgrade_step: float = 0.08
@export var tower_hp_upgrade_step: float = 40.0
@export var tower_archer_upgrade_step: int = 1
@export var outpost_damage_upgrade_step: float = 0.08
@export var outpost_hp_upgrade_step: float = 25.0
@export var outpost_archer_upgrade_step: int = 1
@export var catapult_damage: float = 30.0
@export var catapult_fire_rate: float = 0.28
@export var catapult_damage_upgrade_step: float = 8.0
@export var catapult_speed_upgrade_step: float = 0.04
@export var catapult_aoe_upgrade_step: float = 15.0
@export var outpost_fire_rate: float = 0.55
@export var outpost_damage_scale: float = 0.85
@export var outpost_wave_hp_scale: float = 1.2
@export var outpost_wave_damage_scale: float = 0.55

# Ballistic aiming
@export var speed_hint: float = 700.0
@export var min_shot_time: float = 0.35
@export var max_shot_time: float = 0.95

# NodePaths
@export var enemies_root_path: NodePath = ^"Enemies"
@export var projectiles_root_path: NodePath = ^"Projectiles"
@export var contact_point_path: NodePath = ^"Tower/ContactPoint"
@export var muzzle1_path: NodePath = ^"Tower/Archer1Muzzle"
@export var muzzle2_path: NodePath = ^"Tower/Archer2Muzzle"
@export var muzzle3_path: NodePath = ^"Tower/Archer3Muzzle"
@export var lbl_wave_path: NodePath = ^"UI/LblWave"
@export var lbl_tower_hp_path: NodePath = ^"UI/LblTowerHP"
@export var lbl_status_path: NodePath = ^"UI/LblStatus"
@export var lbl_dbg_path: NodePath = ^"UI/Dbg"
@export var ui_root_path: NodePath = ^"UI"
@export var structures_root_path: NodePath = ^"Structures"
@export var outpost_path: NodePath = ^"Outpost"

@export var game_over_font_size: int = 72
@export var retry_font_size: int = 32

@export var camera_path: NodePath = ^"Camera2D"

# Shake tuning
@export var shake_on_tower_hit: float = 0.18
@export var shake_on_orc_death: float = 0.10
@export var show_structure_hp_bars: bool = true
@export var tower_hp_bar_size: Vector2 = Vector2(84.0, 10.0)
@export var outpost_hp_bar_size: Vector2 = Vector2(72.0, 8.0)
@export var tower_hp_bar_offset_from_contact: Vector2 = Vector2(-42.0, 36.0)
@export var outpost_hp_bar_offset_from_contact: Vector2 = Vector2(-36.0, 28.0)

# Catapult tuning
@export var catapult_path: NodePath = ^"Catapult"
@export var catapult_rock_scene: PackedScene = preload("res://scenes/CatapultRock.tscn")

@export var catapult_aoe_radius: float = 110.0
@export var catapult_gravity: float = 1200.0
@export var catapult_speed_multiplier: float = 0.65
@export var catapult_min_target_distance_from_tower: float = 220.0
@export var speed_up_scale: float = 2.0



var enemies_root: Node2D
var projectiles_root: Node2D
var tower_root: Node2D
var tower_sprite: Sprite2D
var contact_point: Marker2D
var muzzle_1: Marker2D
var muzzle_2: Marker2D
var muzzle_3: Marker2D
var lbl_wave: Label
var lbl_tower_hp: Label
var lbl_status: Label
var lbl_dbg: Label
var retry_button: Button
var cam: CameraShakeScript
var ui_root: CanvasLayer
var structures_root: Node2D
var upgrade_panel: PanelContainer
var btn_upgrade_catapult: Button
var btn_upgrade_catapult_damage: Button
var btn_upgrade_catapult_speed: Button
var btn_upgrade_catapult_aoe: Button
var btn_upgrade_outpost: Button
var btn_upgrade_tower_archer: Button
var btn_upgrade_outpost_archer: Button
var btn_upgrade_outpost_damage: Button
var btn_upgrade_outpost_speed: Button
var btn_upgrade_outpost_hp: Button
var lbl_structure_stats: Label
var btn_speed_up: Button
var btn_send_wave: Button
var btn_upgrade_menu: Button

var wave: int = 1
var _spawning: bool = false
var _pending_spawns: int = 0
var _waiting_for_next_wave: bool = false
var _game_over: bool = false
var _in_upgrade_break: bool = false
var catapult_node: Catapult
var _speed_up_enabled: bool = false


# ✅ Track living enemies instead of relying on get_child_count()
var _alive_enemies: int = 0

var _spawn_timer: Timer
var _wave_timer: Timer

var _archer_cd := [0.0, 0.0, 0.0]
var _outpost_archer_cd := [0.0, 0.0, 0.0]
var _catapult_cd: float = 0.0
var _tower_archer_count: int = 1
var _outpost_archer_count: int = 1
var _catapult_unlocked: bool = false
var _outpost_unlocked: bool = false
var _outpost_instance: Node2D
var _outpost_sprite: Sprite2D
var _outpost_contact_point: Marker2D
var _outpost_muzzles: Array[Marker2D] = []
var _outpost_runtime_max_hp: float = 0.0
var _outpost_runtime_damage_scale: float = 0.0
var _base_archer_damage: float = 0.0
var _base_archer_fire_rate: float = 0.0
var _base_tower_max_hp: float = 0.0
var _base_outpost_damage_scale: float = 0.0
var _base_outpost_fire_rate: float = 0.0
var _base_outpost_max_hp: float = 0.0
var _base_catapult_damage: float = 0.0
var _base_catapult_fire_rate: float = 0.0
var _base_catapult_aoe: float = 0.0

# debug
var _last_spawned_total: int = 0
var _last_speed_scale: float = 1.0
var _last_target_dx: float = -1.0
var _interwave_status_prefix: String = ""
var _interwave_countdown_remaining: float = 0.0
var _interwave_countdown_paused: bool = false

func _ready() -> void:
	get_tree().paused = false
	randomize()
	_set_speed_up(false)
	_ensure_controller_input_actions()

	var save_data := SaveData.new()
	save_data.load_or_init()
	_cache_base_upgrade_stats()
	wave = maxi(1, GameSession.start_wave)
	_apply_saved_upgrades(save_data)
	GameSession.loading_from_save = false
	GameSession.start_wave = wave

	tower_hp = tower_max_hp
	_outpost_runtime_max_hp = outpost_max_hp
	_outpost_runtime_damage_scale = outpost_damage_scale
	if _outpost_unlocked:
		_apply_outpost_scaling_for_wave(wave)
		outpost_hp = _get_outpost_max_hp_value()
	else:
		outpost_hp = 0.0
	_resolve_nodes()
	_build_upgrade_ui()
	_set_outpost_active(_outpost_unlocked)
	_set_catapult_active(_catapult_unlocked)

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_tick)
	add_child(_spawn_timer)

	_wave_timer = Timer.new()
	_wave_timer.wait_time = wave_send_countdown_seconds
	_wave_timer.one_shot = true
	_wave_timer.timeout.connect(_on_wave_countdown_timeout)
	add_child(_wave_timer)

	# clear any pre-placed enemies
	_alive_enemies = 0
	if is_instance_valid(enemies_root):
		for c in enemies_root.get_children():
			c.queue_free()

	if lbl_status:
		lbl_status.text = "Wave %d" % wave

	_update_ui()
	_enter_wave_setup_state()

func _ensure_controller_input_actions() -> void:
	_ensure_action("ui_accept", [JOY_BUTTON_A], [KEY_ENTER, KEY_SPACE])
	_ensure_action("ui_cancel", [JOY_BUTTON_B], [KEY_ESCAPE])
	_ensure_action("ui_up", [JOY_BUTTON_DPAD_UP], [KEY_UP])
	_ensure_action("ui_down", [JOY_BUTTON_DPAD_DOWN], [KEY_DOWN])
	_ensure_action("ui_left", [JOY_BUTTON_DPAD_LEFT], [KEY_LEFT])
	_ensure_action("ui_right", [JOY_BUTTON_DPAD_RIGHT], [KEY_RIGHT])

	# Gameplay shortcuts for controller.
	_ensure_action("dv_send_wave", [JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_START], [])
	_ensure_action("dv_upgrade", [JOY_BUTTON_X], [])
	_ensure_action("dv_speed_toggle", [JOY_BUTTON_Y], [])
	_ensure_action("dv_back", [JOY_BUTTON_B], [])

func _ensure_action(action: StringName, joypad_buttons: Array, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for button_index in joypad_buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = int(button_index)
		_add_action_event_if_missing(action, jb)
	for keycode in keycodes:
		var k := InputEventKey.new()
		k.keycode = int(keycode)
		_add_action_event_if_missing(action, k)

func _add_action_event_if_missing(action: StringName, event_to_add: InputEvent) -> void:
	for existing in InputMap.action_get_events(action):
		if existing.as_text() == event_to_add.as_text():
			return
	InputMap.action_add_event(action, event_to_add)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if _game_over:
		if (event.is_action_pressed("ui_accept") or event.is_action_pressed("dv_send_wave")) and retry_button != null and is_instance_valid(retry_button):
			_on_retry_pressed()
		return

	if event.is_action_pressed("dv_speed_toggle"):
		_on_speed_up_pressed()
		return

	if event.is_action_pressed("dv_send_wave"):
		_on_send_wave_pressed()
		return

	if event.is_action_pressed("dv_upgrade"):
		if upgrade_panel != null and upgrade_panel.visible:
			_on_close_upgrade_pressed()
		else:
			_on_open_upgrade_pressed()
		return

	if event.is_action_pressed("dv_back") and upgrade_panel != null and upgrade_panel.visible:
		_on_close_upgrade_pressed()
		return

func _resolve_nodes() -> void:
	enemies_root = get_node_or_null(enemies_root_path) as Node2D
	projectiles_root = get_node_or_null(projectiles_root_path) as Node2D
	tower_root = get_node_or_null(^"Tower") as Node2D
	tower_sprite = get_node_or_null(^"Tower/Tower") as Sprite2D
	contact_point = get_node_or_null(contact_point_path) as Marker2D

	muzzle_1 = get_node_or_null(muzzle1_path) as Marker2D
	muzzle_2 = get_node_or_null(muzzle2_path) as Marker2D
	muzzle_3 = get_node_or_null(muzzle3_path) as Marker2D

	lbl_wave = get_node_or_null(lbl_wave_path) as Label
	lbl_tower_hp = get_node_or_null(lbl_tower_hp_path) as Label
	lbl_status = get_node_or_null(lbl_status_path) as Label
	lbl_dbg = get_node_or_null(lbl_dbg_path) as Label
	ui_root = get_node_or_null(ui_root_path) as CanvasLayer
	structures_root = get_node_or_null(structures_root_path) as Node2D
	_outpost_instance = get_node_or_null(outpost_path) as Node2D
	if _outpost_instance != null:
		_outpost_sprite = _outpost_instance.get_node_or_null("Sprite2D") as Sprite2D
	if _outpost_instance != null:
		_outpost_contact_point = _outpost_instance.get_node_or_null("OutpostContactPoint") as Marker2D
	catapult_node = get_node_or_null(catapult_path) as Catapult
	if catapult_node == null:
		catapult_node = get_node_or_null(^"Tower/Catapult") as Catapult
	if catapult_node and not catapult_node.fired.is_connected(_on_catapult_fired):
		catapult_node.fired.connect(_on_catapult_fired)


	cam = get_node_or_null(camera_path) as CameraShakeScript



func _process(delta: float) -> void:
	if _game_over:
		return
	if tower_hp <= 0.0:
		_update_ui()
		return

	if _has_enemy_in_camera_view():
		_tick_archers(delta)
		_tick_catapult(delta)
		_tick_outpost_archer(delta)
	_try_advance_wave()
	_update_ui()
	queue_redraw()

func _start_wave() -> void:
	if tower_hp <= 0.0:
		return
	if _in_upgrade_break:
		return

	_waiting_for_next_wave = false
	if is_instance_valid(_wave_timer):
		_wave_timer.stop()
	_alive_enemies = 0

	if lbl_status:
		lbl_status.text = "Wave %d" % wave

	if wave <= 5:
		_pending_spawns = wave
	else:
		var count_f := 5.0 * pow(enemies_per_wave_growth, float(wave - 5))
		_pending_spawns = max(5, int(round(count_f)))
	_last_spawned_total = _pending_spawns

	_spawning = true
	_spawn_timer.start()

func _on_spawn_tick() -> void:
	if not _spawning:
		_spawn_timer.stop()
		return

	if _pending_spawns <= 0:
		_spawning = false
		_spawn_timer.stop()
		_try_advance_wave()
		return

	_spawn_orc_for_wave(wave)
	_pending_spawns -= 1

func _spawn_orc_for_wave(w: int) -> void:
	if not is_instance_valid(enemies_root) or not is_instance_valid(contact_point):
		return

	var inst := enemy_scene.instantiate()
	var e := inst as Node2D
	if e == null:
		if lbl_status:
			lbl_status.text = "Enemy.tscn root must be a Node2D."
		if inst != null:
			inst.queue_free()
		return
	if not e.has_method("configure_spawn"):
		if lbl_status:
			lbl_status.text = "Enemy.tscn root script must implement configure_spawn()."
		e.queue_free()
		return

	enemies_root.add_child(e)

	var contact_x := _get_active_contact_x()
	var vp_w := get_viewport_rect().size.x
	var spawn_x := contact_x + vp_w + spawn_x_offset

	var jitter := randf_range(-floor_jitter_px, floor_jitter_px)
	var fy := floor_y + jitter
	var spawn_pos := Vector2(spawn_x, fy)

	var growth_steps := maxi(0, w - 5)
	var hp_scale := pow(enemy_hp_growth, float(growth_steps)) * orc_hp_multiplier
	var speed_scale := pow(enemy_speed_growth, float(growth_steps))
	var dmg_scale := pow(enemy_damage_growth, float(growth_steps))
	var is_large_enemy := w >= large_enemy_start_wave and randf() <= clampf(large_enemy_spawn_chance, 0.0, 1.0)
	if is_large_enemy:
		hp_scale *= maxf(1.0, large_enemy_hp_multiplier)
		var large_scale := maxf(1.0, large_enemy_scale_multiplier)
		e.scale = Vector2.ONE * large_scale
	_last_speed_scale = speed_scale

	e.configure_spawn(spawn_pos, contact_x, fy, hp_scale, speed_scale, dmg_scale)

	# ✅ Count living enemies (per wave)
	_alive_enemies += 1

	e.attacking_tower.connect(_on_enemy_attacking_tower)
	e.died.connect(_on_enemy_died)

func _get_active_contact_x() -> float:
	if _is_outpost_alive() and is_instance_valid(_outpost_contact_point):
		return _outpost_contact_point.global_position.x
	if is_instance_valid(contact_point):
		return contact_point.global_position.x
	return 0.0

func _is_outpost_alive() -> bool:
	return _outpost_unlocked and outpost_hp > 0.0 and is_instance_valid(_outpost_instance) and _outpost_instance.visible

func _get_outpost_max_hp_value() -> float:
	return _outpost_runtime_max_hp if _outpost_runtime_max_hp > 0.0 else outpost_max_hp

func _get_outpost_damage_scale_value() -> float:
	return _outpost_runtime_damage_scale if _outpost_runtime_damage_scale > 0.0 else outpost_damage_scale

func _apply_outpost_scaling_for_wave(purchase_wave: int) -> void:
	var w := maxi(1, purchase_wave)
	var hp_growth := pow(maxf(1.0, enemy_damage_growth), float(w - 1))
	var dmg_growth := pow(maxf(1.0, enemy_hp_growth), float(w - 1))
	var hp_mult := maxf(1.0, hp_growth * maxf(0.1, outpost_wave_hp_scale))
	var dmg_mult := maxf(1.0, dmg_growth * maxf(0.1, outpost_wave_damage_scale))
	_outpost_runtime_max_hp = outpost_max_hp * hp_mult
	_outpost_runtime_damage_scale = outpost_damage_scale * dmg_mult

func _is_catapult_alive() -> bool:
	return _catapult_unlocked and is_instance_valid(catapult_node) and catapult_node.visible

func _on_enemy_attacking_tower(_enemy, damage: float) -> void:
	if tower_hp <= 0.0:
		return

	if _is_outpost_alive():
		outpost_hp = max(0.0, outpost_hp - damage)
		if outpost_hp <= 0.0:
			_destroy_outpost()
	else:
		tower_hp = max(0.0, tower_hp - damage)

	if cam:
		cam.add_trauma(shake_on_tower_hit)

	if tower_hp <= 0.0:
		if lbl_status:
			lbl_status.text = "DEFEAT — Tower Down"
		_trigger_game_over()

func _on_enemy_died(_enemy) -> void:
	_alive_enemies = max(0, _alive_enemies - 1)

	if cam:
		cam.add_trauma(shake_on_orc_death)

	_try_advance_wave()


func _try_advance_wave() -> void:
	if tower_hp <= 0.0:
		return
	if _spawning:
		return
	if _waiting_for_next_wave:
		return
	if _in_upgrade_break:
		return

	if _alive_enemies <= 0:
		var cleared_wave := wave
		wave += 1
		_save_progress(wave)
		_enter_wave_setup_state("Wave %d cleared" % cleared_wave)

func _on_wave_countdown_timeout() -> void:
	if _game_over:
		return
	if not _in_upgrade_break:
		return
	if not _waiting_for_next_wave:
		return
	_send_wave_now()
func _trigger_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	_spawning = false
	_in_upgrade_break = false
	_show_upgrade_panel(false)
	_refresh_interwave_ui()

	if is_instance_valid(_spawn_timer):
		_spawn_timer.stop()
	if is_instance_valid(_wave_timer):
		_wave_timer.stop()

	if lbl_wave:
		lbl_wave.text = "Wave: %d" % wave

	if lbl_status:
		lbl_status.text = "Game Over\nWave: %d" % wave
		lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_status.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl_status.offset_left = 0.0
		lbl_status.offset_top = 0.0
		lbl_status.offset_right = 0.0
		lbl_status.offset_bottom = 0.0
		lbl_status.add_theme_font_size_override("font_size", game_over_font_size)
		_show_retry_button()

	get_tree().paused = true
	_save_progress(wave)

func _cache_base_upgrade_stats() -> void:
	if _base_archer_damage <= 0.0:
		_base_archer_damage = archer_damage
	if _base_archer_fire_rate <= 0.0:
		_base_archer_fire_rate = archer_fire_rate
	if _base_tower_max_hp <= 0.0:
		_base_tower_max_hp = tower_max_hp
	if _base_outpost_damage_scale <= 0.0:
		_base_outpost_damage_scale = outpost_damage_scale
	if _base_outpost_fire_rate <= 0.0:
		_base_outpost_fire_rate = outpost_fire_rate
	if _base_outpost_max_hp <= 0.0:
		_base_outpost_max_hp = outpost_max_hp
	if _base_catapult_damage <= 0.0:
		_base_catapult_damage = catapult_damage
	if _base_catapult_fire_rate <= 0.0:
		_base_catapult_fire_rate = catapult_fire_rate
	if _base_catapult_aoe <= 0.0:
		_base_catapult_aoe = catapult_aoe_radius

func _apply_saved_upgrades(save_data: SaveData) -> void:
	var up := save_data.upgrades
	var damage_level := maxi(0, int(up.get("archer_power", 0)))
	var speed_level := maxi(0, int(up.get("archer_speed", 0)))
	var tower_hp_level := maxi(0, int(up.get("tower_health", 0)))
	var tower_archer_level := maxi(0, int(up.get("tower_archers", 0)))
	var outpost_archer_level := maxi(0, int(up.get("outpost_archers", 0)))
	var outpost_damage_level := maxi(0, int(up.get("outpost_power", 0)))
	var outpost_speed_level := maxi(0, int(up.get("outpost_speed", 0)))
	var outpost_hp_level := maxi(0, int(up.get("outpost_strength", 0)))
	var catapult_damage_level := maxi(0, int(up.get("catapult_power", 0)))
	var catapult_speed_level := maxi(0, int(up.get("catapult_speed", 0)))
	var catapult_aoe_level := maxi(0, int(up.get("catapult_aoe", 0)))

	archer_damage = _base_archer_damage + (damage_upgrade_step * float(damage_level))
	archer_fire_rate = _base_archer_fire_rate + (speed_upgrade_step * float(speed_level))
	tower_max_hp = _base_tower_max_hp + (tower_hp_upgrade_step * float(tower_hp_level))
	_tower_archer_count = clampi(1 + tower_archer_level, 1, 3)
	_catapult_unlocked = int(up.get("catapult_unlocked", 0)) > 0
	_outpost_unlocked = int(up.get("outpost_unlocked", 0)) > 0
	_outpost_archer_count = clampi(1 + outpost_archer_level, 1, 3)
	outpost_damage_scale = _base_outpost_damage_scale + (outpost_damage_upgrade_step * float(outpost_damage_level))
	outpost_fire_rate = _base_outpost_fire_rate + (speed_upgrade_step * float(outpost_speed_level))
	outpost_max_hp = _base_outpost_max_hp + (outpost_hp_upgrade_step * float(outpost_hp_level))
	catapult_damage = _base_catapult_damage + (catapult_damage_upgrade_step * float(catapult_damage_level))
	catapult_fire_rate = _base_catapult_fire_rate + (catapult_speed_upgrade_step * float(catapult_speed_level))
	catapult_aoe_radius = _base_catapult_aoe + (catapult_aoe_upgrade_step * float(catapult_aoe_level))

func _get_upgrade_level_from_value(current: float, base_value: float, step_value: float) -> int:
	if step_value <= 0.0:
		return 0
	return maxi(0, int(round((current - base_value) / step_value)))

func _write_upgrade_max(save_data: SaveData, key: String, value: int) -> void:
	var current := maxi(0, int(save_data.upgrades.get(key, 0)))
	save_data.upgrades[key] = maxi(current, maxi(0, value))

func _write_runtime_upgrades_to_save(save_data: SaveData) -> void:
	_write_upgrade_max(save_data, "archer_power", _get_upgrade_level_from_value(archer_damage, _base_archer_damage, damage_upgrade_step))
	_write_upgrade_max(save_data, "archer_speed", _get_upgrade_level_from_value(archer_fire_rate, _base_archer_fire_rate, speed_upgrade_step))
	_write_upgrade_max(save_data, "tower_health", _get_upgrade_level_from_value(tower_max_hp, _base_tower_max_hp, tower_hp_upgrade_step))
	_write_upgrade_max(save_data, "tower_archers", maxi(0, _tower_archer_count - 1))
	_write_upgrade_max(save_data, "catapult_unlocked", 1 if _catapult_unlocked else 0)
	_write_upgrade_max(save_data, "catapult_power", _get_upgrade_level_from_value(catapult_damage, _base_catapult_damage, catapult_damage_upgrade_step))
	_write_upgrade_max(save_data, "catapult_speed", _get_upgrade_level_from_value(catapult_fire_rate, _base_catapult_fire_rate, catapult_speed_upgrade_step))
	_write_upgrade_max(save_data, "catapult_aoe", _get_upgrade_level_from_value(catapult_aoe_radius, _base_catapult_aoe, catapult_aoe_upgrade_step))
	_write_upgrade_max(save_data, "outpost_unlocked", 1 if _outpost_unlocked else 0)
	_write_upgrade_max(save_data, "outpost_archers", maxi(0, _outpost_archer_count - 1))
	_write_upgrade_max(save_data, "outpost_power", _get_upgrade_level_from_value(outpost_damage_scale, _base_outpost_damage_scale, outpost_damage_upgrade_step))
	_write_upgrade_max(save_data, "outpost_speed", _get_upgrade_level_from_value(outpost_fire_rate, _base_outpost_fire_rate, speed_upgrade_step))
	_write_upgrade_max(save_data, "outpost_strength", _get_upgrade_level_from_value(outpost_max_hp, _base_outpost_max_hp, outpost_hp_upgrade_step))

func _save_progress(w: int) -> void:
	var save_data := SaveData.new()
	save_data.load_or_init()
	if w > save_data.highest_wave_reached:
		save_data.highest_wave_reached = w
	_write_runtime_upgrades_to_save(save_data)
	save_data.save()

func _show_retry_button() -> void:
	if retry_button != null and is_instance_valid(retry_button):
		return
	if lbl_status == null:
		return

	retry_button = Button.new()
	retry_button.text = "Retry"
	retry_button.custom_minimum_size = Vector2(220.0, 64.0)
	retry_button.set_anchors_preset(Control.PRESET_CENTER)
	retry_button.position = Vector2(-110.0, 120.0)
	retry_button.add_theme_font_size_override("font_size", retry_font_size)
	retry_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	retry_button.pressed.connect(_on_retry_pressed)
	lbl_status.add_child(retry_button)

func _on_retry_pressed() -> void:
	_set_speed_up(false)
	GameSession.loading_from_save = true
	GameSession.start_wave = wave
	get_tree().paused = false
	get_tree().reload_current_scene()

func _enter_wave_setup_state(status_prefix: String = "") -> void:
	_spawning = false
	_waiting_for_next_wave = true
	_in_upgrade_break = true
	_show_upgrade_panel(false)
	_interwave_status_prefix = status_prefix if not status_prefix.is_empty() else "Prepare for Wave %d" % wave
	_interwave_countdown_paused = false
	_interwave_countdown_remaining = maxf(0.1, wave_send_countdown_seconds)
	_update_interwave_status_ui()
	if is_instance_valid(_wave_timer):
		_wave_timer.stop()
		_wave_timer.wait_time = _interwave_countdown_remaining
		_wave_timer.start()
	_refresh_upgrade_ui()
	_refresh_interwave_ui()

func _build_upgrade_ui() -> void:
	if ui_root == null:
		return

	btn_speed_up = Button.new()
	btn_speed_up.name = "BtnSpeedUp"
	btn_speed_up.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_speed_up.position = Vector2(-170.0, 12.0)
	btn_speed_up.custom_minimum_size = Vector2(160.0, 36.0)
	btn_speed_up.pressed.connect(_on_speed_up_pressed)
	ui_root.add_child(btn_speed_up)
	_update_speed_up_button_text()

	btn_send_wave = Button.new()
	btn_send_wave.name = "BtnSendWave"
	btn_send_wave.text = "Send Wave"
	btn_send_wave.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_send_wave.position = Vector2(-340.0, 12.0)
	btn_send_wave.custom_minimum_size = Vector2(160.0, 36.0)
	btn_send_wave.pressed.connect(_on_send_wave_pressed)
	ui_root.add_child(btn_send_wave)

	btn_upgrade_menu = Button.new()
	btn_upgrade_menu.name = "BtnUpgradeMenu"
	btn_upgrade_menu.text = "Upgrade"
	btn_upgrade_menu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_upgrade_menu.position = Vector2(-510.0, 12.0)
	btn_upgrade_menu.custom_minimum_size = Vector2(160.0, 36.0)
	btn_upgrade_menu.pressed.connect(_on_open_upgrade_pressed)
	ui_root.add_child(btn_upgrade_menu)

	lbl_structure_stats = Label.new()
	lbl_structure_stats.name = "LblStructureStats"
	lbl_structure_stats.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lbl_structure_stats.position = Vector2(-510.0, 56.0)
	lbl_structure_stats.custom_minimum_size = Vector2(500.0, 74.0)
	lbl_structure_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_structure_stats.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl_structure_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_structure_stats.text = "Tower: --\nOutpost: --\nCatapult: --"
	ui_root.add_child(lbl_structure_stats)

	upgrade_panel = PanelContainer.new()
	upgrade_panel.name = "UpgradePanel"
	upgrade_panel.visible = false
	upgrade_panel.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_panel.position = Vector2(-234.0, -198.0)
	upgrade_panel.custom_minimum_size = Vector2(468.0, 396.0)
	ui_root.add_child(upgrade_panel)

	var up_scroll := ScrollContainer.new()
	up_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	up_scroll.offset_left = 12.0
	up_scroll.offset_top = 10.0
	up_scroll.offset_right = -12.0
	up_scroll.offset_bottom = -10.0
	up_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	upgrade_panel.add_child(up_scroll)

	var up_vbox := VBoxContainer.new()
	up_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_vbox.add_theme_constant_override("separation", 10)
	up_scroll.add_child(up_vbox)

	var up_title := Label.new()
	up_title.text = "Upgrades"
	up_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	up_vbox.add_child(up_title)

	var btn_damage := Button.new()
	btn_damage.text = "+ Projectile Damage"
	btn_damage.pressed.connect(_on_upgrade_damage_pressed)
	up_vbox.add_child(btn_damage)

	var btn_speed := Button.new()
	btn_speed.text = "+ Fire Rate"
	btn_speed.pressed.connect(_on_upgrade_speed_pressed)
	up_vbox.add_child(btn_speed)

	var btn_hp := Button.new()
	btn_hp.text = "+ Tower Hit Points"
	btn_hp.pressed.connect(_on_upgrade_hp_pressed)
	up_vbox.add_child(btn_hp)

	btn_upgrade_tower_archer = Button.new()
	btn_upgrade_tower_archer.text = "+ Tower Archer"
	btn_upgrade_tower_archer.pressed.connect(_on_upgrade_tower_archer_pressed)
	up_vbox.add_child(btn_upgrade_tower_archer)

	btn_upgrade_catapult = Button.new()
	btn_upgrade_catapult.text = "Add Catapult"
	btn_upgrade_catapult.pressed.connect(_on_upgrade_catapult_pressed)
	up_vbox.add_child(btn_upgrade_catapult)

	var catapult_title := Label.new()
	catapult_title.text = "Catapult Upgrades"
	catapult_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	up_vbox.add_child(catapult_title)

	btn_upgrade_catapult_damage = Button.new()
	btn_upgrade_catapult_damage.text = "+ Catapult Damage"
	btn_upgrade_catapult_damage.pressed.connect(_on_upgrade_catapult_damage_pressed)
	up_vbox.add_child(btn_upgrade_catapult_damage)

	btn_upgrade_catapult_speed = Button.new()
	btn_upgrade_catapult_speed.text = "+ Catapult Fire Rate"
	btn_upgrade_catapult_speed.pressed.connect(_on_upgrade_catapult_speed_pressed)
	up_vbox.add_child(btn_upgrade_catapult_speed)

	btn_upgrade_catapult_aoe = Button.new()
	btn_upgrade_catapult_aoe.text = "+ Catapult Blast Radius"
	btn_upgrade_catapult_aoe.pressed.connect(_on_upgrade_catapult_aoe_pressed)
	up_vbox.add_child(btn_upgrade_catapult_aoe)

	btn_upgrade_outpost = Button.new()
	btn_upgrade_outpost.text = "Add Outpost Tower"
	btn_upgrade_outpost.pressed.connect(_on_upgrade_outpost_pressed)
	up_vbox.add_child(btn_upgrade_outpost)

	var outpost_title := Label.new()
	outpost_title.text = "Outpost Upgrades"
	outpost_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	up_vbox.add_child(outpost_title)

	btn_upgrade_outpost_archer = Button.new()
	btn_upgrade_outpost_archer.text = "+ Outpost Archer"
	btn_upgrade_outpost_archer.pressed.connect(_on_upgrade_outpost_archer_pressed)
	up_vbox.add_child(btn_upgrade_outpost_archer)

	btn_upgrade_outpost_damage = Button.new()
	btn_upgrade_outpost_damage.text = "+ Outpost Damage"
	btn_upgrade_outpost_damage.pressed.connect(_on_upgrade_outpost_damage_pressed)
	up_vbox.add_child(btn_upgrade_outpost_damage)

	btn_upgrade_outpost_speed = Button.new()
	btn_upgrade_outpost_speed.text = "+ Outpost Fire Rate"
	btn_upgrade_outpost_speed.pressed.connect(_on_upgrade_outpost_speed_pressed)
	up_vbox.add_child(btn_upgrade_outpost_speed)

	btn_upgrade_outpost_hp = Button.new()
	btn_upgrade_outpost_hp.text = "+ Outpost Hit Points"
	btn_upgrade_outpost_hp.pressed.connect(_on_upgrade_outpost_hp_pressed)
	up_vbox.add_child(btn_upgrade_outpost_hp)

	var btn_close := Button.new()
	btn_close.text = "Back"
	btn_close.pressed.connect(_on_close_upgrade_pressed)
	up_vbox.add_child(btn_close)

	_refresh_upgrade_ui()
	_refresh_interwave_ui()

func _show_upgrade_panel(show: bool) -> void:
	if upgrade_panel:
		upgrade_panel.visible = show

func _refresh_interwave_ui() -> void:
	var interwave := _waiting_for_next_wave and _in_upgrade_break and not _game_over
	if btn_send_wave:
		btn_send_wave.disabled = not interwave
		btn_send_wave.text = "Send Wave"
	if btn_upgrade_menu:
		btn_upgrade_menu.disabled = not interwave
	if interwave and (upgrade_panel == null or not upgrade_panel.visible):
		_focus_interwave_button()

func _update_interwave_status_ui() -> void:
	var interwave := _waiting_for_next_wave and _in_upgrade_break and not _game_over
	if not interwave:
		if btn_send_wave:
			btn_send_wave.text = "Send Wave"
		return
	var remaining := 0
	if _interwave_countdown_paused:
		remaining = maxi(0, ceili(_interwave_countdown_remaining))
	elif is_instance_valid(_wave_timer):
		remaining = maxi(0, ceili(_wave_timer.time_left))
	if btn_send_wave:
		btn_send_wave.text = "Send Wave (%ds)" % remaining
	if lbl_status:
		if _interwave_countdown_paused:
			lbl_status.text = "%s. Auto-send paused (%ds left)." % [_interwave_status_prefix, remaining]
		else:
			lbl_status.text = "%s. Auto-send in %ds." % [_interwave_status_prefix, remaining]

func _send_wave_now() -> void:
	if not _in_upgrade_break or not _waiting_for_next_wave or _game_over:
		return
	_waiting_for_next_wave = false
	_in_upgrade_break = false
	_interwave_countdown_paused = false
	_interwave_countdown_remaining = 0.0
	_show_upgrade_panel(false)
	_refresh_interwave_ui()
	_start_wave()

func _focus_interwave_button() -> void:
	if not _in_upgrade_break or not _waiting_for_next_wave:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		return
	if btn_send_wave != null and not btn_send_wave.disabled and btn_send_wave.visible:
		btn_send_wave.grab_focus()
	elif btn_upgrade_menu != null and not btn_upgrade_menu.disabled and btn_upgrade_menu.visible:
		btn_upgrade_menu.grab_focus()

func _focus_first_upgrade_button() -> void:
	if upgrade_panel == null:
		return
	for node in upgrade_panel.find_children("*", "Button", true, false):
		var b := node as Button
		if b == null:
			continue
		if not b.visible or b.disabled:
			continue
		b.grab_focus()
		return

func _on_speed_up_pressed() -> void:
	_set_speed_up(not _speed_up_enabled)

func _set_speed_up(enabled: bool) -> void:
	_speed_up_enabled = enabled
	var scale := speed_up_scale if _speed_up_enabled else 1.0
	Engine.time_scale = maxf(0.1, scale)
	_update_speed_up_button_text()

func _update_speed_up_button_text() -> void:
	if btn_speed_up == null:
		return
	var scale_label := "%.1fx" % [maxf(1.0, speed_up_scale)]
	btn_speed_up.text = "Speed %s: %s" % [scale_label, "ON" if _speed_up_enabled else "OFF"]

func _refresh_upgrade_ui() -> void:
	if btn_upgrade_tower_archer:
		btn_upgrade_tower_archer.disabled = _tower_archer_count >= 3
		btn_upgrade_tower_archer.text = "Tower Archers Maxed" if _tower_archer_count >= 3 else "+ Tower Archer (%d/3)" % _tower_archer_count
	if btn_upgrade_catapult:
		var catapult_alive := _is_catapult_alive()
		btn_upgrade_catapult.disabled = catapult_alive
		if catapult_alive:
			btn_upgrade_catapult.text = "Catapult Added"
		else:
			btn_upgrade_catapult.text = "Rebuild Catapult" if _catapult_unlocked else "Add Catapult"
	var catapult_upgrade_locked := not _catapult_unlocked
	if btn_upgrade_catapult_damage:
		btn_upgrade_catapult_damage.disabled = catapult_upgrade_locked
		btn_upgrade_catapult_damage.text = "Unlock Catapult First" if catapult_upgrade_locked else "+ Catapult Damage (%d)" % int(round(catapult_damage))
	if btn_upgrade_catapult_speed:
		btn_upgrade_catapult_speed.disabled = catapult_upgrade_locked
		btn_upgrade_catapult_speed.text = "Unlock Catapult First" if catapult_upgrade_locked else "+ Catapult Fire Rate (%.2f/s)" % catapult_fire_rate
	if btn_upgrade_catapult_aoe:
		btn_upgrade_catapult_aoe.disabled = catapult_upgrade_locked
		btn_upgrade_catapult_aoe.text = "Unlock Catapult First" if catapult_upgrade_locked else "+ Catapult Blast Radius (%.0f)" % catapult_aoe_radius
	if btn_upgrade_outpost:
		var outpost_alive := _is_outpost_alive()
		btn_upgrade_outpost.disabled = outpost_alive
		if outpost_alive:
			btn_upgrade_outpost.text = "Outpost Added"
		else:
			btn_upgrade_outpost.text = "Rebuild Outpost Tower" if _outpost_unlocked else "Add Outpost Tower"
	var outpost_upgrade_locked := not _outpost_unlocked
	if btn_upgrade_outpost_archer:
		btn_upgrade_outpost_archer.disabled = outpost_upgrade_locked or _outpost_archer_count >= 3
		if outpost_upgrade_locked:
			btn_upgrade_outpost_archer.text = "Unlock Outpost First"
		elif _outpost_archer_count >= 3:
			btn_upgrade_outpost_archer.text = "Outpost Archers Maxed"
		else:
			btn_upgrade_outpost_archer.text = "+ Outpost Archer (%d/3)" % _outpost_archer_count
	if btn_upgrade_outpost_damage:
		btn_upgrade_outpost_damage.disabled = outpost_upgrade_locked
	if btn_upgrade_outpost_speed:
		btn_upgrade_outpost_speed.disabled = outpost_upgrade_locked
	if btn_upgrade_outpost_hp:
		btn_upgrade_outpost_hp.disabled = outpost_upgrade_locked

func _on_send_wave_pressed() -> void:
	_send_wave_now()

func _on_open_upgrade_pressed() -> void:
	if not _in_upgrade_break or not _waiting_for_next_wave or _game_over:
		return
	if is_instance_valid(_wave_timer) and not _interwave_countdown_paused:
		_interwave_countdown_remaining = maxf(0.1, _wave_timer.time_left)
		_wave_timer.stop()
		_interwave_countdown_paused = true
	_show_upgrade_panel(true)
	_refresh_upgrade_ui()
	_focus_first_upgrade_button()
	_update_interwave_status_ui()

func _on_close_upgrade_pressed() -> void:
	_show_upgrade_panel(false)
	if _in_upgrade_break and _waiting_for_next_wave and not _game_over and _interwave_countdown_paused and is_instance_valid(_wave_timer):
		_wave_timer.wait_time = maxf(0.1, _interwave_countdown_remaining)
		_wave_timer.start()
		_interwave_countdown_paused = false
	_refresh_upgrade_ui()
	_focus_interwave_button()
	_update_interwave_status_ui()

func _on_upgrade_damage_pressed() -> void:
	archer_damage += damage_upgrade_step
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_speed_pressed() -> void:
	archer_fire_rate += speed_upgrade_step
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_hp_pressed() -> void:
	tower_max_hp += tower_hp_upgrade_step
	tower_hp = min(tower_max_hp, tower_hp + tower_hp_upgrade_step)
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_tower_archer_pressed() -> void:
	if _tower_archer_count >= 3:
		return
	_tower_archer_count = clampi(_tower_archer_count + tower_archer_upgrade_step, 1, 3)
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_catapult_pressed() -> void:
	if _is_catapult_alive():
		return
	_catapult_unlocked = true
	_set_catapult_active(true)
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_catapult_damage_pressed() -> void:
	if not _catapult_unlocked:
		return
	catapult_damage += catapult_damage_upgrade_step
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_catapult_speed_pressed() -> void:
	if not _catapult_unlocked:
		return
	catapult_fire_rate += catapult_speed_upgrade_step
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_catapult_aoe_pressed() -> void:
	if not _catapult_unlocked:
		return
	catapult_aoe_radius += catapult_aoe_upgrade_step
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_outpost_pressed() -> void:
	if _is_outpost_alive():
		return
	_outpost_unlocked = true
	_outpost_archer_count = clampi(_outpost_archer_count, 1, 3)
	_apply_outpost_scaling_for_wave(wave)
	outpost_hp = _get_outpost_max_hp_value()
	_ensure_outpost_exists()
	_set_outpost_active(true)
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_outpost_archer_pressed() -> void:
	if not _outpost_unlocked:
		return
	if _outpost_archer_count >= 3:
		return
	_outpost_archer_count = clampi(_outpost_archer_count + outpost_archer_upgrade_step, 1, 3)
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_outpost_damage_pressed() -> void:
	if not _outpost_unlocked:
		return
	outpost_damage_scale += outpost_damage_upgrade_step
	_outpost_runtime_damage_scale = outpost_damage_scale
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_outpost_speed_pressed() -> void:
	if not _outpost_unlocked:
		return
	outpost_fire_rate += speed_upgrade_step
	_refresh_upgrade_ui()
	_save_progress(0)

func _on_upgrade_outpost_hp_pressed() -> void:
	if not _outpost_unlocked:
		return
	outpost_max_hp += outpost_hp_upgrade_step
	_outpost_runtime_max_hp = outpost_max_hp
	if _is_outpost_alive():
		outpost_hp = min(_get_outpost_max_hp_value(), outpost_hp + outpost_hp_upgrade_step)
	_refresh_upgrade_ui()
	_save_progress(0)

func _ensure_outpost_exists() -> void:
	if _outpost_instance == null or not is_instance_valid(_outpost_instance):
		_outpost_instance = get_node_or_null(outpost_path) as Node2D
	if _outpost_instance == null:
		if lbl_status:
			lbl_status.text = "Missing Outpost node at path: %s" % String(outpost_path)
		return

	_outpost_muzzles.clear()

	for child in _outpost_instance.get_children():
		var m := child as Marker2D
		if m != null and m.name.begins_with("Outpost") and m.name.ends_with("Archer"):
			_outpost_muzzles.append(m)

	if _outpost_muzzles.is_empty():
		var fallback := _outpost_instance.get_node_or_null("Outpost1Archer") as Marker2D
		if fallback != null:
			_outpost_muzzles.append(fallback)

	_outpost_contact_point = _outpost_instance.get_node_or_null("OutpostContactPoint") as Marker2D
	_outpost_sprite = _outpost_instance.get_node_or_null("Sprite2D") as Sprite2D

func _destroy_outpost() -> void:
	outpost_hp = 0.0
	_set_outpost_active(false)

	var tower_contact_x := contact_point.global_position.x if is_instance_valid(contact_point) else 0.0
	if is_instance_valid(enemies_root):
		for child in enemies_root.get_children():
			if child != null and child.has_method("retarget_contact"):
				child.retarget_contact(tower_contact_x)

	if lbl_status and tower_hp > 0.0:
		lbl_status.text = "Outpost destroyed!"

func _set_outpost_active(active: bool) -> void:
	if _outpost_instance == null or not is_instance_valid(_outpost_instance):
		_outpost_instance = get_node_or_null(outpost_path) as Node2D
	if _outpost_instance == null:
		return
	_outpost_instance.visible = active
	if active:
		if outpost_hp <= 0.0:
			outpost_hp = _get_outpost_max_hp_value()
		_ensure_outpost_exists()
	else:
		_outpost_muzzles.clear()
		_outpost_contact_point = null
		_outpost_sprite = _outpost_instance.get_node_or_null("Sprite2D") as Sprite2D

func _set_catapult_active(active: bool) -> void:
	if catapult_node == null or not is_instance_valid(catapult_node):
		catapult_node = get_node_or_null(catapult_path) as Catapult
		if catapult_node == null:
			catapult_node = get_node_or_null(^"Tower/Catapult") as Catapult
	if catapult_node == null:
		return
	catapult_node.visible = active

# --------------------
# Shooting + aiming
# --------------------
func _tick_archers(delta: float) -> void:
	if archer_fire_rate <= 0.0:
		return
	if not is_instance_valid(projectiles_root) or not is_instance_valid(enemies_root):
		return

	var cd_time := 1.0 / maxf(0.01, archer_fire_rate)
	var active_archers := clampi(_tower_archer_count, 1, 3)

	for i in range(active_archers):
		_archer_cd[i] -= delta
		if _archer_cd[i] <= 0.0:
			_archer_cd[i] = cd_time
			_fire_aimed_arc(i)

func _tick_catapult(delta: float) -> void:
	if not _is_catapult_alive():
		return
	if catapult_fire_rate <= 0.0:
		return
	if not is_instance_valid(catapult_node):
		return

	_catapult_cd -= delta
	if _catapult_cd > 0.0:
		return

	_catapult_cd = 1.0 / maxf(0.01, catapult_fire_rate)
	catapult_node.fire()


func _tick_outpost_archer(delta: float) -> void:
	if not _outpost_unlocked:
		return
	if not _is_outpost_alive():
		return
	if _outpost_muzzles.is_empty() or not is_instance_valid(_outpost_instance):
		_ensure_outpost_exists()
		if _outpost_muzzles.is_empty():
			return
	if outpost_fire_rate <= 0.0:
		return
	var active_archers := mini(clampi(_outpost_archer_count, 1, 3), _outpost_muzzles.size())
	var cd_time := 1.0 / maxf(0.01, outpost_fire_rate)
	for i in range(active_archers):
		_outpost_archer_cd[i] -= delta
		if _outpost_archer_cd[i] > 0.0:
			continue
		_outpost_archer_cd[i] = cd_time
		var muzzle := _outpost_muzzles[i]
		if not is_instance_valid(muzzle):
			continue
		var start := muzzle.global_position + Vector2(arrow_spawn_x_nudge, 0.0)
		var target := _find_ranked_enemy_ahead(start.x, i)
		_fire_projectile_at(start, target, archer_damage * _get_outpost_damage_scale_value(), 0.85, 2.0)

func _fire_projectile_at(start: Vector2, target: Node2D, damage: float, speed_multiplier: float, jitter_deg: float) -> void:
	if target == null:
		_last_target_dx = -1.0
		return
	if not is_instance_valid(projectiles_root):
		return

	var aim_point := target.global_position
	_last_target_dx = aim_point.x - start.x

	var g := _get_projectile_gravity()
	var v0 := _compute_ballistic_velocity(start, aim_point, speed_hint * speed_multiplier, g)
	if jitter_deg > 0.0:
		v0 = v0.rotated(deg_to_rad(randf_range(-jitter_deg, jitter_deg)))

	var inst := projectile_scene.instantiate()
	var p := inst as Projectile
	if p == null:
		if lbl_status:
			lbl_status.text = "Projectile.tscn root must have Projectile.gd attached (class_name Projectile)."
		if inst != null:
			inst.queue_free()
		return

	projectiles_root.add_child(p)
	p.projectile_gravity = g
	# Allow shots to reach enemies spawned slightly below base floor_y from lane jitter.
	p.floor_y = maxf(floor_y, aim_point.y + 6.0)
	p.configure_ballistic(start, v0, damage)

func _fire_aimed_arc(index: int) -> void:
	var muzzle := muzzle_1
	if index == 1:
		muzzle = muzzle_2
	elif index == 2:
		muzzle = muzzle_3
	if not is_instance_valid(muzzle):
		return

	var start := muzzle.global_position + Vector2(arrow_spawn_x_nudge, 0.0)

	var target := _find_ranked_enemy_ahead(start.x, index)
	var max_jitter_deg: float = lerpf(9.0, 1.0, clampf(archer_accuracy, 0.0, 1.0))
	_fire_projectile_at(start, target, archer_damage, 1.0, max_jitter_deg)

func _find_ranked_enemy_ahead(from_x: float, rank: int) -> Node2D:
	var picks: Array[Node2D] = []
	var closest: Node2D = null
	var wanted := maxi(0, rank)

	for i in range(wanted + 1):
		var best: Node2D = null
		var best_dx := INF

		for child in enemies_root.get_children():
			var e := child as Node2D
			if e == null:
				continue
			if not e.has_method("take_damage"):
				continue
			if picks.has(e):
				continue

			var dx := e.global_position.x - from_x
			if dx < 0.0:
				continue

			if dx < best_dx:
				best_dx = dx
				best = e

		if best == null:
			return closest

		if i == 0:
			closest = best
		picks.append(best)

	return picks[wanted] if picks.size() > wanted else closest

func _has_enemy_in_camera_view() -> bool:
	if not is_instance_valid(enemies_root):
		return false

	var screen_rect := get_viewport_rect()
	var canvas_xform := get_viewport().get_canvas_transform()

	for child in enemies_root.get_children():
		var e := child as Node2D
		if e == null:
			continue
		if not e.has_method("take_damage"):
			continue

		var screen_pos := canvas_xform * e.global_position
		if screen_rect.has_point(screen_pos):
			return true

	return false

func _find_catapult_target(from_x: float) -> Node2D:
	if not is_instance_valid(enemies_root):
		return null

	var tower_x := contact_point.global_position.x if is_instance_valid(contact_point) else from_x
	var min_x := tower_x + maxf(0.0, catapult_min_target_distance_from_tower)

	var best: Node2D = null
	var best_dx := INF
	for child in enemies_root.get_children():
		var e := child as Node2D
		if e == null:
			continue
		if not e.has_method("take_damage"):
			continue
		if e.global_position.x < min_x:
			continue

		var dx := e.global_position.x - from_x
		if dx < 0.0:
			continue
		if dx < best_dx:
			best_dx = dx
			best = e
	return best

func _get_projectile_gravity() -> float:
	return 1200.0

func _compute_ballistic_velocity(start: Vector2, target: Vector2, speed_hint_local: float, g: float) -> Vector2:
	var d := target - start
	var dist := maxf(1.0, d.length())
	var t := clampf(dist / maxf(1.0, speed_hint_local), min_shot_time, max_shot_time)
	var vx := d.x / t
	var vy := (d.y - 0.5 * g * t * t) / t
	return Vector2(vx, vy)

func _draw() -> void:
	if not show_structure_hp_bars:
		return

	if tower_max_hp > 0.0 and is_instance_valid(tower_sprite):
		var tower_pos := _get_bar_pos_from_sprite(tower_sprite, tower_hp_bar_size, tower_hp_bar_offset_from_contact.y)
		_draw_world_hp_bar(tower_pos, tower_hp, tower_max_hp, tower_hp_bar_size, Color(0.26, 0.78, 0.35, 0.95))

	if _outpost_unlocked and _is_outpost_alive() and is_instance_valid(_outpost_sprite):
		var outpost_pos := _get_bar_pos_from_sprite(_outpost_sprite, outpost_hp_bar_size, outpost_hp_bar_offset_from_contact.y)
		_draw_world_hp_bar(outpost_pos, outpost_hp, _get_outpost_max_hp_value(), outpost_hp_bar_size, Color(0.35, 0.65, 0.98, 0.95))

func _get_bar_pos_from_sprite(sprite: Sprite2D, bar_size: Vector2, vertical_offset: float) -> Vector2:
	var tex_size := sprite.texture.get_size() if sprite.texture != null else Vector2.ZERO
	var scaled_h := tex_size.y * absf(sprite.global_scale.y)
	var top_y := sprite.global_position.y - (scaled_h * 0.5)
	var x := sprite.global_position.x - (bar_size.x * 0.5)
	return Vector2(x, top_y + vertical_offset)

func _draw_world_hp_bar(world_pos: Vector2, current_hp: float, max_hp_value: float, size: Vector2, fill_color: Color) -> void:
	if max_hp_value <= 0.0:
		return
	var pct := clampf(current_hp / max_hp_value, 0.0, 1.0)
	var local_pos := to_local(world_pos)
	var bg_rect := Rect2(local_pos, size)
	var fill_rect := Rect2(local_pos + Vector2(1.0, 1.0), Vector2((size.x - 2.0) * pct, size.y - 2.0))

	draw_rect(bg_rect, Color(0.05, 0.05, 0.05, 0.8), true)
	draw_rect(fill_rect, fill_color, true)
	draw_rect(bg_rect, Color(0.95, 0.95, 0.95, 0.9), false, 1.0)

# --------------------
# UI
# --------------------
func _update_ui() -> void:
	if lbl_wave:
		lbl_wave.text = "Wave: %d" % wave
	if lbl_tower_hp:
		var hp_text := "Tower: %d/%d" % [int(tower_hp), int(tower_max_hp)]
		if _outpost_unlocked:
			if _is_outpost_alive():
				hp_text += " | Outpost: %d/%d" % [int(outpost_hp), int(_get_outpost_max_hp_value())]
			else:
				hp_text += " | Outpost: Destroyed"
		lbl_tower_hp.text = hp_text
	if lbl_dbg:
		var enemy_count := enemies_root.get_child_count() if is_instance_valid(enemies_root) else 0
		lbl_dbg.text = "pending=%d total=%d alive=%d speed=%.3f target_dx=%.0f enemies=%d" % [
			_pending_spawns, _last_spawned_total, _alive_enemies, _last_speed_scale, _last_target_dx, enemy_count
		]
	_refresh_upgrade_ui()
	if lbl_structure_stats:
		var tower_damage_whole := int(round(archer_damage))
		var outpost_damage_whole := int(round(archer_damage * _get_outpost_damage_scale_value()))
		var tower_detail := "Archers %d/3 | Dmg %d | Rate %.2f/s | HP %d/%d" % [_tower_archer_count, tower_damage_whole, archer_fire_rate, int(tower_hp), int(tower_max_hp)]
		var outpost_detail := "Locked"
		if _outpost_unlocked:
			if _is_outpost_alive():
				outpost_detail = "Archers %d/3 | Dmg %d | Rate %.2f/s | HP %d/%d" % [_outpost_archer_count, outpost_damage_whole, outpost_fire_rate, int(outpost_hp), int(_get_outpost_max_hp_value())]
			else:
				outpost_detail = "Destroyed"
		var catapult_detail := "Not built"
		if _catapult_unlocked:
			catapult_detail = "Destroyed"
			if _is_catapult_alive():
				catapult_detail = "Ready | Dmg %d | Rate %.2f/s | AOE %.0f" % [int(round(catapult_damage)), catapult_fire_rate, catapult_aoe_radius]
		lbl_structure_stats.text = "Tower: %s\nOutpost: %s\nCatapult: %s" % [tower_detail, outpost_detail, catapult_detail]
	_update_interwave_status_ui()

func _on_catapult_fired(muzzle_pos: Vector2) -> void:
	if not is_instance_valid(projectiles_root):
		return

	var target := _find_catapult_target(muzzle_pos.x)
	if target == null:
		return

	# Aim at the ground near the enemy (not at the enemy)
	var aim := Vector2(target.global_position.x, floor_y)

	var g := catapult_gravity

	# slower = higher arc
	var v0 := _compute_ballistic_velocity(muzzle_pos, aim, speed_hint * catapult_speed_multiplier, g)

	var inst := catapult_rock_scene.instantiate()
	var rock := inst as CatapultRock
	if rock == null:
		inst.queue_free()
		return

	projectiles_root.add_child(rock)
	rock.gravity = g
	rock.configure(muzzle_pos, v0, floor_y, catapult_damage, catapult_aoe_radius)

	# optional heavier shake
	if cam:
		cam.add_trauma(0.22)

