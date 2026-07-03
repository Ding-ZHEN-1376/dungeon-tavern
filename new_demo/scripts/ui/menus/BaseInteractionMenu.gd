extends Control
class_name BaseInteractionMenu

signal menu_action_pressed(menu_id: String, action_id: String)
signal menu_closed(menu_id: String)

var menu_id: String = ""
var context: Dictionary = {}


## 初始化菜单 ID 和打开菜单时传入的上下文数据。
func setup(id: String, menu_context := {}) -> void:
	menu_id = id
	context = menu_context


## 将菜单内部按钮操作转换为统一的菜单动作信号。
func emit_action(action_id: String) -> void:
	menu_action_pressed.emit(menu_id, action_id)


## 通知菜单关闭并销毁自身。
func close_menu() -> void:
	menu_closed.emit(menu_id)
	queue_free()
