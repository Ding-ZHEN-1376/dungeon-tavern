extends Node

signal inventory_changed

const MAX_STACK := 64
const BACKPACK_SLOT_COUNT := 15
const WAREHOUSE_SLOT_COUNT := 40

var backpack_slots: Array = []
var warehouse_slots: Array = []


func _ready() -> void:
	reset_inventory(true)


func reset_inventory(include_demo_items: bool = true) -> void:
	backpack_slots = _make_slots(BACKPACK_SLOT_COUNT)
	warehouse_slots = _make_slots(WAREHOUSE_SLOT_COUNT)

	if include_demo_items:
		add_item_to_container("backpack", "low_grade_sugar", 12)
		add_item_to_container("backpack", "mushroom", 5)
		add_item_to_container("backpack", "wine", 1)

	inventory_changed.emit()


func add_item_to_container(container_name: String, material_id: String, amount: int) -> int:
	if material_id == "" or amount <= 0:
		return amount

	var slots := get_slots(container_name)
	if slots.is_empty():
		return amount

	var remaining := amount

	for slot in slots:
		if remaining <= 0:
			break
		if slot["id"] == material_id and slot["count"] < MAX_STACK:
			var can_add: int = min(MAX_STACK - int(slot["count"]), remaining)
			slot["count"] += can_add
			remaining -= can_add

	for slot in slots:
		if remaining <= 0:
			break
		if _is_empty_slot(slot):
			var stack_count: int = min(MAX_STACK, remaining)
			slot["id"] = material_id
			slot["count"] = stack_count
			remaining -= stack_count

	if remaining != amount:
		inventory_changed.emit()

	return remaining


func move_stack(from_container: String, from_index: int, to_container: String, to_index: int) -> void:
	if from_container == to_container and from_index == to_index:
		return

	var from_slots := get_slots(from_container)
	var to_slots := get_slots(to_container)
	if not _is_valid_index(from_slots, from_index) or not _is_valid_index(to_slots, to_index):
		return

	var from_slot: Dictionary = from_slots[from_index]
	var to_slot: Dictionary = to_slots[to_index]
	if _is_empty_slot(from_slot):
		return

	if _is_empty_slot(to_slot):
		to_slot["id"] = from_slot["id"]
		to_slot["count"] = from_slot["count"]
		_clear_slot(from_slot)
	elif to_slot["id"] == from_slot["id"]:
		var can_add: int = min(MAX_STACK - int(to_slot["count"]), int(from_slot["count"]))
		if can_add <= 0:
			return
		to_slot["count"] += can_add
		from_slot["count"] -= can_add
		if from_slot["count"] <= 0:
			_clear_slot(from_slot)
	else:
		var old_id: String = to_slot["id"]
		var old_count: int = to_slot["count"]
		to_slot["id"] = from_slot["id"]
		to_slot["count"] = from_slot["count"]
		from_slot["id"] = old_id
		from_slot["count"] = old_count

	inventory_changed.emit()


func get_slots(container_name: String) -> Array:
	if container_name == "warehouse":
		return warehouse_slots
	if container_name == "backpack":
		return backpack_slots
	return []


func get_slot(container_name: String, slot_index: int) -> Dictionary:
	var slots := get_slots(container_name)
	if not _is_valid_index(slots, slot_index):
		return _make_empty_slot()
	return slots[slot_index]


func set_slot(container_name: String, slot_index: int, material_id: String, count: int) -> void:
	var slots := get_slots(container_name)
	if not _is_valid_index(slots, slot_index):
		return

	if material_id == "" or count <= 0:
		_clear_slot(slots[slot_index])
	else:
		slots[slot_index]["id"] = material_id
		slots[slot_index]["count"] = clampi(count, 1, MAX_STACK)

	inventory_changed.emit()


func _make_slots(count: int) -> Array:
	var slots: Array = []
	for _i in range(count):
		slots.append(_make_empty_slot())
	return slots


func _make_empty_slot() -> Dictionary:
	return {
		"id": "",
		"count": 0
	}


func _clear_slot(slot: Dictionary) -> void:
	slot["id"] = ""
	slot["count"] = 0


func _is_empty_slot(slot: Dictionary) -> bool:
	return String(slot.get("id", "")) == "" or int(slot.get("count", 0)) <= 0


func _is_valid_index(slots: Array, index: int) -> bool:
	return index >= 0 and index < slots.size()
