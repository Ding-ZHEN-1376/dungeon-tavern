extends Node

const TimeSystemScript := preload("res://scripts/systems/time_system.gd")
const ActivitySystemScript := preload("res://scripts/systems/activity_system.gd")


func _ready() -> void:
	var time_system := TimeSystemScript.new()
	var activity_system := ActivitySystemScript.new()
	activity_system.time_system = time_system

	time_system.reset_time()
	_assert_eq(activity_system.can_perform_activity("trade"), true, "Trade should be available in normal morning.")
	_assert_eq(activity_system.can_perform_activity("sleep"), false, "Sleep should not be available in normal morning.")

	var result: Dictionary = activity_system.perform_activity("trade")
	_assert_eq(result["ok"], true, "Trade should execute in normal morning.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_FORENOON, "Trade should consume one time point.")

	time_system.phase = time_system.PHASE_EVENING
	time_system.day_slot = time_system.DAY_SLOT_AFTERNOON
	_assert_eq(activity_system.can_perform_activity("trade"), false, "Trade should not be available in evening.")
	_assert_eq(activity_system.can_perform_activity("tavern_service"), true, "Tavern service should be available in evening.")

	result = activity_system.perform_activity("tavern_service")
	_assert_eq(result["ok"], true, "Tavern service should execute in evening.")
	_assert_eq(time_system.phase, time_system.PHASE_NIGHT, "Evening activity should advance to night.")

	_assert_eq(activity_system.can_perform_activity("arena"), true, "Arena should be available at night.")
	_assert_eq(activity_system.can_perform_activity("tavern_service"), false, "Tavern service should not be available at night.")

	result = activity_system.perform_activity("arena")
	_assert_eq(result["ok"], true, "Arena should execute at night.")
	_assert_eq(time_system.day_index, 2, "Night non-sleep activity should advance to next day.")
	_assert_eq(time_system.is_forced_morning_sleep(), true, "Night non-sleep activity should force morning sleep.")

	_assert_eq(activity_system.can_perform_activity("trade"), false, "Forced morning sleep should block trade.")
	_assert_eq(activity_system.can_perform_activity("battle_gather"), false, "Forced morning sleep should block battle gathering.")
	_assert_eq(activity_system.can_perform_activity("sleep"), true, "Forced morning sleep should allow sleep.")

	result = activity_system.perform_activity("sleep")
	_assert_eq(result["ok"], true, "Forced morning sleep should execute.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_AFTERNOON, "Forced morning sleep should wake in afternoon.")

	time_system.phase = time_system.PHASE_NIGHT
	time_system.day_slot = time_system.DAY_SLOT_AFTERNOON
	time_system.must_sleep_this_morning = false
	result = activity_system.perform_activity("sleep")
	_assert_eq(result["ok"], true, "Night sleep should execute.")
	_assert_eq(time_system.day_slot, time_system.DAY_SLOT_MORNING, "Night sleep should wake next morning.")
	_assert_eq(time_system.must_sleep_this_morning, false, "Night sleep should not force morning sleep.")

	get_tree().quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		get_tree().quit(1)
