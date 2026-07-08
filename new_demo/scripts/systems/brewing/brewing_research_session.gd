extends RefCounted
class_name BrewingResearchSession

const Catalog := preload("res://scripts/systems/brewing/brewing_research_catalog.gd")

var recipe_id: String = ""
var recipe: Dictionary = {}
var map_size: Vector2i = Vector2i.ZERO
var start_position: Vector2i = Vector2i.ZERO
var current_position: Vector2i = Vector2i.ZERO
var max_inputs: int = 0
var used_inputs: int = 0
var committed_inputs: Array[Dictionary] = []
var revealed_cells: Dictionary = {}
var discovered_wine_id: String = ""
var is_finished: bool = false
var is_started: bool = false
var base_water_id: String = ""
var base_grain_id: String = ""
var failure_result_id: String = "failed_mushroom_wine"


func setup(new_recipe_id: String) -> void:
	recipe_id = new_recipe_id
	recipe = Catalog.get_recipe(recipe_id)
	map_size = recipe.get("map_size", Vector2i(11, 11))
	start_position = recipe.get("start", Vector2i(5, 5))
	current_position = start_position
	max_inputs = int(recipe.get("max_inputs", 5))
	used_inputs = 0
	committed_inputs.clear()
	revealed_cells.clear()
	discovered_wine_id = ""
	is_finished = false
	is_started = false
	base_water_id = ""
	base_grain_id = ""
	_reveal_area(current_position, 1)


func start_research(water_id: String, grain_id: String) -> Dictionary:
	if is_finished:
		return {
			"ok": false,
			"message": "研发已经结束。"
		}
	if not Catalog.get_water_options(recipe_id).has(water_id):
		return {
			"ok": false,
			"message": "当前酒谱不能使用这个水。"
		}
	if not Catalog.get_grain_options(recipe_id).has(grain_id):
		return {
			"ok": false,
			"message": "当前酒谱不能使用这个麦。"
		}

	base_water_id = water_id
	base_grain_id = grain_id
	is_started = true
	max_inputs = int(recipe.get("max_inputs", 5))
	if grain_id == "advanced_wheat":
		max_inputs += 1
	if water_id == "advanced_water":
		_reveal_first_wine_zone()
	return {
		"ok": true,
		"message": "开始学习酿酒。"
	}


func preview_input(material_id: String, method_id: String, owned_tools: Array[String]) -> Dictionary:
	if is_finished:
		return _make_result(false, "研发已经结束。", [], current_position, "")
	if not is_started:
		return _make_result(false, "请先选择水和麦并开始学习。", [], current_position, "")
	if used_inputs >= max_inputs:
		return _make_result(false, "投料次数已经用完。", [], current_position, "")
	if not _is_material_allowed(material_id):
		return _make_result(false, "当前酒谱不能使用这个材料。", [], current_position, "")
	if not _is_method_allowed(material_id, method_id):
		return _make_result(false, "这个材料不能使用该处理方法。", [], current_position, "")
	if not _has_required_tool(method_id, owned_tools):
		return _make_result(false, "缺少对应处理道具。", [], current_position, "")

	var route := Catalog.build_route(material_id, method_id)
	var path := _build_absolute_path(current_position, route)
	if not _is_path_inside_map(path):
		return _make_result(false, "路线会超出酒谱地图。", path, current_position, "")
	if not _is_route_inside_local_limit(route):
		return _make_result(false, "单次路线超出 5x5 限制。", path, current_position, "")

	var end_position := current_position
	if not path.is_empty():
		end_position = path[path.size() - 1]
	return _make_result(true, "", path, end_position, _find_wine_at(end_position))


func commit_input(material_id: String, method_id: String, owned_tools: Array[String]) -> Dictionary:
	var preview := preview_input(material_id, method_id, owned_tools)
	if not bool(preview.get("ok", false)):
		return preview

	var path: Array = preview.get("path", [])
	for cell in path:
		_reveal_area(cell, 0)
	current_position = preview.get("end_position", current_position)
	_reveal_area(current_position, 1)
	used_inputs += 1
	committed_inputs.append({
		"material_id": material_id,
		"method_id": method_id,
		"path": path,
		"end_position": current_position
	})

	var wine_id := String(preview.get("wine_id", ""))
	if wine_id != "":
		discovered_wine_id = wine_id
		is_finished = true
		return {
			"ok": true,
			"finished": true,
			"success": true,
			"wine_id": discovered_wine_id,
			"recipe_inputs": get_recipe_inputs(),
			"consumes_time": true,
			"message": "发现了新的酒。"
		}

	if used_inputs >= max_inputs:
		return finish()

	return {
		"ok": true,
		"finished": false,
		"success": false,
		"wine_id": "",
		"message": "路线已确认。"
	}


