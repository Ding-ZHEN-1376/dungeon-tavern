class_name InventoryTransfer
extends RefCounted


static func move_stack(from_container: Node, from_index: int, to_container: Node, to_index: int) -> void:
	if from_container == null or to_container == null:
		return
	if from_container == to_container and from_index == to_index:
		return
	if not _has_container_api(from_container) or not _has_container_api(to_container):
		return

	var from_slots: Array = from_container.get_slots()
	var to_slots: Array = to_container.get_slots()
	if not _is_valid_index(from_slots, from_index) or not _is_valid_index(to_slots, to_index):
		return

	var from_slot: Dictionary = from_slots[from_index]
	var to_slot: Dictionary = to_slots[to_index]
	if _is_empty_slot(from_slot):
		return

	var changed := false
	var max_stack: int = int(to_container.get("max_stack"))
	if max_stack <= 0:
		max_stack = 64

	if _is_empty_slot(to_slot):
		to_slot["id"] = from_slot["id"]
		to_slot["count"] = from_slot["count"]
		_clear_slot(from_slot)
		changed = true
	elif String(to_slot.get("id", "")) == String(from_slot.get("id", "")):
		var can_add: int = min(max_stack - int(to_slot.get("count", 0)), int(from_slot.get("count", 0)))
		if can_add <= 0:
			return
		to_slot["count"] += can_add
		from_slot["count"] -= can_add
		if int(from_slot["count"]) <= 0:
			_clear_slot(from_slot)
		changed = true
	else:
		var old_id: String = String(to_slot.get("id", ""))
		var old_count: int = int(to_slot.get("count", 0))
		to_slot["id"] = from_slot["id"]
		to_slot["count"] = from_slot["count"]
		from_slot["id"] = old_id
		from_slot["count"] = old_count
		changed = true

	if changed:
		_emit_container_changed(from_container)
		if to_container != from_container:
			_emit_container_changed(to_container)


static func _has_container_api(container: Node) -> bool:
	return container.has_method("get_slots") and container.has_method("notify_inventory_changed")


static func _emit_container_changed(container: Node) -> void:
	container.notify_inventory_changed()


static func _clear_slot(slot: Dictionary) -> void:
	slot["id"] = ""
	slot["count"] = 0


static func _is_empty_slot(slot: Dictionary) -> bool:
	return String(slot.get("id", "")) == "" or int(slot.get("count", 0)) <= 0


static func _is_valid_index(slots: Array, index: int) -> bool:
	return index >= 0 and index < slots.size()
