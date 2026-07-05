extends Node

const TaskConfirmMenuScene := preload("res://scenes/ui/menus/task_confirm/TaskConfirmMenu.tscn")


func _ready() -> void:
	TimeSystem.reset_time()

	var menu := TaskConfirmMenuScene.instantiate()
	add_child(menu)
	menu.setup("task_confirm", {
		"activity_id": "trade",
		"activity_title": "交易",
		"activity_description": "是否交易？"
	})
	await get_tree().process_frame

	var confirm_button: Button = menu.get_node("%ConfirmButton")
	var cancel_button: Button = menu.get_node("%CancelButton")
	var result_label: Label = menu.get_node("%ResultLabel")

	_assert_eq(confirm_button.text, "是", "Executable task should show yes button.")
	_assert_eq(confirm_button.visible, true, "Executable task should show confirm button.")
	_assert_eq(cancel_button.visible, true, "Executable task should show cancel button.")
	_assert_eq(result_label.text, "", "Executable task should not show result before confirmation.")

	confirm_button.pressed.emit()
	await get_tree().process_frame

	_assert_eq(confirm_button.text, "好的", "Completed task should change confirm button to OK.")
	_assert_eq(confirm_button.visible, true, "Completed task should keep OK button visible.")
	_assert_eq(cancel_button.visible, false, "Completed task should hide cancel button.")
	_assert_eq(result_label.text.contains("交易完成"), true, "Completed task should show result text.")
	var slot_after_trade := TimeSystem.day_slot

	confirm_button.pressed.emit()
	await get_tree().process_frame
	_assert_eq(TimeSystem.day_slot, slot_after_trade, "OK button should close without repeating the activity.")

	TimeSystem.reset_time()
	menu = TaskConfirmMenuScene.instantiate()
	add_child(menu)
	menu.setup("task_confirm", {
		"activity_id": "arena",
		"activity_title": "竞技场竞技",
		"activity_description": "是否参加竞技场？"
	})
	await get_tree().process_frame

	confirm_button = menu.get_node("%ConfirmButton")
	cancel_button = menu.get_node("%CancelButton")
	result_label = menu.get_node("%ResultLabel")

	_assert_eq(confirm_button.text, "好的", "Unavailable task should only show OK button.")
	_assert_eq(confirm_button.visible, true, "Unavailable task should show OK button.")
	_assert_eq(cancel_button.visible, false, "Unavailable task should hide cancel button.")
	_assert_eq(result_label.text.contains("当前时间不能进行"), true, "Unavailable task should show reason.")

	confirm_button.pressed.emit()
	await get_tree().process_frame
	_assert_eq(TimeSystem.day_slot, TimeSystem.DAY_SLOT_MORNING, "Unavailable OK should not advance time.")

	get_tree().quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		get_tree().quit(1)
