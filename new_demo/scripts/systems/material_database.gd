extends RefCounted
class_name MaterialDatabase

const MATERIALS := {
	"water": {
		"display_name": "水",
		"icon": ""
	},
	"rye": {
		"display_name": "黑麦",
		"icon": ""
	},
	"basic_water": {
		"display_name": "基础水",
		"icon": ""
	},
	"advanced_water": {
		"display_name": "高级水",
		"icon": ""
	},
	"basic_wheat": {
		"display_name": "基础小麦",
		"icon": ""
	},
	"advanced_wheat": {
		"display_name": "高级小麦",
		"icon": ""
	},
	"cave_red_mushroom": {
		"display_name": "洞穴红蘑菇",
		"icon": "res://assets/materials/mushroom_temp.png"
	},
	"cave_blue_mushroom": {
		"display_name": "洞穴蓝蘑菇",
		"icon": "res://assets/materials/mushroom_temp.png"
	},
	"glowing_mushroom_wine": {
		"display_name": "发光蘑菇酒",
		"icon": "res://assets/materials/wine_temp.png"
	},
	"deep_mushroom_wine": {
		"display_name": "深层蘑菇酒",
		"icon": "res://assets/materials/wine_temp.png"
	},
	"failed_mushroom_wine": {
		"display_name": "浑浊蘑菇酒",
		"icon": "res://assets/materials/wine_temp.png"
	},
	"low_grade_sugar": {
		"display_name": "低级糖",
		"icon": "res://assets/materials/honey.png"
	},
	"mushroom": {
		"display_name": "蘑菇",
		"icon": "res://assets/materials/mushroom_temp.png"
	},
	"wine": {
		"display_name": "酒",
		"icon": "res://assets/materials/wine_temp.png"
	}
}


static func get_display_name(material_id: String) -> String:
	if not MATERIALS.has(material_id):
		return material_id
	return MATERIALS[material_id]["display_name"]


static func get_icon_path(material_id: String) -> String:
	if not MATERIALS.has(material_id):
		return ""
	return MATERIALS[material_id]["icon"]
