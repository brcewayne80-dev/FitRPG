extends Node
class_name SaveData

const SAVE_PATH := "user://defend_valley_save.json"

var highest_wave_reached: int = 1

# Persistent upgrades (levels / flags)
var upgrades := {
	"archer_power": 0,
	"archer_speed": 0,
	"archer_accuracy": 0,
	"tower_archers": 0,
	"catapult_unlocked": 0,      # reserved
	"catapult_power": 0,
	"catapult_speed": 0,
	"catapult_aoe": 0,
	"tower_health": 0,

	# New: outpost exists if >= 1
	"outpost_unlocked": 0,

	# Used as OUTPOST starting strength (+% HP)
	"outpost_strength": 0,
	"outpost_archers": 0,
	"outpost_power": 0,
	"outpost_speed": 0
}

# One-time inventory (counts)
var consumables := {
	# Used as REBUILD OUTPOST (kept name so you don't break InputMap / UI)
	"defensive_walls": 0,
	"moats": 0,
	"traps": 0
}

func load_or_init() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		save()
		return

	var txt := f.get_as_text()
	f.close()

	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		save()
		return

	highest_wave_reached = int(data.get("highest_wave_reached", 1))

	var up: Dictionary = data.get("upgrades", {})
	if typeof(up) == TYPE_DICTIONARY:
		for k in upgrades.keys():
			upgrades[k] = int(up.get(k, upgrades[k]))

	var con: Dictionary = data.get("consumables", {})
	if typeof(con) == TYPE_DICTIONARY:
		for k in consumables.keys():
			consumables[k] = int(con.get(k, consumables[k]))

func save() -> void:
	var data := {
		"highest_wave_reached": highest_wave_reached,
		"upgrades": upgrades,
		"consumables": consumables
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func set_highest_wave_if_greater(wave: int) -> void:
	if wave > highest_wave_reached:
		highest_wave_reached = wave
		save()
