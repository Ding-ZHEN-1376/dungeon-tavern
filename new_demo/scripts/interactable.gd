extends Area2D

@export var prompt_text: String = "按 E 互动"
@export var action_text: String = "互动成功"
@export var opens_menu: bool = false ## 交互是否开启菜单
@export var menu_id: String = "" ## 开启交互菜单的种类
@export var activity_id: String = "" ## 菜单要执行的任务类型
@export var activity_title: String = "" ## 任务菜单标题
@export_multiline var activity_description: String = "" ## 任务菜单说明

@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	prompt_label.text = prompt_text
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact() -> void:
	print(action_text)
	if opens_menu and menu_id != "":
		var opened_menu := MenuManager.open_menu(menu_id, {
			"source": self,
			"activity_id": activity_id,
			"activity_title": activity_title,
			"activity_description": activity_description
		})
		if opened_menu != null:
			get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_interactable"):
		body.set_interactable(self)
		prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("clear_interactable"):
		body.clear_interactable(self)
		prompt_label.visible = false
