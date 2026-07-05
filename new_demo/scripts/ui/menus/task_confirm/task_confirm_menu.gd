extends BaseInteractionMenu

@onready var title_label: Label = %TitleLabel
@onready var time_label: Label = %TimeLabel
@onready var description_label: Label = %DescriptionLabel
@onready var result_label: Label = %ResultLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton

var activity_id := ""
var is_result_state := false


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	_refresh()


func setup(id: String, menu_context := {}) -> void:
	super.setup(id, menu_context)
	activity_id = String(context.get("activity_id", ""))
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if activity_id == "":
		title_label.text = "未知任务"
		description_label.text = "这个交互对象还没有配置任务。"
		time_label.text = "当前时间：%s" % TimeSystem.get_time_label()
		_show_result_state("这个交互对象还没有配置任务。")
		return

	var custom_title := String(context.get("activity_title", ""))
	var custom_description := String(context.get("activity_description", ""))
	title_label.text = custom_title if custom_title != "" else ActivitySystem.get_activity_title(activity_id)
	description_label.text = custom_description if custom_description != "" else ActivitySystem.get_activity_description(activity_id)
	time_label.text = "当前时间：%s" % TimeSystem.get_time_label()

	var can_perform := ActivitySystem.can_perform_activity(activity_id)
	if can_perform:
		_show_confirm_state()
	else:
		_show_result_state(ActivitySystem.get_unavailable_message(activity_id))


func _on_confirm_button_pressed() -> void:
	if is_result_state:
		close_menu()
		return

	var result := ActivitySystem.perform_activity(activity_id)
	time_label.text = "当前时间：%s" % TimeSystem.get_time_label()
	var result_text := String(result.get("message", ""))
	var time_message := String(result.get("time_message", ""))
	if time_message != "":
		result_text += "\n" + time_message
	_show_result_state(result_text)


func _on_cancel_button_pressed() -> void:
	close_menu()


func _show_confirm_state() -> void:
	is_result_state = false
	result_label.text = ""
	confirm_button.text = "是"
	confirm_button.visible = true
	confirm_button.disabled = false
	cancel_button.visible = true
	cancel_button.disabled = false


func _show_result_state(message: String) -> void:
	is_result_state = true
	result_label.text = message
	confirm_button.text = "好的"
	confirm_button.visible = true
	confirm_button.disabled = false
	cancel_button.visible = false
	cancel_button.disabled = true
