extends SceneTree

const MaterialInventoryScript := preload("res://scripts/systems/material_inventory.gd")


func _init() -> void:
	var inventory := MaterialInventoryScript.new()
	get_root().add_child(inventory)
	inventory.reset_inventory(false)

	_assert_eq(inventory.backpack_slots.size(), 15, "Backpack should have 15 slots.")
	_assert_eq(inventory.warehouse_slots.size(), 40, "Warehouse should have 40 slots.")

	var remaining := inventory.add_item_to_container("backpack", "low_grade_sugar", 70)
	_assert_eq(remaining, 0, "All sugar should fit into the empty backpack.")
	_assert_eq(inventory.backpack_slots[0]["count"], 64, "First stack should be capped at 64.")
	_assert_eq(inventory.backpack_slots[1]["count"], 6, "Overflow should continue in the next slot.")

	inventory.move_stack("backpack", 1, "warehouse", 0)
	_assert_eq(inventory.backpack_slots[1]["count"], 0, "Moved stack should leave the backpack slot empty.")
	_assert_eq(inventory.warehouse_slots[0]["id"], "low_grade_sugar", "Warehouse should receive sugar.")
	_assert_eq(inventory.warehouse_slots[0]["count"], 6, "Warehouse should receive the moved count.")

	inventory.set_slot("backpack", 2, "mushroom", 3)
	inventory.move_stack("backpack", 2, "warehouse", 0)
	_assert_eq(inventory.backpack_slots[2]["id"], "low_grade_sugar", "Different materials should swap.")
	_assert_eq(inventory.warehouse_slots[0]["id"], "mushroom", "Target slot should receive mushroom.")

	quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		quit(1)
