extends SceneTree

const InventoryContainerScript := preload("res://scripts/inventory/inventory_container.gd")


func _init() -> void:
	var inventory := InventoryContainerScript.new()
	inventory.slot_count = 3
	inventory.max_stack = 64
	get_root().add_child(inventory)
	inventory.reset_inventory()

	_assert_eq(inventory.get_slots().size(), 3, "Inventory should create the configured slot count.")

	var remaining := inventory.add_item("low_grade_sugar", 70)
	_assert_eq(remaining, 0, "All sugar should fit into two empty slots.")
	_assert_eq(inventory.get_slot(0)["count"], 64, "First stack should be capped at max_stack.")
	_assert_eq(inventory.get_slot(1)["count"], 6, "Overflow should continue in the next slot.")

	inventory.set_slot(2, "mushroom", 3)
	_assert_eq(inventory.get_slot(2)["id"], "mushroom", "set_slot should assign the item id.")
	_assert_eq(inventory.get_slot(2)["count"], 3, "set_slot should assign the item count.")

	inventory.set_slot(2, "", 0)
	_assert_eq(inventory.get_slot(2)["id"], "", "set_slot should clear an empty item id.")
	_assert_eq(inventory.get_slot(2)["count"], 0, "set_slot should clear an empty count.")

	quit(0)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		quit(1)