func finish() -> Dictionary:
	if is_finished and discovered_wine_id != "":
		return {
			"ok": true,
			"finished": true,
			"success": true,
			"wine_id": discovered_wine_id,
			"recipe_inputs": get_recipe_inputs(),
			"consumes_time": false,
			"message": "研发已经成功。"
		}
	if not is_started or used_inputs == 0:
		is_finished = true
		return {
			"ok": true,
			"finished": true,
			"success": false,
			"cancelled": true,
			"wine_id": "",
			"recipe_inputs": [],
			"consumes_time": false,
			"message": "已取消学习酿酒。"
		}
	is_finished = true
	return {
		"ok": true,
		"finished": true,
		"success": false,
		"wine_id": failure_result_id,
		"recipe_inputs": get_recipe_inputs(),
		"consumes_time": true,
		"message": "研发失败，获得失败酒。"
	}


func get_recipe_inputs() -> Array[Dictionary]:
	var inputs: Array[Dictionary] = []
	if base_water_id != "":
		inputs.append({
			"material_id": base_water_id,
			"method_id": Catalog.METHOD_NONE
		})
	if base_grain_id != "":
		inputs.append({
			"material_id": base_grain_id,
			"method_id": Catalog.METHOD_NONE
		})
	for input in committed_inputs:
		inputs.append({
			"material_id": String(input.get("material_id", "")),
			"method_id": String(input.get("method_id", Catalog.METHOD_NONE))
		})
	return inputs


func get_status() -> Dictionary:
	return {
		"recipe_id": recipe_id,
		"display_name": recipe.get("display_name", recipe_id),
		"map_size": map_size,
		"current_position": current_position,
		"max_inputs": max_inputs,
		"used_inputs": used_inputs,
		"remaining_inputs": max_inputs - used_inputs,
		"is_finished": is_finished,
		"is_started": is_started,
		"base_water_id": base_water_id,
		"base_grain_id": base_grain_id,
		"discovered_wine_id": discovered_wine_id,
		"committed_inputs": committed_inputs
	}


func get_cell_state(cell: Vector2i) -> Dictionary:
	var wine_id := _find_wine_at(cell)
	return {
		"revealed": revealed_cells.has(cell),
		"is_current": cell == current_position,
		"is_start": cell == start_position,
		"wine_id": wine_id
	}


func _make_result(ok: bool, message: String, path: Array, end_position: Vector2i, wine_id: String) -> Dictionary:
	return {
		"ok": ok,
		"message": message,
		"path": path,
		"end_position": end_position,
		"wine_id": wine_id
	}


func _is_material_allowed(material_id: String) -> bool:
	return Catalog.get_allowed_materials(recipe_id).has(material_id)


func _is_method_allowed(material_id: String, method_id: String) -> bool:
	return Catalog.get_allowed_methods(material_id).has(method_id)


func _has_required_tool(method_id: String, owned_tools: Array[String]) -> bool:
	var method := Catalog.get_method(method_id)
	var required_tool := String(method.get("required_tool", ""))
	return required_tool == "" or owned_tools.has(required_tool)


func _build_absolute_path(from_position: Vector2i, route: Array[Vector2i]) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var position := from_position
	for step in route:
		position += step
		path.append(position)
	return path


func _is_path_inside_map(path: Array) -> bool:
	for cell in path:
		if not _is_inside_map(cell):
			return false
	return true


func _is_inside_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y


func _is_route_inside_local_limit(route: Array[Vector2i]) -> bool:
	var offset := Vector2i.ZERO
	for step in route:
		offset += step
		if abs(offset.x) > 2 or abs(offset.y) > 2:
			return false
	return true


func _reveal_area(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if _is_inside_map(cell):
				revealed_cells[cell] = true


func _reveal_first_wine_zone() -> void:
	var zones: Array = recipe.get("wine_zones", [])
	if zones.is_empty():
		return
	var zone: Dictionary = zones[0]
	var top_left: Vector2i = zone.get("top_left", Vector2i.ZERO)
	var size: Vector2i = zone.get("size", Vector2i.ONE)
	for y in range(top_left.y, top_left.y + size.y):
		for x in range(top_left.x, top_left.x + size.x):
			var cell := Vector2i(x, y)
			if _is_inside_map(cell):
				revealed_cells[cell] = true


func _find_wine_at(cell: Vector2i) -> String:
	for zone in recipe.get("wine_zones", []):
		var top_left: Vector2i = zone.get("top_left", Vector2i.ZERO)
		var size: Vector2i = zone.get("size", Vector2i.ONE)
		var inside_x := cell.x >= top_left.x and cell.x < top_left.x + size.x
		var inside_y := cell.y >= top_left.y and cell.y < top_left.y + size.y
		if inside_x and inside_y:
			return String(zone.get("id", ""))
	return ""
