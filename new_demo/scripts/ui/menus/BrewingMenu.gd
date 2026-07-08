extends BaseInteractionMenu

@onready var start_button: Button = %StartButton
@onready var recipe_button: Button = %RecipeButton
@onready var close_button: Button = %CloseButton


## 绑定酿酒菜单内部按钮到本菜单的信号释放逻辑。
func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	recipe_button.pressed.connect(_on_recipe_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)


## 释放开始酿酒动作信号，暂不连接实际酿酒系统。
func _on_start_button_pressed() -> void:
	MenuManager.open_menu("brewing_research", {
		"recipe_id": "dungeon_mushroom"
	})


## 释放查看配方动作信号，暂不连接实际配方系统。
func _on_recipe_button_pressed() -> void:
	MenuManager.open_menu("brewing_production")


## 释放关闭动作信号，并关闭当前菜单 UI。
func _on_close_button_pressed() -> void:
	emit_action("close")
	close_menu()
