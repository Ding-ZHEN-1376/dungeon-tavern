extends Node

signal time_changed(day_index: int, phase: String, day_points_remaining: int)
signal night_started(day_index: int)
signal day_started(day_index: int)

const PHASE_DAY := "day"
const PHASE_EVENING := "evening"
const PHASE_NIGHT := "night"

const DAY_SLOT_MORNING := 0
const DAY_SLOT_FORENOON := 1
const DAY_SLOT_AFTERNOON := 2
const DAY_SLOT_NAMES := ["清晨", "上午", "下午"]
const MAX_DAY_POINTS := 3

var day_index := 1
var phase := PHASE_DAY
var day_slot := DAY_SLOT_MORNING
var day_points_remaining := MAX_DAY_POINTS
var must_sleep_this_morning := false


func reset_time() -> void:
	day_index = 1
	phase = PHASE_DAY
	day_slot = DAY_SLOT_MORNING
	day_points_remaining = MAX_DAY_POINTS
	must_sleep_this_morning = false
	_emit_time_changed()


func is_day() -> bool:
	return phase == PHASE_DAY


func is_evening() -> bool:
	return phase == PHASE_EVENING


func is_night() -> bool:
	return phase == PHASE_NIGHT


func is_morning() -> bool:
	return is_day() and day_slot == DAY_SLOT_MORNING


func is_forced_morning_sleep() -> bool:
	return is_morning() and must_sleep_this_morning


func can_sleep() -> bool:
	return is_night() or is_forced_morning_sleep()


func get_time_label() -> String:
	if is_day():
		return "第 %d 天 %s" % [day_index, DAY_SLOT_NAMES[day_slot]]
	if is_evening():
		return "第 %d 天 傍晚" % day_index
	return "第 %d 天 夜晚" % day_index


func advance_after_activity(activity_id: String) -> Dictionary:
	if activity_id == "sleep":
		return sleep()
	if is_forced_morning_sleep():
		return {
			"ok": false,
			"message": "你昨晚没有休息，现在必须先睡觉。"
		}

	if is_day():
		if day_slot < DAY_SLOT_AFTERNOON:
			day_slot += 1
			day_points_remaining = MAX_DAY_POINTS - day_slot
			_emit_time_changed()
		else:
			phase = PHASE_EVENING
			day_points_remaining = 0
			_emit_time_changed()
		return {
			"ok": true,
			"message": "时间推进到了%s。" % get_time_label()
		}

	if is_evening():
		phase = PHASE_NIGHT
		day_points_remaining = 0
		night_started.emit(day_index)
		_emit_time_changed()
		return {
			"ok": true,
			"message": "时间推进到了%s。" % get_time_label()
		}

	_start_next_day(true)
	return {
		"ok": true,
		"message": "你一夜未眠，第二天清晨必须先睡觉。"
	}


func sleep() -> Dictionary:
	if is_night():
		_start_next_day(false)
		return {
			"ok": true,
			"message": "你睡了一觉，在第二天清晨醒来。"
		}

	if is_forced_morning_sleep():
		day_slot = DAY_SLOT_AFTERNOON
		day_points_remaining = 1
		must_sleep_this_morning = false
		_emit_time_changed()
		return {
			"ok": true,
			"message": "你补了一觉，在当天下午醒来。"
		}

	return {
		"ok": false,
		"message": "现在不能睡觉。"
	}


func consume_day_point(reason: String) -> bool:
	return bool(advance_after_activity(reason).get("ok", false))


func skip_night() -> void:
	if is_night():
		_start_next_day(false)


func _start_next_day(force_morning_sleep: bool) -> void:
	day_index += 1
	phase = PHASE_DAY
	day_slot = DAY_SLOT_MORNING
	day_points_remaining = MAX_DAY_POINTS
	must_sleep_this_morning = force_morning_sleep
	day_started.emit(day_index)
	_emit_time_changed()


func _emit_time_changed() -> void:
	time_changed.emit(day_index, phase, day_points_remaining)
