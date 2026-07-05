extends PanelContainer

const MaterialDatabaseScript := preload("res://scripts/systems/material_database.gd")
const InventoryTransferScript := preload("res://scripts/inventory/inventory_transfer.gd")

@export var slot_index: int = 0

@onready var icon_texture: TextureRect = %IconTexture
@onready var count_label: Label = %CountLabel

var inventory_container: Node = null


func _ready() -> void:
	_connect_inventory_changed()
	refresh()


func setup(new_inventory_container: Node, new_slot_index: int) -> void:
	_disconnect_inventory_changed()
	inventory_container = new_inventory_container
	slot_index = new_slot_index
	if is_node_ready():
		_connect_inventory_changed()
		refresh()


func refresh() -> void:
	if inventory_container == null or not inventory_container.has_method("get_slot"):
		_show_empty_slot()
		return

	var slot: Dictionary = inventory_container.get_slot(slot_index)
	var material_id := String(slot.get("id", ""))
	var count := int(slot.get("count", 0))

	if material_id == "" or count <= 0:
		_show_empty_slot()
		return

	var icon_path := MaterialDatabaseScript.get_icon_path(material_id)
	icon_texture.texture = load(icon_path) if icon_path != "" else null
	icon_texture.visible = icon_texture.texture != null
	count_label.text = str(count)
	count_label.visible = true
	tooltip_text = MaterialDatabaseScript.get_display_name(material_id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if inventory_container == null or not inventory_container.has_method("get_slot"):
		return null

	var slot: Dictionary = inventory_container.get_slot(slot_index)
	if String(slot.get("id", "")) == "" or int(slot.get("count", 0)) <= 0:
		return null

	var preview := TextureRect.new()
	preview.texture = icon_texture.texture
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {
		"container_node": inventory_container,
		"slot_index": slot_index
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		data is Dictionary
		and data.has("container_node")
		and data.has("slot_index")
		and inventory_container != null
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	InventoryTransferScript.move_stack(
		data["container_node"] as Node,
		int(data["slot_index"]),
		inventory_container,
		slot_index
	)


func _connect_inventory_changed() -> void:
	if inventory_container == null or not inventory_container.has_signal("inventory_changed"):
		return
	var refresh_callable := Callable(self, "refresh")
	if not inventory_container.is_connected("inventory_changed", refresh_callable):
		inventory_container.connect("inventory_changed", refresh_callable)


func _disconnect_inventory_changed() -> void:
	if inventory_container == null or not inventory_container.has_signal("inventory_changed"):
		return
	var refresh_callable := Callable(self, "refresh")
	if inventory_container.is_connected("inventory_changed", refresh_callable):
		inventory_container.disconnect("inventory_changed", refresh_callable)


func _show_empty_slot() -> void:
	icon_texture.texture = null
	icon_texture.visible = false
	count_label.text = ""
	count_label.visible = false
	tooltip_text = ""
