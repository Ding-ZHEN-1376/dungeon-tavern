extends Node

var learned_recipes: Dictionary = {}


func learn_recipe(wine_id: String, recipe_inputs: Array) -> void:
	if wine_id == "":
		return

	var ingredients := {}
	var method_tags: Array[String] = []
	for input in recipe_inputs:
		var input_dict: Dictionary = input
		var material_id := String(input_dict.get("material_id", ""))
		var method_id := String(input_dict.get("method_id", "none"))
		if material_id == "":
			continue
		ingredients[material_id] = int(ingredients.get(material_id, 0)) + 1
		if method_id != "none":
			var tag := "%s:%s" % [material_id, method_id]
			if not method_tags.has(tag):
				method_tags.append(tag)

	learned_recipes[wine_id] = {
		"wine_id": wine_id,
		"ingredients": ingredients,
		"method_tags": method_tags
	}


func has_recipe(wine_id: String) -> bool:
	return learned_recipes.has(wine_id)


func get_recipe(wine_id: String) -> Dictionary:
	return learned_recipes.get(wine_id, {})


func get_learned_recipes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for wine_id in learned_recipes.keys():
		result.append(learned_recipes[wine_id])
	return result


func clear() -> void:
	learned_recipes.clear()
