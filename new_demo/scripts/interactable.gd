extends Area2D

@export var prompt_text: String = "按 E 互动"
@export var action_text: String = "互动成功"

@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	prompt_label.text = prompt_text
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact() -> void:
	print(action_text)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_interactable"):
		body.set_interactable(self)
		prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("clear_interactable"):
		body.clear_interactable(self)
		prompt_label.visible = false
