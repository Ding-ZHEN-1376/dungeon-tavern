# 角色动作交互模块
extends CharacterBody2D

# 移动速度
const SPEED: float = 120.0

var current_interactable: Node = null

# 移动函数
func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()

# 交互函数
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if current_interactable != null:
			current_interactable.interact()
		else:
			print("附近没有可以互动的对象")


func set_interactable(interactable: Node) -> void:
	current_interactable = interactable


func clear_interactable(interactable: Node) -> void:
	if current_interactable == interactable:
		current_interactable = null
