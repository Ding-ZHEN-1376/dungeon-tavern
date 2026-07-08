extends BaseInteractionMenu

const Catalog := preload("res://scripts/systems/brewing/brewing_research_catalog.gd")
const SessionScript := preload("res://scripts/systems/brewing/brewing_research_session.gd")
const Tools := preload("res://scripts/systems/brewing/brewing_player_tools.gd")

@onready var title_label: Label = %TitleLabel
@onready var map_grid: GridContainer = %MapGrid
@onready var status_label: Label = %StatusLabel
@onready var water_label: Label = %WaterLabel
@onready var water_list: VBoxContainer = %WaterList
@onready var grain_label: Label = %GrainLabel
@onready var grain_list: VBoxContainer = %GrainList
@onready var start_research_button: Button = %StartResearchButton
@onready var cancel_button: Button = %CancelButton
@onready var material_label: Label = %MaterialLabel
@onready var material_list: VBoxContainer = %MaterialList
@onready var method_label: Label = %MethodLabel
@onready var method_list: VBoxContainer = %MethodList
@onready var preview_label: Label = %PreviewLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var finish_button: Button = %FinishButton
@onready var close_button: Button = %CloseButton
@onready var log_label: RichTextLabel = %LogLabel

var session = null
var selected_material_id: String = ""
var selected_method_id: String = Catalog.METHOD_NONE
var selected_water_id: String = "basic_water"
var selected_grain_id: String = "basic_wheat"
var preview_result: Dictionary = {}
var cell_buttons: Dictionary = {}


func _ready() -> void:
	start_research_button.pressed.connect(_on_start_research_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	close_button.pressed.connect(_on_close_pressed)


func setup(id: String, menu_context := {}) -> void:
	super.setup(id, menu_context)
	var recipe_id := String(menu_context.get("recipe_id", "dungeon_mushroom"))
	session = SessionScript.new()
	session.setup(recipe_id)
	_build_map_grid()
	_build_base_option_buttons()
	_build_material_buttons()
	_set_research_controls_visible(false)
	_refresh_all()


func _build_map_grid() -> void:
	for child in map_grid.get_children():
		child.queue_free()
	cell_buttons.clear()

	var status: Dictionary = session.get_status()
	var grid_size: Vector2i = status["map_size"]
	map_grid.columns = grid_size.x

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, y)
			var button := Button.new()
			button.custom_minimum_size = Vector2(30, 30)
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE
			map_grid.add_child(button)
			cell_buttons[cell] = button


func _build_material_buttons() -> void:
	for child in material_list.get_children():
		child.queue_free()

	var current_status: Dictionary = session.get_status()
	var current_recipe_id := String(current_status["recipe_id"])
	for material_id in Catalog.get_allowed_materials(current_recipe_id):
		var button := Button.new()
		var count := MaterialInventory.get_item_count("backpack", material_id)
		button.text = "%s x%d" % [MaterialDatabase.get_display_name(material_id), count]
		button.disabled = count <= 0 or bool(current_status["is_finished"])
		button.pressed.connect(_select_material.bind(material_id))
		material_list.add_child(button)


func _build_base_option_buttons() -> void:
	for child in water_list.get_children():
		child.queue_free()
	for child in grain_list.get_children():
		child.queue_free()

	var current_recipe_id := String(session.get_status()["recipe_id"])
	for water_id in Catalog.get_water_options(current_recipe_id):
		var button := Button.new()
		button.text = "%s x%d" % [MaterialDatabase.get_display_name(water_id), MaterialInventory.get_item_count("backpack", water_id)]
		button.disabled = MaterialInventory.get_item_count("backpack", water_id) <= 0
		button.pressed.connect(_select_water.bind(water_id))
		water_list.add_child(button)

	for grain_id in Catalog.get_grain_options(current_recipe_id):
		var button := Button.new()
		button.text = "%s x%d" % [MaterialDatabase.get_display_name(grain_id), MaterialInventory.get_item_count("backpack", grain_id)]
		button.disabled = MaterialInventory.get_item_count("backpack", grain_id) <= 0
		button.pressed.connect(_select_grain.bind(grain_id))
		grain_list.add_child(button)


