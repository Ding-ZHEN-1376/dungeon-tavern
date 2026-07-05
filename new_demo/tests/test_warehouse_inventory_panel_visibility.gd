extends Node

const InventoryPanelScene := preload("res://scenes/ui/inventory/InventoryPanel.tscn")
const WarehouseMenuScene := preload("res://scenes/ui/menus/storage/WarehouseMenu.tscn")


func _ready() -> void:
	var inventory_panel := InventoryPanelScene.instantiate()
	add_child(inventory_panel)
	await get_tree().process_frame

	_assert_true(
		inventory_panel.has_method("is_panel_visible"),
		"Inventory panel should expose is_panel_visible for menus that temporarily show it."
	)
	_assert_eq(inventory_panel.is_panel_visible(), false, "Inventory panel should start hidden.")

	var warehouse_menu := WarehouseMenuScene.instantiate()
	add_child(warehouse_menu)
	await get_tree().process_frame

	_assert_eq(inventory_panel.is_panel_visible(), true, "Warehouse should show the inventory panel.")
	warehouse_menu.close_menu()
	await get_tree().process_frame

	_assert_eq(
		inventory_panel.is_panel_visible(),
		false,
		"Closing warehouse should hide inventory when warehouse opened it."
	)

	inventory_panel.show_panel()
	_assert_eq(inventory_panel.is_panel_visible(), true, "Test setup should show inventory panel.")

	warehouse_menu = WarehouseMenuScene.instantiate()
	add_child(warehouse_menu)
	await get_tree().process_frame
	warehouse_menu.close_menu()
	await get_tree().process_frame

	_assert_eq(
		inventory_panel.is_panel_visible(),
		true,
		"Closing warehouse should keep inventory open when player had already opened it."
	)

	get_tree().quit(0)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		get_tree().quit(1)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s Expected %s, got %s." % [message, str(expected), str(actual)])
		get_tree().quit(1)
