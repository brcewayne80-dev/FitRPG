extends Control
# Auto-completes when a weight is recorded today and awards XP once per day.

const XP_NODE_PATH: String      = "/root/XP"
const PREFS_NODE_PATH: String   = "/root/Prefs"
const WEIGHT_NODE_PATH: String  = "/root/Weight"

const PREF_KEY_LAST_DONE: String = "goal_weigh_in_last_date"
const XP_REWARD: int = 10

var status_lbl: Label = null

func _ready() -> void:
	status_lbl = find_child("Status", true, false) as Label

	# Listen for weight entries
	var w: Node = get_node_or_null(WEIGHT_NODE_PATH)
	if w != null and not w.is_connected("entry_added", Callable(self, "_on_weight_added")):
		w.connect("entry_added", Callable(self, "_on_weight_added"))

	_check_and_award_if_needed()
	_refresh_ui()

func _today_str() -> String:
	# "YYYY-MM-DD"
	var iso_now: String = Time.get_datetime_string_from_system(true, true)
	return iso_now.substr(0, 10)

func _is_done_today() -> bool:
	var prefs: Node = get_node_or_null(PREFS_NODE_PATH)
	if prefs == null:
		return false
	var last_var: Variant = prefs.call("read", PREF_KEY_LAST_DONE, "")
	var last: String = String(last_var)
	return last == _today_str()

func _mark_done_today() -> void:
	var prefs: Node = get_node_or_null(PREFS_NODE_PATH)
	if prefs != null:
		prefs.call("write", PREF_KEY_LAST_DONE, _today_str())

func _check_and_award_if_needed() -> void:
	if _is_done_today():
		return
	var w: Node = get_node_or_null(WEIGHT_NODE_PATH)
	if w != null:
		var has_today: bool = bool(w.call("has_entry_today"))
		if has_today:
			_award_and_mark()

func _on_weight_added(date_str: String, _value: float, _unit: String) -> void:
	if date_str == _today_str() and not _is_done_today():
		_award_and_mark()

func _award_and_mark() -> void:
	var xp: Node = get_node_or_null(XP_NODE_PATH)
	if xp != null:
		xp.call("earn_xp", XP_REWARD, "objective:weigh_in")
	_mark_done_today()
	_refresh_ui()

func _refresh_ui() -> void:
	var done: bool = _is_done_today()
	if status_lbl != null:
		status_lbl.text = "Completed" if done else "Not completed"
