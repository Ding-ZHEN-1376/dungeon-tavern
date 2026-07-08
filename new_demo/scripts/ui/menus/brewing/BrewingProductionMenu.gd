extends BaseInteractionMenu

@onready var title_label: Label = %TitleLabel
@onready var recipe_list: VBoxContainer = %RecipeList
@onready var message_label: Label = %MessageLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func setup(id: String, menu_context := {}) -> void:
	super.setup(id, menu_context)
	_refresh_recipes()


func _refresh_recipes() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	var learned_recipes: Array[Dictionary] = BrewingRecipeBook.get_learned_recipes()
	if learned_recipes.is_empty():
		message_label.text = "还没有学会任何酒。先去学习酿酒。"
		return

	message_label.text = "选择一种已学会的酒进行酿造。"
	for recipe in learned_recipes:
		var wine_id := String(recipe.get("wine_id", ""))
		var button := Button.new()
		button.text = _format_recipe_button(recipe)
		button.disabled = not _has_ingredients(recipe)
		button.pressed.connect(_brew_recipe.bind(wine_id))
		recipe_list.add_child(button)


func _brew_recipe(wine_id: String) -> void:
	var recipe: Dictionary = BrewingRecipeBook.get_recipe(wine_id)
	if recipe.is_empty():
		message_label.text = "没有找到这个配方。"
		return
	if not _has_ingredients(recipe):
		message_label.text = "材料不足。"
		_refresh_recipes()
		return
	if has_node("/root/ActivitySystem") and not ActivitySystem.can_perform_activity("brew"):
		message_label.text = "当前时间不能酿酒。"
		return

	if has_node("/root/ActivitySystem"):
		var time_result: Dictionary = ActivitySystem.perform_activity("brew")
		if not bool(time_result.get("ok", false)):
			message_label.text = String(time_result.get("message", "时间推进失败。"))
			return

	var ingredients: Dictionary = recipe.get("ingredients", {})
	for material_id in ingredients.keys():
		MaterialInventory.consume_item_from_container("backpack", String(material_id), int(ingredients[material_id]))
	MaterialInventory.add_item_to_container("backpack", wine_id, 1)
	message_label.text = "酿造完成：" + MaterialDatabase.get_display_name(wine_id)
	_refresh_recipes()


func _has_ingredients(recipe: Dictionary) -> bool:
	var ingredients: Dictionary = recipe.get("ingredients", {})
	for material_id in ingredients.keys():
		if MaterialInventory.get_item_count("backpack", String(material_id)) < int(ingredients[material_id]):
			return false
	return true


func _format_recipe_button(recipe: Dictionary) -> String:
	var wine_id := String(recipe.get("wine_id", ""))
	var ingredients: Dictionary = recipe.get("ingredients", {})
	var parts: Array[String] = []
	for material_id in ingredients.keys():
		parts.append("%s x%d" % [MaterialDatabase.get_display_name(String(material_id)), int(ingredients[material_id])])
	var tags: Array = recipe.get("method_tags", [])
	var tag_text := ""
	if not tags.is_empty():
		tag_text = " | 标签：" + ", ".join(tags)
	return "%s：%s%s" % [MaterialDatabase.get_display_name(wine_id), "，".join(parts), tag_text]


func _on_close_pressed() -> void:
	MenuManager.open_menu("brewing_barrel")
