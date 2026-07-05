extends CanvasLayer

@onready var day_label: Label = %DayLabel
@onready var phase_label: Label = %PhaseLabel


func _ready() -> void:
	TimeSystem.time_changed.connect(_on_time_changed)
	_refresh()


func _on_time_changed(_day_index: int, _phase: String, _day_points_remaining: int) -> void:
	_refresh()


func _refresh() -> void:
	day_label.text = "第 %d 天" % TimeSystem.day_index
	if TimeSystem.is_day():
		phase_label.text = TimeSystem.DAY_SLOT_NAMES[TimeSystem.day_slot]
	elif TimeSystem.is_evening():
		phase_label.text = "傍晚"
	else:
		phase_label.text = "夜晚"
