extends CanvasLayer

const SLOT_SCENE := preload("res://scenes/ui/inventory/InventorySlot.tscn")
const BACKPACK_COLUMNS := 3
const PLAYER_INVENTORY_GROUP := "player_inventory"

@onready var panel: PanelContainer = %Panel
@onready var slots_grid: GridContainer = %SlotsGrid

var inventory_container: Node = null


func _ready() -> void:
	add_to_group("inventory_panel")
	slots_grid.columns = BACKPACK_COLUMNS
	hide_panel()
	call_deferred("refresh_inventory_container")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_panel()
		get_viewport().set_input_as_handled()


func show_panel() -> void:
	panel.visible = true


func hide_panel() -> void:
	panel.visible = false


func is_panel_visible() -> bool:
	return panel.visible


func toggle_panel() -> void:
	panel.visible = not panel.visible


func refresh_inventory_container() -> void:
	inventory_container = get_tree().get_first_node_in_group(PLAYER_INVENTORY_GROUP)
	_create_slots()


func _create_slots() -> void:
	for child in slots_grid.get_children():
		child.queue_free()

	if inventory_container == null or not inventory_container.has_method("get_slots"):
		push_warning("InventoryPanel could not find a node in group '%s'." % PLAYER_INVENTORY_GROUP)
		return

	var slots: Array = inventory_container.get_slots()
	for index in range(slots.size()):
		var slot := SLOT_SCENE.instantiate()
		slots_grid.add_child(slot)
		slot.setup(inventory_container, index)