func _build_method_buttons() -> void:
	for child in method_list.get_children():
		child.queue_free()

	if selected_material_id == "":
		return

	var owned_tools := Tools.get_owned_tools()
	for method_id in Catalog.get_allowed_methods(selected_material_id):
		var method := Catalog.get_method(method_id)
		var required_tool := String(method.get("required_tool", ""))
		var button := Button.new()
		button.text = String(method.get("display_name", method_id))
		if required_tool != "" and not owned_tools.has(required_tool):
			button.text += "（需要工具）"
			button.disabled = true
		button.pressed.connect(_select_method.bind(method_id))
		method_list.add_child(button)


func _select_water(water_id: String) -> void:
	selected_water_id = water_id
	preview_label.text = "已选择水：" + MaterialDatabase.get_display_name(water_id)


func _select_grain(grain_id: String) -> void:
	selected_grain_id = grain_id
	preview_label.text = "已选择麦：" + MaterialDatabase.get_display_name(grain_id)


func _select_material(material_id: String) -> void:
	selected_material_id = material_id
	selected_method_id = Catalog.METHOD_NONE
	_build_method_buttons()
	_update_preview()


func _select_method(method_id: String) -> void:
	selected_method_id = method_id
	_update_preview()


func _update_preview() -> void:
	if selected_material_id == "":
		preview_result = {}
		preview_label.text = "请选择材料。"
		confirm_button.disabled = true
		_refresh_map()
		return

	preview_result = session.preview_input(selected_material_id, selected_method_id, Tools.get_owned_tools())
	preview_label.text = _format_preview(preview_result)
	confirm_button.disabled = not bool(preview_result.get("ok", false))
	_refresh_map()


func _on_start_research_pressed() -> void:
	if not _can_brew_now():
		preview_label.text = "当前时间不能学习酿酒。"
		return
	if not MaterialInventory.consume_item_from_container("backpack", selected_water_id, 1):
		preview_label.text = "缺少：" + MaterialDatabase.get_display_name(selected_water_id)
		return
	if not MaterialInventory.consume_item_from_container("backpack", selected_grain_id, 1):
		MaterialInventory.add_item_to_container("backpack", selected_water_id, 1)
		preview_label.text = "缺少：" + MaterialDatabase.get_display_name(selected_grain_id)
		return

	var result: Dictionary = session.start_research(selected_water_id, selected_grain_id)
	if not bool(result.get("ok", false)):
		MaterialInventory.add_item_to_container("backpack", selected_water_id, 1)
		MaterialInventory.add_item_to_container("backpack", selected_grain_id, 1)
		preview_label.text = String(result.get("message", "无法开始学习。"))
		return

	_append_log(result.get("message", ""))
	_set_research_controls_visible(true)
	_build_base_option_buttons()
	_build_material_buttons()
	_refresh_all()


func _on_cancel_pressed() -> void:
	_return_to_brewing_menu()


func _on_confirm_pressed() -> void:
	if selected_material_id == "":
		return
	if not MaterialInventory.consume_item_from_container("backpack", selected_material_id, 1):
		preview_label.text = "背包中没有足够材料。"
		return

	var result: Dictionary = session.commit_input(selected_material_id, selected_method_id, Tools.get_owned_tools())
	_append_log(result.get("message", ""))
	selected_material_id = ""
	selected_method_id = Catalog.METHOD_NONE
	_build_material_buttons()
	_build_method_buttons()
	_refresh_all()

	if bool(result.get("finished", false)):
		_on_research_finished(result)


func _on_finish_pressed() -> void:
	var result: Dictionary = session.finish()
	_on_research_finished(result)


func _on_close_pressed() -> void:
	close_menu()


