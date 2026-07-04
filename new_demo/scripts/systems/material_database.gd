extends RefCounted
class_name MaterialDatabase

const MATERIALS := {
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
