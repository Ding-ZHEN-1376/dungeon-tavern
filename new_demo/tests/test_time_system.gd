extends Node

const TimeSystemScript := preload("res://scripts/systems/time_system.gd")


func _ready() -> void:
	var time_system := TimeSystemScript.new()
	time_system.reset_time()

	_assert_eq(time_system.day_index, 1, "Game should start on day 1.")
	_assert_eq(time_system.phase, time_system.PHASE_DAY, "Game should start during the day.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_MORNING, "Game should start in the morning.")
	_assert_eq(time_system.day_points_remaining, 3, "Morning should show 3 remaining daytime points.")
	_assert_eq(time_system.must_sleep_this_morning, false, "First morning should not force sleep.")
	_assert_eq(time_system.get_time_label(), "第 1 天 清晨", "Initial time label should be day 1 morning.")
	_assert_eq(time_system.is_day(), true, "Initial phase should report day.")
	_assert_eq(time_system.is_night(), false, "Initial phase should not report night.")
	_assert_eq(time_system.is_morning(), true, "Initial slot should report morning.")

	var result: Dictionary = time_system.advance_after_activity("trade")
	_assert_eq(result["ok"], true, "Morning activity should advance time.")
	_assert_eq(time_system.phase, time_system.PHASE_DAY, "Morning activity should remain day.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_FORENOON, "Morning activity should advance to forenoon.")
	_assert_eq(time_system.day_points_remaining, 2, "Forenoon should show 2 remaining daytime points.")

	result = time_system.advance_after_activity("battle_gather")
	_assert_eq(result["ok"], true, "Forenoon activity should advance time.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_AFTERNOON, "Forenoon activity should advance to afternoon.")
	_assert_eq(time_system.day_points_remaining, 1, "Afternoon should show 1 remaining daytime point.")

	result = time_system.advance_after_activity("brew")
	_assert_eq(result["ok"], true, "Afternoon activity should advance time.")
	_assert_eq(time_system.phase, time_system.PHASE_EVENING, "Afternoon activity should advance to evening.")
	_assert_eq(time_system.day_points_remaining, 0, "Evening should show no remaining daytime points.")

	result = time_system.advance_after_activity("tavern_service")
	_assert_eq(result["ok"], true, "Evening activity should advance time.")
	_assert_eq(time_system.phase, time_system.PHASE_NIGHT, "Evening activity should advance to night.")
	_assert_eq(time_system.is_night(), true, "Night phase should report night.")

	result = time_system.advance_after_activity("arena")
	_assert_eq(result["ok"], true, "Night non-sleep activity should advance to next morning.")
	_assert_eq(time_system.day_index, 2, "Night non-sleep activity should advance to day 2.")
	_assert_eq(time_system.phase, time_system.PHASE_DAY, "Night non-sleep activity should return to day.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_MORNING, "Night non-sleep activity should return to morning.")
	_assert_eq(time_system.must_sleep_this_morning, true, "Night non-sleep activity should force morning sleep.")
	_assert_eq(time_system.is_forced_morning_sleep(), true, "Forced morning sleep helper should report true.")

	result = time_system.sleep()
	_assert_eq(result["ok"], true, "Forced morning sleep should be allowed.")
	_assert_eq(time_system.day_index, 2, "Forced morning sleep should remain on the same day.")
	_assert_eq(time_system.phase, time_system.PHASE_DAY, "Forced morning sleep should remain in day phase.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_AFTERNOON, "Forced morning sleep should wake in afternoon.")
	_assert_eq(time_system.must_sleep_this_morning, false, "Forced morning sleep should clear the forced flag.")

	time_system.reset_time()
	time_system.phase = time_system.PHASE_NIGHT
	time_system.day_points_remaining = 0
	result = time_system.sleep()
	_assert_eq(result["ok"], true, "Night sleep should be allowed.")
	_assert_eq(time_system.day_index, 2, "Night sleep should advance to the next day.")
	_assert_eq(time_system.phase, time_system.PHASE_DAY, "Night sleep should wake during day phase.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_MORNING, "Night sleep should wake in the morning.")
	_assert_eq(time_system.must_sleep_this_morning, false, "Night sleep should not force another morning sleep.")

	result = time_system.sleep()
	_assert_eq(result["ok"], false, "Normal morning sleep should not be allowed after sleeping at night.")

	get_tree().quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		get_tree().quit(1)
