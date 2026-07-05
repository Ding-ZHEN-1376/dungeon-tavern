class_name InventoryContainer
extends Node

signal inventory_changed

@export var container_id: String = ""
@export var slot_count: int = 15
@export var max_stack: int = 64

var slots: Array = []


func _ready() -> void:
	if slots.is_empty():
		reset_inventory()


func reset_inventory() -> void:
	slots = _make_slots(slot_count)
	inventory_changed.emit()


func add_item(item_id: String, amount: int) -> int:
	if item_id == "" or amount <= 0:
		return amount

	if slots.is_empty():
		reset_inventory()

	var remaining := amount

	for slot in slots:
		if remaining <= 0:
			break
		if String(slot.get("id", "")) == item_id and int(slot.get("count", 0)) < max_stack:
			var can_add: int = min(max_stack - int(slot["count"]), remaining)
			slot["count"] += can_add
			remaining -= can_add

	for slot in slots:
		if remaining <= 0:
			break
		if is_empty_slot(slot):
			var stack_count: int = min(max_stack, remaining)
			slot["id"] = item_id
			slot["count"] = stack_count
			remaining -= stack_count

	if remaining != amount:
		inventory_changed.emit()

	return remaining


func get_slots() -> Array:
	if slots.is_empty():
		reset_inventory()
	return slots


func get_slot(slot_index: int) -> Dictionary:
	if not is_valid_index(slot_index):
		return make_empty_slot()
	return slots[slot_index]


func set_slot(slot_index: int, item_id: String, count: int) -> void:
	if not is_valid_index(slot_index):
		return

	if item_id == "" or count <= 0:
		clear_slot(slots[slot_index])
	else:
		slots[slot_index]["id"] = item_id
		slots[slot_index]["count"] = clampi(count, 1, max_stack)

	inventory_changed.emit()


func notify_inventory_changed() -> void:
	inventory_changed.emit()


func is_valid_index(slot_index: int) -> bool:
	if slots.is_empty():
		reset_inventory()
	return slot_index >= 0 and slot_index < slots.size()


func make_empty_slot() -> Dictionary:
	return {
		"id": "",
		"count": 0
	}


func clear_slot(slot: Dictionary) -> void:
	slot["id"] = ""
	slot["count"] = 0


func is_empty_slot(slot: Dictionary) -> bool:
	return String(slot.get("id", "")) == "" or int(slot.get("count", 0)) <= 0


func _make_slots(count: int) -> Array:
	var new_slots: Array = []
	for _i in range(maxi(count, 0)):
		new_slots.append(make_empty_slot())
	return new_slots
