extends Node

signal inventory_changed

const InventoryContainerScript := preload("res://scripts/inventory/inventory_container.gd")
const InventoryTransferScript := preload("res://scripts/inventory/inventory_transfer.gd")

const BACKPACK_SLOT_COUNT := 15
const WAREHOUSE_SLOT_COUNT := 40
const PLAYER_INVENTORY_GROUP := "player_inventory"
const WAREHOUSE_INVENTORY_GROUP := "warehouse_inventory"

var backpack_slots: Array = []
var warehouse_slots: Array = []

var _fallback_backpack: Node = null
var _fallback_warehouse: Node = null


func _ready() -> void:
	reset_inventory(true)


func reset_inventory(include_demo_items: bool = true) -> void:
	_ensure_fallback_containers()
	_fallback_backpack.reset_inventory()
	_fallback_warehouse.reset_inventory()
	backpack_slots = _fallback_backpack.get_slots()
	warehouse_slots = _fallback_warehouse.get_slots()

	if include_demo_items:
		add_item_to_container("backpack", "low_grade_sugar", 12)
		add_item_to_container("backpack", "mushroom", 5)
		add_item_to_container("backpack", "wine", 1)

	inventory_changed.emit()


func add_item_to_container(container_name: String, material_id: String, amount: int) -> int:
	var container := _get_container(container_name)
	if container == null or not container.has_method("add_item"):
		return amount

	var remaining: int = container.add_item(material_id, amount)
	if remaining != amount:
		inventory_changed.emit()
	return remaining


func move_stack(from_container: String, from_index: int, to_container: String, to_index: int) -> void:
	var from_inventory := _get_container(from_container)
	var to_inventory := _get_container(to_container)
	InventoryTransferScript.move_stack(from_inventory, from_index, to_inventory, to_index)
	inventory_changed.emit()


func get_slots(container_name: String) -> Array:
	var container := _get_container(container_name)
	if container == null or not container.has_method("get_slots"):
		return []
	return container.get_slots()


func get_slot(container_name: String, slot_index: int) -> Dictionary:
	var container := _get_container(container_name)
	if container == null or not container.has_method("get_slot"):
		return _make_empty_slot()
	return container.get_slot(slot_index)


func set_slot(container_name: String, slot_index: int, material_id: String, count: int) -> void:
	var container := _get_container(container_name)
	if container == null or not container.has_method("set_slot"):
		return
	container.set_slot(slot_index, material_id, count)
	inventory_changed.emit()


func _get_container(container_name: String) -> Node:
	_ensure_fallback_containers()
	if container_name == "backpack":
		var player_inventory := _get_first_group_node(PLAYER_INVENTORY_GROUP)
		return player_inventory if player_inventory != null else _fallback_backpack
	if container_name == "warehouse":
		var warehouse_inventory := _get_first_group_node(WAREHOUSE_INVENTORY_GROUP)
		return warehouse_inventory if warehouse_inventory != null else _fallback_warehouse
	return null


func _get_first_group_node(group_name: String) -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(group_name)


func _ensure_fallback_containers() -> void:
	if _fallback_backpack == null:
		_fallback_backpack = InventoryContainerScript.new()
		_fallback_backpack.container_id = "backpack_legacy_fallback"
		_fallback_backpack.slot_count = BACKPACK_SLOT_COUNT
		_fallback_backpack.inventory_changed.connect(_on_fallback_inventory_changed)
		add_child(_fallback_backpack)
	if _fallback_warehouse == null:
		_fallback_warehouse = InventoryContainerScript.new()
		_fallback_warehouse.container_id = "warehouse_legacy_fallback"
		_fallback_warehouse.slot_count = WAREHOUSE_SLOT_COUNT
		_fallback_warehouse.inventory_changed.connect(_on_fallback_inventory_changed)
		add_child(_fallback_warehouse)


func _on_fallback_inventory_changed() -> void:
	inventory_changed.emit()


func _make_empty_slot() -> Dictionary:
	return {
		"id": "",
		"count": 0
	}
