extends RefCounted
class_name BrewingResearchCatalog

const METHOD_NONE := "none"
const METHOD_GRIND := "grind"
const METHOD_BAKE := "bake"

const RECIPES := {
	"dungeon_mushroom": {
		"display_name": "地牢蘑菇酒谱",
		"map_size": Vector2i(11, 11),
		"start": Vector2i(5, 5),
		"max_inputs": 5,
		"water_options": [
			"basic_water",
			"advanced_water"
		],
		"grain_options": [
			"basic_wheat",
			"advanced_wheat"
		],
		"allowed_materials": [
			"cave_red_mushroom",
			"cave_blue_mushroom"
		],
		"wine_zones": [
			{
				"id": "glowing_mushroom_wine",
				"display_name": "发光蘑菇酒",
				"top_left": Vector2i(1, 1),
				"size": Vector2i(2, 2)
			},
			{
				"id": "deep_mushroom_wine",
				"display_name": "深层蘑菇酒",
				"top_left": Vector2i(8, 8),
				"size": Vector2i(2, 2)
			}
		]
	}
}

const MATERIALS := {
	"basic_water": {
		"display_name": "基础水",
		"base_route": [],
		"methods": [METHOD_NONE]
	},
	"advanced_water": {
		"display_name": "高级水",
		"base_route": [],
		"methods": [METHOD_NONE]
	},
	"basic_wheat": {
		"display_name": "基础小麦",
		"base_route": [],
		"methods": [METHOD_NONE]
	},
	"advanced_wheat": {
		"display_name": "高级小麦",
		"base_route": [],
		"methods": [METHOD_NONE]
	},
	"cave_red_mushroom": {
		"display_name": "洞穴红蘑菇",
		"base_route": [Vector2i(0, -1)],
		"methods": [METHOD_NONE, METHOD_GRIND, METHOD_BAKE]
	},
	"cave_blue_mushroom": {
		"display_name": "洞穴蓝蘑菇",
		"base_route": [Vector2i(-1, 0)],
		"methods": [METHOD_NONE, METHOD_GRIND, METHOD_BAKE]
	}
}

const METHODS := {
	METHOD_NONE: {
		"display_name": "不处理",
		"required_tool": "",
		"description": "保留材料原始路线。"
	},
	METHOD_GRIND: {
		"display_name": "研磨",
		"required_tool": "grinder",
		"description": "延伸材料路线。"
	},
	METHOD_BAKE: {
		"display_name": "烘烤",
		"required_tool": "oven",
		"description": "反转并延伸材料路线。"
	}
}


static func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {})


static func get_material(material_id: String) -> Dictionary:
	return MATERIALS.get(material_id, {})


static func get_method(method_id: String) -> Dictionary:
	return METHODS.get(method_id, {})


static func get_allowed_materials(recipe_id: String) -> Array[String]:
	var recipe := get_recipe(recipe_id)
	var result: Array[String] = []
	for material_id in recipe.get("allowed_materials", []):
		result.append(String(material_id))
	return result


static func get_water_options(recipe_id: String) -> Array[String]:
	var recipe := get_recipe(recipe_id)
	var result: Array[String] = []
	for material_id in recipe.get("water_options", []):
		result.append(String(material_id))
	return result


static func get_grain_options(recipe_id: String) -> Array[String]:
	var recipe := get_recipe(recipe_id)
	var result: Array[String] = []
	for material_id in recipe.get("grain_options", []):
		result.append(String(material_id))
	return result


static func get_allowed_methods(material_id: String) -> Array[String]:
	var material := get_material(material_id)
	var result: Array[String] = []
	for method_id in material.get("methods", []):
		result.append(String(method_id))
	return result


static func build_route(material_id: String, method_id: String) -> Array[Vector2i]:
	var material := get_material(material_id)
	var base_route: Array[Vector2i] = []
	for step in material.get("base_route", []):
		base_route.append(step)

	if method_id == METHOD_NONE:
		return base_route
	if method_id == METHOD_GRIND:
		return _extend_route(base_route)
	if method_id == METHOD_BAKE:
		return _reverse_and_extend_route(base_route)
	return []


static func _extend_route(base_route: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for step in base_route:
		result.append(step)
		result.append(step)
	return result


static func _reverse_and_extend_route(base_route: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for step in base_route:
		var reversed := Vector2i(-step.x, -step.y)
		result.append(reversed)
		result.append(reversed)
	return result
