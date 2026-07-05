extends Node

signal activity_completed(result: Dictionary)
signal activity_failed(reason: String)

const ACTIVITY_TRADE := "trade"
const ACTIVITY_BATTLE_GATHER := "battle_gather"
const ACTIVITY_BREW := "brew"
const ACTIVITY_SLEEP := "sleep"
const ACTIVITY_TAVERN_SERVICE := "tavern_service"
const ACTIVITY_ARENA := "arena"

const ACTIVITY_DEFINITIONS := {
	ACTIVITY_TRADE: {
		"title": "交易",
		"description": "和商人交易，获得少量基础物资。",
		"allowed_phases": ["day"],
		"rewards": [{"item_id": "low_grade_sugar", "count": 1}]
	},
	ACTIVITY_BATTLE_GATHER: {
		"title": "战斗采集",
		"description": "外出探索，战斗并收集素材。",
		"allowed_phases": ["day", "evening", "night"],
		"rewards": [{"item_id": "mushroom", "count": 1}, {"item_id": "low_grade_sugar", "count": 1}]
	},
	ACTIVITY_BREW: {
		"title": "酿酒",
		"description": "整理酒桶并进行一次酿造准备。",
		"allowed_phases": ["day", "evening", "night"],
		"rewards": []
	},
	ACTIVITY_SLEEP: {
		"title": "睡觉",
		"description": "休息并推进时间。",
		"allowed_phases": ["day", "night"],
		"rewards": []
	},
	ACTIVITY_TAVERN_SERVICE: {
		"title": "酒馆营业",
		"description": "在傍晚接待客人并获得收入。",
		"allowed_phases": ["evening"],
		"rewards": [{"item_id": "low_grade_sugar", "count": 2}]
	},
	ACTIVITY_ARENA: {
		"title": "竞技场竞技",
		"description": "在夜晚参加竞技场挑战。",
		"allowed_phases": ["night"],
		"rewards": [{"item_id": "wine", "count": 1}]
	}
}

var time_system = null
var inventory_system = null


func can_perform_activity(activity_id: String) -> bool:
	var time = _get_time_system()
	if time == null or not ACTIVITY_DEFINITIONS.has(activity_id):
		return false
	if activity_id == ACTIVITY_SLEEP:
		return time.can_sleep()
	if time.is_forced_morning_sleep():
		return false

	var allowed_phases: Array = ACTIVITY_DEFINITIONS[activity_id]["allowed_phases"]
	return allowed_phases.has(time.phase)


func perform_activity(activity_id: String) -> Dictionary:
	if not ACTIVITY_DEFINITIONS.has(activity_id):
		return _fail("未知任务。")
	if not can_perform_activity(activity_id):
		return _fail(get_unavailable_message(activity_id))

	var time = _get_time_system()
	var definition: Dictionary = ACTIVITY_DEFINITIONS[activity_id]
	var rewards: Array = definition["rewards"]
	_apply_rewards(rewards)

	var time_result: Dictionary
	if activity_id == ACTIVITY_SLEEP:
		time_result = time.sleep()
	else:
		time_result = time.advance_after_activity(activity_id)

	if not bool(time_result.get("ok", false)):
		return _fail(String(time_result.get("message", "任务执行失败。")))

	var result := {
		"ok": true,
		"activity_id": activity_id,
		"title": definition["title"],
		"message": _get_success_message(activity_id),
		"time_message": time_result.get("message", ""),
		"rewards": rewards
	}
	activity_completed.emit(result)
	return result


func get_activity_title(activity_id: String) -> String:
	if not ACTIVITY_DEFINITIONS.has(activity_id):
		return "未知任务"
	return String(ACTIVITY_DEFINITIONS[activity_id]["title"])


func get_activity_description(activity_id: String) -> String:
	if not ACTIVITY_DEFINITIONS.has(activity_id):
		return "这个任务还没有配置。"
	return String(ACTIVITY_DEFINITIONS[activity_id]["description"])


func get_unavailable_message(activity_id: String) -> String:
	var time = _get_time_system()
	if time != null and time.is_forced_morning_sleep() and activity_id != ACTIVITY_SLEEP:
		return "你昨晚没有休息，现在必须先睡觉。"
	return "当前时间不能进行%s。" % get_activity_title(activity_id)


func _get_time_system():
	if time_system != null:
		return time_system
	if is_inside_tree():
		return get_node_or_null("/root/TimeSystem")
	return null


func _get_inventory_system():
	if inventory_system != null:
		return inventory_system
	if is_inside_tree():
		return get_node_or_null("/root/MaterialInventory")
	return null


func _apply_rewards(rewards: Array) -> void:
	var inventory = _get_inventory_system()
	if inventory == null:
		return
	for reward in rewards:
		inventory.add_item_to_container("backpack", String(reward["item_id"]), int(reward["count"]))


func _fail(message: String) -> Dictionary:
	activity_failed.emit(message)
	return {
		"ok": false,
		"message": message,
		"rewards": []
	}


func _get_success_message(activity_id: String) -> String:
	match activity_id:
		ACTIVITY_TRADE:
			return "交易完成，获得了少量物资。"
		ACTIVITY_BATTLE_GATHER:
			return "探索结束，获得了战利品和素材。"
		ACTIVITY_BREW:
			return "你完成了一次酿酒准备。"
		ACTIVITY_SLEEP:
			return "你休息了一段时间。"
		ACTIVITY_TAVERN_SERVICE:
			return "酒馆营业结束，获得了收入。"
		ACTIVITY_ARENA:
			return "竞技场挑战结束，获得了奖励。"
	return "任务完成。"
