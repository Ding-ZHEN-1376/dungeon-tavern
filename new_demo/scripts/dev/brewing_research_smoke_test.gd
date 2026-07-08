extends Node

const Catalog := preload("res://scripts/systems/brewing/brewing_research_catalog.gd")
const SessionScript := preload("res://scripts/systems/brewing/brewing_research_session.gd")
const RecipeBookScript := preload("res://scripts/systems/brewing/brewing_recipe_book.gd")


func _ready() -> void:
	var passed := true
	passed = _test_finish_before_start_cancels() and passed
	passed = _test_finish_before_input_cancels() and passed
	passed = _test_advanced_wheat_adds_input() and passed
	passed = _test_upper_left_discovery() and passed
	passed = _test_lower_right_discovery() and passed
	passed = _test_finish_failure() and passed
	passed = _test_recipe_book_records_material_counts() and passed
	if passed:
		print("Brewing research smoke tests passed.")
	else:
		push_error("Brewing research smoke tests failed.")
	await get_tree().create_timer(2.0).timeout
	get_tree().quit(0 if passed else 1)


func _test_finish_before_start_cancels() -> bool:
	var session = SessionScript.new()
	session.setup("dungeon_mushroom")
	var result: Dictionary = session.finish()
	return _expect(bool(result.get("cancelled", false)), "finish before start cancels")


func _test_finish_before_input_cancels() -> bool:
	var session = SessionScript.new()
	session.setup("dungeon_mushroom")
	session.start_research("basic_water", "basic_wheat")
	var result: Dictionary = session.finish()
	return _expect(bool(result.get("cancelled", false)), "finish before input cancels")


func _test_advanced_wheat_adds_input() -> bool:
	var session = SessionScript.new()
	session.setup("dungeon_mushroom")
	session.start_research("basic_water", "advanced_wheat")
	return _expect(int(session.get_status().get("max_inputs", 0)) == 6, "advanced wheat adds one input")


func _test_upper_left_discovery() -> bool:
	var session = SessionScript.new()
	session.setup("dungeon_mushroom")
	session.start_research("basic_water", "basic_wheat")
	var tools: Array[String] = ["grinder", "oven"]
	session.commit_input("cave_red_mushroom", Catalog.METHOD_GRIND, tools)
	session.commit_input("cave_blue_mushroom", Catalog.METHOD_GRIND, tools)
	session.commit_input("cave_red_mushroom", Catalog.METHOD_NONE, tools)
	var result: Dictionary = session.commit_input("cave_blue_mushroom", Catalog.METHOD_NONE, tools)
	return _expect(bool(result.get("success", false)), "upper-left route discovers wine")


func _test_lower_right_discovery() -> bool:
	var session = SessionScript.new()
	session.setup("dungeon_mushroom")
	session.start_research("basic_water", "basic_wheat")
	var tools: Array[String] = ["grinder", "oven"]
	session.commit_input("cave_red_mushroom", Catalog.METHOD_BAKE, tools)
	session.commit_input("cave_red_mushroom", Catalog.METHOD_BAKE, tools)
	session.commit_input("cave_blue_mushroom", Catalog.METHOD_BAKE, tools)
	var result: Dictionary = session.commit_input("cave_blue_mushroom", Catalog.METHOD_BAKE, tools)
	return _expect(bool(result.get("success", false)), "lower-right route discovers wine")


func _test_finish_failure() -> bool:
	var session = SessionScript.new()
	session.setup("dungeon_mushroom")
	session.start_research("basic_water", "basic_wheat")
	session.commit_input("cave_red_mushroom", Catalog.METHOD_NONE, ["grinder", "oven"])
	var result: Dictionary = session.finish()
	return _expect(not bool(result.get("success", true)) and bool(result.get("consumes_time", false)), "finish after input fails and consumes time")


func _test_recipe_book_records_material_counts() -> bool:
	var book = RecipeBookScript.new()
	book.learn_recipe("glowing_mushroom_wine", [
		{"material_id": "cave_red_mushroom", "method_id": Catalog.METHOD_GRIND},
		{"material_id": "cave_blue_mushroom", "method_id": Catalog.METHOD_GRIND},
		{"material_id": "cave_red_mushroom", "method_id": Catalog.METHOD_NONE}
	])
	var recipe: Dictionary = book.get_recipe("glowing_mushroom_wine")
	var ingredients: Dictionary = recipe.get("ingredients", {})
	return _expect(
		int(ingredients.get("cave_red_mushroom", 0)) == 2
		and int(ingredients.get("cave_blue_mushroom", 0)) == 1,
		"recipe book records material counts"
	)


func _expect(condition: bool, label: String) -> bool:
	if not condition:
		push_error("Expected: " + label)
	return condition
