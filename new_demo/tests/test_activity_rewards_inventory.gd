extends SceneTree

const ActivitySystemScript := preload("res://scripts/systems/activity_system.gd")
const InventoryContainerScript := preload("res://scripts/inventory/inventory_container.gd")
const TimeSystemScript := preload("res://scripts/systems/time_system.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var time_system := TimeSystemScript.new()
	var activity_system := ActivitySystemScript.new()
	var player_inventory := InventoryContainerScript.new()

	get_root().add_child(time_system)
	get_root().add_child(activity_system)
	get_root().add_child(player_inventory)

	player_inventory.add_to_group("player_inventory")
	player_inventory.slot_count = 15
	player_inventory.reset_inventory()

	activity_system.time_system = time_system
	time_system.reset_time()

	var result: Dictionary = activity_system.perform_activity("trade")
	_assert_eq(result["ok"], true, "Trade should execute.")
	_assert_eq(player_inventory.get_slot(0)["id"], "low_grade_sugar", "Trade reward should enter player inventory.")
	_assert_eq(player_inventory.get_slot(0)["count"], 1, "Trade reward count should enter player inventory.")

	quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		quit(1)
