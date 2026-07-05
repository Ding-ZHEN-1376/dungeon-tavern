extends Node

const TimeHudScene := preload("res://scenes/ui/hud/TimeHud.tscn")


func _ready() -> void:
	TimeSystem.reset_time()

	var hud := TimeHudScene.instantiate()
	add_child(hud)
	await get_tree().process_frame

	var day_label: Label = hud.get_node("%DayLabel")
	var phase_label: Label = hud.get_node("%PhaseLabel")
	_assert_eq(day_label.text, "第 1 天", "HUD should show the current day.")
	_assert_eq(phase_label.text, "清晨", "HUD should show the current time slot.")

	TimeSystem.phase = TimeSystem.PHASE_NIGHT
	TimeSystem.advance_after_activity("arena")
	await get_tree().process_frame

	_assert_eq(TimeSystem.is_forced_morning_sleep(), true, "Test setup should force morning sleep.")
	_assert_eq(day_label.text, "第 2 天", "HUD should update after time changes.")
	_assert_eq(phase_label.text, "清晨", "HUD should not append forced sleep text.")

	get_tree().quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		get_tree().quit(1)
