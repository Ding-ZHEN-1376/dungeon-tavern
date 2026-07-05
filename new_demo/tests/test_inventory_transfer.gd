extends SceneTree

const InventoryContainerScript := preload("res://scripts/inventory/inventory_container.gd")
const InventoryTransferScript := preload("res://scripts/inventory/inventory_transfer.gd")


func _init() -> void:
	var backpack := _make_inventory(3, 64)
	var warehouse := _make_inventory(3, 64)

	backpack.set_slot(0, "low_grade_sugar", 6)
	InventoryTransferScript.move_stack(backpack, 0, warehouse, 0)
	_assert_eq(backpack.get_slot(0)["count"], 0, "Move should clear the source slot.")
	_assert_eq(warehouse.get_slot(0)["id"], "low_grade_sugar", "Move should copy the item id.")
	_assert_eq(warehouse.get_slot(0)["count"], 6, "Move should copy the item count.")

	backpack.set_slot(1, "low_grade_sugar", 10)
	warehouse.set_slot(1, "low_grade_sugar", 60)
	InventoryTransferScript.move_stack(backpack, 1, warehouse, 1)
	_assert_eq(backpack.get_slot(1)["count"], 6, "Merge should leave source overflow behind.")
	_assert_eq(warehouse.get_slot(1)["count"], 64, "Merge should cap target at max_stack.")

	backpack.set_slot(2, "mushroom", 3)
	InventoryTransferScript.move_stack(backpack, 2, warehouse, 0)
	_assert_eq(backpack.get_slot(2)["id"], "low_grade_sugar", "Different items should swap source id.")
	_assert_eq(backpack.get_slot(2)["count"], 6, "Different items should swap source count.")
	_assert_eq(warehouse.get_slot(0)["id"], "mushroom", "Different items should swap target id.")
	_assert_eq(warehouse.get_slot(0)["count"], 3, "Different items should swap target count.")

	InventoryTransferScript.move_stack(backpack, 2, backpack, 2)
	_assert_eq(backpack.get_slot(2)["id"], "low_grade_sugar", "Same source and target slot should not change.")

	InventoryTransferScript.move_stack(backpack, 20, warehouse, 0)
	_assert_eq(warehouse.get_slot(0)["id"], "mushroom", "Invalid source index should not change target.")

	quit(0)


func _make_inventory(slot_count: int, max_stack: int) -> Node:
	var inventory := InventoryContainerScript.new()
	inventory.slot_count = slot_count
	inventory.max_stack = max_stack
	get_root().add_child(inventory)
	inventory.reset_inventory()
	return inventory


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		quit(1)
