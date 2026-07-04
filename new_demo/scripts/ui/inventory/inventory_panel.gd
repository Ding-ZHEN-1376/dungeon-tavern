extends CanvasLayer

const SLOT_SCENE := preload("res://scenes/ui/inventory/InventorySlot.tscn")
const BACKPACK_COLUMNS := 3
const BACKPACK_SLOT_COUNT := 15

@onready var panel: PanelContainer = %Panel
@onready var slots_grid: GridContainer = %SlotsGrid


func _ready() -> void:
	add_to_group("inventory_panel")
	slots_grid.columns = BACKPACK_COLUMNS
	_create_slots()
	hide_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_panel()
		get_viewport().set_input_as_handled()


func show_panel() -> void:
	panel.visible = true


func hide_panel() -> void:
	panel.visible = false


func toggle_panel() -> void:
	panel.visible = not panel.visible


func _create_slots() -> void:
	for child in slots_grid.get_children():
		child.queue_free()

	for index in range(BACKPACK_SLOT_COUNT):
		var slot := SLOT_SCENE.instantiate()
		slots_grid.add_child(slot)
		slot.setup("backpack", index)