func _on_research_finished(result: Dictionary) -> void:
	confirm_button.disabled = true
	finish_button.disabled = true
	if bool(result.get("cancelled", false)):
		_append_log(result.get("message", ""))
		_return_to_brewing_menu()
		return

	if bool(result.get("consumes_time", false)):
		_consume_brew_time()

	if bool(result.get("success", false)):
		var wine_id := String(result.get("wine_id", ""))
		BrewingRecipeBook.learn_recipe(wine_id, result.get("recipe_inputs", []))
		MaterialInventory.add_item_to_container("backpack", wine_id, 1)
		_append_log("学会配方并获得样酒：" + MaterialDatabase.get_display_name(wine_id))
	else:
		MaterialInventory.add_item_to_container("backpack", "failed_mushroom_wine", 1)
		_append_log("获得：" + MaterialDatabase.get_display_name("failed_mushroom_wine"))
	_append_log(result.get("message", ""))
	_build_material_buttons()
	_refresh_all()


func _refresh_all() -> void:
	var status: Dictionary = session.get_status()
	title_label.text = String(status.get("display_name", "酿酒研发"))
	status_label.text = "位置 %s / 投料 %d/%d" % [
		str(status["current_position"]),
		int(status["used_inputs"]),
		int(status["max_inputs"])
	]
	_update_preview()
	_refresh_map()


func _refresh_map() -> void:
	if session == null:
		return

	var preview_path: Array = preview_result.get("path", [])
	var preview_cells := {}
	for cell in preview_path:
		preview_cells[cell] = true

	for cell in cell_buttons.keys():
		var button: Button = cell_buttons[cell]
		var state: Dictionary = session.get_cell_state(cell)
		var wine_id := String(state.get("wine_id", ""))

		if bool(state["is_current"]):
			button.text = "@"
		elif preview_cells.has(cell):
			button.text = "+"
		elif bool(state["revealed"]) and wine_id != "":
			button.text = "W"
		elif bool(state["revealed"]):
			button.text = "."
		else:
			button.text = "?"

		if bool(state["is_current"]):
			button.modulate = Color(0.35, 0.9, 0.9)
		elif preview_cells.has(cell):
			button.modulate = Color(0.45, 0.7, 1.0)
		elif bool(state["revealed"]) and wine_id != "":
			button.modulate = Color(0.9, 0.75, 0.25)
		elif bool(state["revealed"]):
			button.modulate = Color(0.7, 0.7, 0.7)
		else:
			button.modulate = Color(0.2, 0.2, 0.2)


func _format_preview(result: Dictionary) -> String:
	if selected_material_id == "":
		return "请选择材料。"

	var material_name := MaterialDatabase.get_display_name(selected_material_id)
	var method_name := String(Catalog.get_method(selected_method_id).get("display_name", selected_method_id))
	if not bool(result.get("ok", false)):
		return "%s + %s：%s" % [material_name, method_name, String(result.get("message", ""))]
	return "%s + %s：终点 %s" % [material_name, method_name, str(result.get("end_position", Vector2i.ZERO))]


func _append_log(text: String) -> void:
	if text == "":
		return
	log_label.append_text(text + "\n")


func _set_research_controls_visible(show_research_controls: bool) -> void:
	material_label.visible = show_research_controls
	material_list.visible = show_research_controls
	method_label.visible = show_research_controls
	method_list.visible = show_research_controls
	confirm_button.visible = show_research_controls
	finish_button.visible = show_research_controls
	start_research_button.visible = not show_research_controls
	water_label.visible = not show_research_controls
	water_list.visible = not show_research_controls
	grain_label.visible = not show_research_controls
	grain_list.visible = not show_research_controls


func _can_brew_now() -> bool:
	if not has_node("/root/ActivitySystem"):
		return true
	return ActivitySystem.can_perform_activity("brew")


func _consume_brew_time() -> void:
	if has_node("/root/ActivitySystem"):
		var result: Dictionary = ActivitySystem.perform_activity("brew")
		if not bool(result.get("ok", false)):
			_append_log(String(result.get("message", "时间推进失败。")))


func _return_to_brewing_menu() -> void:
	MenuManager.open_menu("brewing_barrel")
