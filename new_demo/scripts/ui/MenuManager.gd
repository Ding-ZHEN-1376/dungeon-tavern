extends CanvasLayer

var current_menu: Control = null

var menu_registry := {
	"brewing_barrel": preload("res://scenes/ui/menus/brewing/BrewingMenu.tscn"),
	"warehouse": preload("res://scenes/ui/menus/storage/WarehouseMenu.tscn")
}


## 关闭旧菜单并按 menu_id 创建新的菜单实例。
func open_menu(menu_id: String, context := {}) -> Control:
	close_current_menu()

	if not menu_registry.has(menu_id):
		push_warning("Unknown menu_id: " + menu_id)
		return null

	current_menu = menu_registry[menu_id].instantiate()
	add_child(current_menu)

	if current_menu.has_method("setup"):
		current_menu.setup(menu_id, context)

	if current_menu.has_signal("menu_closed"):
		current_menu.connect("menu_closed", _on_menu_closed)

	return current_menu


## 销毁当前菜单实例，恢复为空菜单状态。
func close_current_menu() -> void:
	if current_menu != null and is_instance_valid(current_menu):
		current_menu.queue_free()
	current_menu = null


## 查询当前是否存在有效的菜单实例。
func is_menu_open() -> bool:
	return current_menu != null and is_instance_valid(current_menu)


## 菜单自行关闭后，同步清空 MenuManager 的引用。
func _on_menu_closed(_menu_id: String) -> void:
	current_menu = null
