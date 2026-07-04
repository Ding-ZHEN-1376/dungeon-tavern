extends BaseInteractionMenu

const SLOT_SCENE := preload("res://scenes/ui/inventory/InventorySlot.tscn")
const WAREHOUSE_COLUMNS := 4
const WAREHOUSE_SLOT_COUNT := 40

@onready var slots_grid: GridContainer = %SlotsGrid
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	slots_grid.columns = WAREHOUSE_COLUMNS
	_create_slots()
	close_button.pressed.connect(_on_close_button_pressed)

	var inventory_panel := get_tree().get_first_node_in_group("inventory_panel")
	if inventory_panel != null and inventory_panel.has_method("show_panel"):
		inventory_panel.show_panel()


func _create_slots() -> void:
	for child in slots_grid.get_children():
		child.queue_free()

	for index in range(WAREHOUSE_SLOT_COUNT):
		var slot := SLOT_SCENE.instantiate()
		slots_grid.add_child(slot)
		slot.setup("warehouse", index)


func _on_close_button_pressed() -> void:
	emit_action("close")
	close_menu()
