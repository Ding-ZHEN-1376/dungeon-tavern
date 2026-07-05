extends BaseInteractionMenu

const SLOT_SCENE := preload("res://scenes/ui/inventory/InventorySlot.tscn")
const WAREHOUSE_COLUMNS := 4
const WAREHOUSE_INVENTORY_GROUP := "warehouse_inventory"

@onready var slots_grid: GridContainer = %SlotsGrid
@onready var close_button: Button = %CloseButton

var inventory_panel: Node = null
var inventory_panel_auto_opened := false
var warehouse_container: Node = null


func _ready() -> void:
	slots_grid.columns = WAREHOUSE_COLUMNS
	close_button.pressed.connect(_on_close_button_pressed)
	warehouse_container = get_tree().get_first_node_in_group(WAREHOUSE_INVENTORY_GROUP)
	_create_slots()

	inventory_panel = get_tree().get_first_node_in_group("inventory_panel")
	if inventory_panel != null and inventory_panel.has_method("show_panel"):
		if inventory_panel.has_method("refresh_inventory_container"):
			inventory_panel.refresh_inventory_container()
		var was_visible := false
		if inventory_panel.has_method("is_panel_visible"):
			was_visible = inventory_panel.is_panel_visible()
		inventory_panel.show_panel()
		inventory_panel_auto_opened = not was_visible


func _exit_tree() -> void:
	if inventory_panel_auto_opened and is_instance_valid(inventory_panel) and inventory_panel.has_method("hide_panel"):
		inventory_panel.hide_panel()


func _create_slots() -> void:
	for child in slots_grid.get_children():
		child.queue_free()

	if warehouse_container == null or not warehouse_container.has_method("get_slots"):
		push_warning("WarehouseMenu could not find a node in group '%s'." % WAREHOUSE_INVENTORY_GROUP)
		return

	var slots: Array = warehouse_container.get_slots()
	for index in range(slots.size()):
		var slot := SLOT_SCENE.instantiate()
		slots_grid.add_child(slot)
		slot.setup(warehouse_container, index)


func _on_close_button_pressed() -> void:
	emit_action("close")
	close_menu()
