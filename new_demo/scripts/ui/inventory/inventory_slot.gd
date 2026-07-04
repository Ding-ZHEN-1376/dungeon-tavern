extends PanelContainer

const MaterialDatabaseScript := preload("res://scripts/systems/material_database.gd")

@export var container_name: String = "backpack"
@export var slot_index: int = 0

@onready var icon_texture: TextureRect = %IconTexture
@onready var count_label: Label = %CountLabel


func _ready() -> void:
	if MaterialInventory.inventory_changed.is_connected(refresh):
		MaterialInventory.inventory_changed.disconnect(refresh)
	MaterialInventory.inventory_changed.connect(refresh)
	refresh()


func setup(new_container_name: String, new_slot_index: int) -> void:
	container_name = new_container_name
	slot_index = new_slot_index
	if is_node_ready():
		refresh()


func refresh() -> void:
	var slot := MaterialInventory.get_slot(container_name, slot_index)
	var material_id := String(slot.get("id", ""))
	var count := int(slot.get("count", 0))

	if material_id == "" or count <= 0:
		icon_texture.texture = null
		icon_texture.visible = false
		count_label.text = ""
		count_label.visible = false
		tooltip_text = ""
		return

	var icon_path := MaterialDatabaseScript.get_icon_path(material_id)
	icon_texture.texture = load(icon_path) if icon_path != "" else null
	icon_texture.visible = icon_texture.texture != null
	count_label.text = str(count)
	count_label.visible = true
	tooltip_text = MaterialDatabaseScript.get_display_name(material_id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var slot := MaterialInventory.get_slot(container_name, slot_index)
	if String(slot.get("id", "")) == "" or int(slot.get("count", 0)) <= 0:
		return null

	var preview := TextureRect.new()
	preview.texture = icon_texture.texture
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {
		"container": container_name,
		"slot_index": slot_index
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("container") and data.has("slot_index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	MaterialInventory.move_stack(
		String(data["container"]),
		int(data["slot_index"]),
		container_name,
		slot_index
	)
