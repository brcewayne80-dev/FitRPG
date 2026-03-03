extends Control

const PATH_SETTINGS := "res://scenes/ui/Settings.tscn"

@onready var menu_btn: MenuButton = find_child("MenuBtn", true, false) as MenuButton
@onready var btn_edit_daily: Button = find_child("BtnEditDaily", true, false) as Button
@onready var btn_edit_weekly: Button = find_child("BtnEditWeekly", true, false) as Button
@onready var daily_slot: VBoxContainer = find_child("DailySlot", true, false) as VBoxContainer
@onready var weekly_slot: VBoxContainer = find_child("WeeklySlot", true, false) as VBoxContainer

func _ready() -> void:
	# Hamburger – ensure it opens
	if menu_btn:
		menu_btn.text = "☰"
		menu_btn.flat = true
		menu_btn.focus_mode = Control.FOCUS_NONE
		menu_btn.custom_minimum_size = Vector2(48, 48)
		_populate_menu()
		if not menu_btn.is_connected("pressed", Callable(self, "_on_menu_pressed")):
			menu_btn.pressed.connect(_on_menu_pressed)

	# Gear buttons
	if btn_edit_daily and not btn_edit_daily.is_connected("pressed", Callable(self, "_open_picker_daily")):
		btn_edit_daily.pressed.connect(_open_picker_daily)
	if btn_edit_weekly and not btn_edit_weekly.is_connected("pressed", Callable(self, "_open_picker_weekly")):
		btn_edit_weekly.pressed.connect(_open_picker_weekly)

func _populate_menu() -> void:
	if menu_btn == null: return
	var pm := menu_btn.get_popup()
	if pm == null: return
	pm.clear()
	pm.add_item("Workouts", 1)
	pm.add_item("Sleep",    2)
	pm.add_item("Weight",   3)
	pm.add_separator()
	pm.add_item("Widget Selection", 5)  # NEW shortcut
	pm.add_item("Settings", 4)
	if not pm.id_pressed.is_connected(_on_menu_id_pressed):
		pm.id_pressed.connect(_on_menu_id_pressed)

func _on_menu_pressed() -> void:
	_populate_menu()
	if menu_btn: menu_btn.show_popup()

func _on_menu_id_pressed(id: int) -> void:
	match id:
		1: _go("res://scenes/ui/Workouts.tscn")
		2: _go("res://scenes/ui/Sleep.tscn")
		3: _go("res://scenes/ui/Weight.tscn")
		4: _go(PATH_SETTINGS)
		5: _open_picker_daily()   # opens Daily by default; you can add a sub-menu later

func _open_picker_daily() -> void:
	_open_picker_for_key("daily_widgets")

func _open_picker_weekly() -> void:
	_open_picker_for_key("weekly_widgets")

func _open_picker_for_key(key: String) -> void:
	var scene: PackedScene = load("res://scenes/ui/WidgetPicker.tscn")
	if scene == null:
		push_error("[Home] WidgetPicker.tscn not found.")
		return
	var picker := scene.instantiate() as Window
	picker.prefs_key = key
	add_child(picker)
	picker.popup_centered(Vector2(360, 420))

func _go(path: String) -> void:
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_error("[Home] Scene not found: " + path)
