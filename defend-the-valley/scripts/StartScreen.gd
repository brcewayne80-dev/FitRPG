extends Control

const GAME_SCENE_PATH := "res://scenes/DefendValley.tscn"

@onready var new_game_button: Button = $CenterContainer/VBox/NewGameButton
@onready var load_button: Button = $CenterContainer/VBox/LoadGameButton
@onready var status_label: Label = $CenterContainer/VBox/StatusLabel

func _ready() -> void:
	_ensure_controller_input_actions()
	var has_save := FileAccess.file_exists(SaveData.SAVE_PATH)
	if has_save:
		var save_data := SaveData.new()
		save_data.load_or_init()
		var continue_wave := maxi(1, save_data.highest_wave_reached)
		new_game_button.visible = true
		new_game_button.disabled = false
		new_game_button.text = "Restart (Wave 1)"
		load_button.visible = true
		load_button.disabled = false
		load_button.text = "Continue (Wave %d)" % continue_wave
		status_label.text = "Continue your run or restart from Wave 1."
		if is_instance_valid(new_game_button):
			new_game_button.grab_focus()
	else:
		new_game_button.visible = true
		new_game_button.disabled = false
		new_game_button.text = "New Game"
		load_button.visible = false
		load_button.disabled = true
		status_label.text = "Start a new game."
		if is_instance_valid(new_game_button):
			new_game_button.grab_focus()

func _ensure_controller_input_actions() -> void:
	_ensure_action("ui_accept", [JOY_BUTTON_A], [KEY_ENTER, KEY_SPACE])
	_ensure_action("ui_cancel", [JOY_BUTTON_B], [KEY_ESCAPE])
	_ensure_action("ui_up", [JOY_BUTTON_DPAD_UP], [KEY_UP])
	_ensure_action("ui_down", [JOY_BUTTON_DPAD_DOWN], [KEY_DOWN])
	_ensure_action("ui_left", [JOY_BUTTON_DPAD_LEFT], [KEY_LEFT])
	_ensure_action("ui_right", [JOY_BUTTON_DPAD_RIGHT], [KEY_RIGHT])

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

func _on_new_game_button_pressed() -> void:
	var save_data := SaveData.new()
	save_data.load_or_init()
	save_data.highest_wave_reached = 1
	for key in save_data.upgrades.keys():
		save_data.upgrades[key] = 0
	save_data.save()

	GameSession.loading_from_save = false
	GameSession.start_wave = 1

	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_load_game_button_pressed() -> void:
	var save_data := SaveData.new()
	save_data.load_or_init()

	GameSession.loading_from_save = true
	GameSession.start_wave = maxi(1, save_data.highest_wave_reached)

	get_tree().change_scene_to_file(GAME_SCENE_PATH)
