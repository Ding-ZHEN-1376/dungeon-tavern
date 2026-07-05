# Tavern Growth Systems Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在当前 Godot 项目中分阶段实现出门菜单、白天/夜晚时间系统、夜晚 NPC 就餐交互、材料分类、酿造系统、配方系统和酒水相性系统。

**Architecture:** 延续当前项目已有的 `interactable.gd`、`MenuManager`、`MaterialInventory` 和菜单场景结构，不推翻现有实现。新增玩法规则放入独立 Autoload 系统中，UI 只负责展示和发出选择，数据计算、库存变更、时间推进、NPC 反馈都由系统脚本处理。

**Tech Stack:** Godot 4.7、GDScript、Autoload、Area2D 交互、Control UI、现有背包/仓库格子系统、轻量 SceneTree 测试脚本。

---

## 1. 当前项目评估

### 1.1 已经适合继续复用的部分

当前项目不是空项目，已经有几个后续系统可以直接接入的基础：

- `D:\godot_study\new_demo\scripts\interactable.gd`
  - 已经支持玩家靠近 `Area2D` 后显示交互提示。
  - 已经支持按 `E` 调用 `interact()`。
  - 已经支持通过 `opens_menu` 和 `menu_id` 打开菜单。
- `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`
  - 已经有统一菜单注册表 `menu_registry`。
  - 已经支持同一时间只打开一个交互菜单。
  - 已经支持菜单关闭后同步清理引用。
- `D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
  - 已经有背包和仓库两个容器。
  - 已经有堆叠、移动、交换的基础规则。
  - 已经发出 `inventory_changed` 信号供 UI 刷新。
- `D:\godot_study\new_demo\scripts\systems\material_database.gd`
  - 已经有材料 id 到显示名、图标的映射入口。
- `D:\godot_study\new_demo\scenes\main.tscn`
  - 已经放置了酿酒桶、仓库、床、桌子等可交互对象，适合作为第一版酒馆场景。

这些基础说明后续不需要重新写交互框架。正确方向是把新系统挂到现有交互和菜单结构上。

### 1.2 当前不合理点

#### 问题 1：业务规则还没有独立系统承接

`BrewingMenu.gd` 当前只发出 `start_brewing` 和 `open_recipe` 这类菜单动作，实际没有系统接收这些动作。后续如果直接把酿造计算写进 UI，会导致 UI、库存、时间、配方混在一起。

修改方向：

- 新增 `BrewingSystem` Autoload，专门负责酿造规则、配方匹配、酿造批次和产物生成。
- `BrewingMenu.gd` 只负责展示材料选择、手法选择、时长选择，并把玩家选择交给 `BrewingSystem`。
- `BrewingSystem` 成功创建酿造批次后，再通知 UI 刷新。

#### 问题 2：库存格子不能表达自酿酒

当前库存格子结构是：

```gdscript
{
	"id": "wine",
	"count": 1
}
```

这个结构适合普通材料，但不适合自酿酒。自酿酒需要保存五维评分、隐藏相性分、原料、手法、酿造天数、是否命名、是否可记录为配方等信息。

修改方向：

- 将格子结构升级为：

```gdscript
{
	"item_id": "custom_wine",
	"count": 1,
	"metadata": {
		"name": "",
		"scores": {
			"aroma": 0,
			"body": 0,
			"sweetness": 0,
			"purity": 0,
			"finish": 0
		},
		"hidden_affinity": 0,
		"source_batch": {},
		"created_day": 1
	}
}
```

- 普通材料使用 `metadata = {}`。
- `metadata` 不同的物品不自动堆叠，避免两瓶不同自酿酒被合并成同一种。

#### 问题 3：材料数据库字段不够

当前 `MaterialDatabase` 只有 `display_name` 和 `icon`。你要的酿造系统需要材料分类和风味属性。

修改方向：

- 每个材料增加 `category`：
  - `flavor`：风味材料，例如蘑菇、矿石、草药。
  - `water`：基础水材料，例如井水、污水、泉水。
  - `crop`：基础作物材料，例如黑麦、小麦。
  - `food`：食物。
  - `drink`：成品酒水。
- 每个可酿造材料增加 `brew_traits`：

```gdscript
"brew_traits": {
	"aroma": 2,
	"body": 0,
	"sweetness": 1,
	"purity": -1,
	"finish": 1
}
```

#### 问题 4：时间推进没有全局权威

未来会有出门、战斗、采集、酿造完成、夜晚 NPC、跳过夜晚等多个系统都影响时间。如果每个菜单自己改时间，会很快失控。

修改方向：

- 新增 `TimeSystem` Autoload，作为唯一时间状态来源。
- 白天有 3 个时间点。
- 白天行动消耗时间点。
- 时间点耗尽后进入夜晚。
- 夜晚不消耗时间点，只能通过菜单交互进入下一天。

#### 问题 5：玩家控制没有菜单锁

当前玩家 `_physics_process` 总是移动，`_unhandled_input` 总是可以交互。打开菜单时如果玩家仍能移动和反复按 E，会造成重复开菜单或交互状态混乱。

修改方向：

- 新增 `GameState` 或让 `MenuManager` 提供 `is_menu_open()` 作为判断。
- `player_main.gd` 在菜单打开时停止移动和交互输入。
- 所有菜单打开后应调用 `get_viewport().set_input_as_handled()`，避免同一次按键继续穿透。

---

## 2. 推荐实施顺序

这些系统有依赖关系，推荐按下面顺序推进：

1. 修正交互和菜单基础，避免后续系统接入时输入混乱。
2. 实现 `TimeSystem`，让白天 3 个时间点和夜晚切换先跑通。
3. 实现出门菜单和 `ActivitySystem`，让战斗/采集能消耗时间并给奖励。
4. 升级材料和库存数据结构，让系统能表达材料分类和自酿酒 metadata。
5. 实现第一版酿造系统，只做自定义酿造的规则层。
6. 实现配方系统，让“按配方酿造”和“自酿好酒后记录配方”成立。
7. 实现 NPC 数据、夜晚访客生成和就餐菜单。
8. 实现酒水/食物相性反馈和好感度反馈。
9. 增加存档读档，让跨天数据、NPC 好感、解锁配方、酿造批次可保存。

---

## 3. 文件结构规划

### 3.1 新增系统脚本

- `D:\godot_study\new_demo\scripts\systems\time_system.gd`
  - 保存日期、白天/夜晚阶段、剩余时间点。
  - 负责消耗时间点、进入夜晚、跳过夜晚。
- `D:\godot_study\new_demo\scripts\systems\activity_system.gd`
  - 处理出门菜单选择。
  - 调用时间系统消耗时间点。
  - 产出战斗奖励、采集奖励、配方奖励。
- `D:\godot_study\new_demo\scripts\systems\brewing_system.gd`
  - 校验酿造输入。
  - 创建酿造批次。
  - 根据材料、手法、时长生成酒。
- `D:\godot_study\new_demo\scripts\systems\recipe_book.gd`
  - 保存已解锁配方。
  - 根据材料组合和手法匹配配方。
  - 记录玩家自酿出的好酒配方。
- `D:\godot_study\new_demo\scripts\systems\npc_database.gd`
  - 保存 NPC 静态数据，例如名字、偏好、台词池。
- `D:\godot_study\new_demo\scripts\systems\npc_system.gd`
  - 生成夜晚来访 NPC。
  - 维护好感度。
  - 处理点餐、替代品、闲聊反馈。
- `D:\godot_study\new_demo\scripts\systems\affinity_system.gd`
  - 计算酒水/食物与 NPC 偏好的相性。
  - 把相性分映射为反馈等级。

### 3.2 新增 UI 场景和脚本

- `D:\godot_study\new_demo\scenes\ui\menus\outside\OutsideMenu.tscn`
- `D:\godot_study\new_demo\scripts\ui\menus\outside\outside_menu.gd`
  - 大门菜单，选项包括战斗、收集素材、取消。
- `D:\godot_study\new_demo\scenes\ui\menus\night\NightMenu.tscn`
- `D:\godot_study\new_demo\scripts\ui\menus\night\night_menu.gd`
  - 夜晚管理菜单，显示访客、打烊/跳过夜晚。
- `D:\godot_study\new_demo\scenes\ui\menus\npc\NpcDiningMenu.tscn`
- `D:\godot_study\new_demo\scripts\ui\menus\npc\npc_dining_menu.gd`
  - NPC 就餐交互菜单，支持满足需求、提供替代品、闲聊。
- `D:\godot_study\new_demo\scenes\ui\menus\brewing\BrewingCraftMenu.tscn`
- `D:\godot_study\new_demo\scripts\ui\menus\brewing\brewing_craft_menu.gd`
  - 自定义酿造材料选择、手法选择、时长选择。
- `D:\godot_study\new_demo\scenes\ui\menus\brewing\RecipeBrewingMenu.tscn`
- `D:\godot_study\new_demo\scripts\ui\menus\brewing\recipe_brewing_menu.gd`
  - 按配方酿造的配方列表和开始按钮。

### 3.3 修改现有文件

- `D:\godot_study\new_demo\project.godot`
  - 注册新增 Autoload。
  - 保留现有 `MenuManager` 和 `MaterialInventory`。
- `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`
  - 注册新菜单 id。
- `D:\godot_study\new_demo\scripts\player_main.gd`
  - 菜单打开时禁止移动和交互。
- `D:\godot_study\new_demo\scripts\interactable.gd`
  - 打开菜单后处理输入，避免按键穿透。
- `D:\godot_study\new_demo\scripts\systems\material_database.gd`
  - 增加材料分类和酿造属性。
- `D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
  - 支持 `metadata`。
  - 增加按分类查询、消耗材料、添加带 metadata 物品。
- `D:\godot_study\new_demo\scenes\main.tscn`
  - 添加大门交互点。
  - 添加夜晚管理交互点，第一版可以复用床或桌子。

---

## 4. 任务清单

### Task 1: 稳定菜单和玩家输入基础

**实现目标：** 打开任意交互菜单时，玩家不能继续移动，不能用同一次按键重复触发交互，关闭菜单后恢复正常控制。这个任务是后续所有菜单系统的基础。

**为什么先做：** 后续会新增出门菜单、夜晚菜单、NPC 菜单、酿造菜单。如果输入穿透不先处理，很多问题会被误判为业务系统错误。

**Files:**

- Modify: `D:\godot_study\new_demo\scripts\player_main.gd`
- Modify: `D:\godot_study\new_demo\scripts\interactable.gd`
- Modify: `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`
- Test: `D:\godot_study\new_demo\tests\test_menu_input_lock.gd`

**Detailed goals:**

- `MenuManager.is_menu_open()` 是玩家脚本判断是否允许移动和交互的唯一入口。
- `player_main.gd` 在菜单打开时把 `velocity` 设为 `Vector2.ZERO`，并跳过移动输入。
- `player_main.gd` 在菜单打开时不再触发 `current_interactable.interact()`。
- `interactable.gd` 在打开菜单后调用 `get_viewport().set_input_as_handled()` 的等价处理，避免一次 `E` 同时影响多个 UI。
- 不改变现有 `B` 键背包行为，背包可以继续作为独立 UI 存在。

**Implementation notes:**

建议在 `player_main.gd` 中使用这种判断：

```gdscript
func _physics_process(_delta: float) -> void:
	if MenuManager.is_menu_open():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()
```

`_unhandled_input` 也要加同样的菜单判断：

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if MenuManager.is_menu_open():
		return

	if event.is_action_pressed("interact"):
		if current_interactable != null:
			current_interactable.interact()
		else:
			print("附近没有可以互动的对象")
```

**Acceptance criteria:**

- 运行主场景，靠近仓库按 `E` 打开仓库菜单。
- 仓库菜单打开时，按方向键玩家不移动。
- 仓库菜单打开时，再按 `E` 不会重新触发当前交互对象。
- 关闭菜单后玩家恢复移动。
- 现有仓库菜单和酿造菜单仍能正常打开和关闭。

---

### Task 2: 实现 TimeSystem 白天/夜晚时间系统

**实现目标：** 建立全局时间权威，让游戏拥有“白天 3 个时间点”和“夜晚不消耗时间点、通过菜单跳过”的基本循环。

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\time_system.gd`
- Modify: `D:\godot_study\new_demo\project.godot`
- Test: `D:\godot_study\new_demo\tests\test_time_system.gd`

**Detailed goals:**

- 游戏开始时是第 1 天白天，剩余 3 个时间点。
- 白天行动可以调用 `consume_day_point(reason: String) -> bool`。
- 每成功消耗 1 点，`day_points_remaining` 减 1。
- 当剩余时间点变为 0 时，系统进入夜晚。
- 夜晚调用 `consume_day_point()` 必须返回 `false`，不扣点。
- 夜晚调用 `skip_night()` 进入下一天白天，并把时间点恢复到 3。
- 系统发出信号，让 UI 可以后续显示时间变化。

**Public API:**

```gdscript
extends Node

signal time_changed(day_index: int, phase: String, day_points_remaining: int)
signal night_started(day_index: int)
signal day_started(day_index: int)

const PHASE_DAY := "day"
const PHASE_NIGHT := "night"
const MAX_DAY_POINTS := 3

var day_index := 1
var phase := PHASE_DAY
var day_points_remaining := MAX_DAY_POINTS

func reset_time() -> void:
	day_index = 1
	phase = PHASE_DAY
	day_points_remaining = MAX_DAY_POINTS
	time_changed.emit(day_index, phase, day_points_remaining)

func is_day() -> bool:
	return phase == PHASE_DAY

func is_night() -> bool:
	return phase == PHASE_NIGHT

func consume_day_point(_reason: String) -> bool:
	if not is_day():
		return false
	if day_points_remaining <= 0:
		return false

	day_points_remaining -= 1
	if day_points_remaining <= 0:
		_enter_night()
	else:
		time_changed.emit(day_index, phase, day_points_remaining)
	return true

func skip_night() -> void:
	if not is_night():
		return
	day_index += 1
	phase = PHASE_DAY
	day_points_remaining = MAX_DAY_POINTS
	day_started.emit(day_index)
	time_changed.emit(day_index, phase, day_points_remaining)

func _enter_night() -> void:
	phase = PHASE_NIGHT
	night_started.emit(day_index)
	time_changed.emit(day_index, phase, day_points_remaining)
```

**Autoload registration:**

在 `project.godot` 的 `[autoload]` 中增加：

```ini
TimeSystem="*res://scripts/systems/time_system.gd"
```

**Acceptance criteria:**

- 新测试脚本能验证初始为第 1 天白天 3 点。
- 连续消耗 1、2、3 次后，第三次进入夜晚。
- 夜晚再次消耗时间点返回 `false`。
- 夜晚调用 `skip_night()` 后进入第 2 天白天 3 点。

---

### Task 3: 实现出门菜单 OutsideMenu

**实现目标：** 玩家靠近大门按 `E` 打开出门菜单，菜单提供“战斗”“收集素材”“取消”。战斗和收集素材都通过 `ActivitySystem` 执行，并消耗白天时间点。

**Files:**

- Create: `D:\godot_study\new_demo\scenes\ui\menus\outside\OutsideMenu.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\menus\outside\outside_menu.gd`
- Modify: `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`
- Modify: `D:\godot_study\new_demo\scenes\main.tscn`

**Detailed goals:**

- `MenuManager.menu_registry` 新增 `"outside"`。
- 主场景新增 `Door` 或 `OutsideDoor` 交互对象，挂载现有 `interactable.gd`。
- 大门交互对象设置：

```text
prompt_text = "按 E：出门"
action_text = "你走到门口。"
opens_menu = true
menu_id = "outside"
```

- 出门菜单显示当前时间状态：
  - 白天：显示剩余时间点。
  - 夜晚：显示“夜晚无法出门行动”。
- 白天可点击：
  - `战斗`：调用 `ActivitySystem.run_battle_activity()`。
  - `收集素材`：调用 `ActivitySystem.run_gather_activity()`。
  - `取消`：关闭菜单。
- 夜晚时战斗和收集按钮禁用，只能取消。

**Menu script responsibilities:**

`outside_menu.gd` 只负责按钮和展示，不直接改库存和时间。

```gdscript
extends BaseInteractionMenu

@onready var battle_button: Button = %BattleButton
@onready var gather_button: Button = %GatherButton
@onready var close_button: Button = %CloseButton
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	battle_button.pressed.connect(_on_battle_pressed)
	gather_button.pressed.connect(_on_gather_pressed)
	close_button.pressed.connect(_on_close_pressed)
	_refresh_state()

func _refresh_state() -> void:
	if TimeSystem.is_day():
		status_label.text = "白天剩余时间点：%d" % TimeSystem.day_points_remaining
		battle_button.disabled = false
		gather_button.disabled = false
	else:
		status_label.text = "现在是夜晚，不能出门行动。"
		battle_button.disabled = true
		gather_button.disabled = true

func _on_battle_pressed() -> void:
	ActivitySystem.run_battle_activity()
	close_menu()

func _on_gather_pressed() -> void:
	ActivitySystem.run_gather_activity()
	close_menu()

func _on_close_pressed() -> void:
	close_menu()
```

**Acceptance criteria:**

- 玩家靠近大门出现提示。
- 按 `E` 打开出门菜单。
- 白天能点击战斗和收集素材。
- 夜晚打开菜单时战斗和收集素材按钮禁用。
- 点击取消关闭菜单。

---

### Task 4: 实现 ActivitySystem 战斗/采集活动

**实现目标：** 把出门菜单的选择转化为可测试的游戏结果：消耗时间点、获得材料、可能获得配方。

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\activity_system.gd`
- Modify: `D:\godot_study\new_demo\project.godot`
- Test: `D:\godot_study\new_demo\tests\test_activity_system.gd`

**Detailed goals:**

- `run_battle_activity()` 只能在白天成功。
- `run_gather_activity()` 只能在白天成功。
- 每次成功活动都调用 `TimeSystem.consume_day_point()`。
- 如果时间点不足或当前是夜晚，活动返回失败结果，不给奖励。
- 战斗直接获得战利品，第一版不进入战斗场景。
- 收集素材直接获得材料。
- 结果用 Dictionary 返回，方便 UI 后续展示。

**Public API:**

```gdscript
extends Node

signal activity_completed(result: Dictionary)
signal activity_failed(reason: String)

func run_battle_activity() -> Dictionary:
	if not TimeSystem.consume_day_point("battle"):
		var failed := {"ok": false, "reason": "当前时间不能战斗。"}
		activity_failed.emit(failed["reason"])
		return failed

	var rewards := [
		{"item_id": "low_grade_sugar", "count": 2},
		{"item_id": "mushroom", "count": 1}
	]
	_apply_rewards(rewards)

	var result := {
		"ok": true,
		"activity": "battle",
		"message": "战斗结束，获得了战利品。",
		"rewards": rewards
	}
	activity_completed.emit(result)
	return result

func run_gather_activity() -> Dictionary:
	if not TimeSystem.consume_day_point("gather"):
		var failed := {"ok": false, "reason": "当前时间不能收集素材。"}
		activity_failed.emit(failed["reason"])
		return failed

	var rewards := [
		{"item_id": "well_water", "count": 3},
		{"item_id": "rye", "count": 2}
	]
	_apply_rewards(rewards)

	var result := {
		"ok": true,
		"activity": "gather",
		"message": "你带回了一些酿酒材料。",
		"rewards": rewards
	}
	activity_completed.emit(result)
	return result

func _apply_rewards(rewards: Array) -> void:
	for reward in rewards:
		MaterialInventory.add_item_to_container(
			"backpack",
			String(reward["item_id"]),
			int(reward["count"])
		)
```

**Autoload registration:**

```ini
ActivitySystem="*res://scripts/systems/activity_system.gd"
```

**Acceptance criteria:**

- 白天执行战斗后，时间点减少 1。
- 白天执行采集后，时间点减少 1。
- 连续活动 3 次后进入夜晚。
- 夜晚执行活动失败，不给奖励。
- 背包中能看到奖励材料。

---

### Task 5: 扩展材料数据库

**实现目标：** 让材料系统能区分风味材料、水材料、作物材料、食物、酒水，并为酿造和 NPC 相性提供基础属性。

**Files:**

- Modify: `D:\godot_study\new_demo\scripts\systems\material_database.gd`
- Test: `D:\godot_study\new_demo\tests\test_material_database.gd`

**Detailed goals:**

- 每个材料必须有：
  - `display_name`
  - `icon`
  - `category`
- 可用于酿造的材料必须有：
  - `brew_traits`
- 第一版至少定义这些物品：
  - `low_grade_sugar`：风味材料或辅料。
  - `mushroom`：风味材料。
  - `well_water`：基础水材料。
  - `dirty_water`：基础水材料。
  - `rye`：基础作物材料。
  - `wheat`：基础作物材料。
  - `simple_meal`：食物。
  - `custom_wine`：酒水产物模板。

**Recommended data shape:**

```gdscript
const CATEGORY_FLAVOR := "flavor"
const CATEGORY_WATER := "water"
const CATEGORY_CROP := "crop"
const CATEGORY_FOOD := "food"
const CATEGORY_DRINK := "drink"

const MATERIALS := {
	"well_water": {
		"display_name": "井水",
		"icon": "res://assets/materials/wine_temp.png",
		"category": CATEGORY_WATER,
		"brew_traits": {
			"aroma": 0,
			"body": 0,
			"sweetness": 0,
			"purity": 2,
			"finish": 0
		}
	},
	"dirty_water": {
		"display_name": "污水",
		"icon": "res://assets/materials/wine_temp.png",
		"category": CATEGORY_WATER,
		"brew_traits": {
			"aroma": -1,
			"body": 1,
			"sweetness": 0,
			"purity": -3,
			"finish": -1
		}
	},
	"rye": {
		"display_name": "黑麦",
		"icon": "res://assets/materials/honey.png",
		"category": CATEGORY_CROP,
		"brew_traits": {
			"aroma": 1,
			"body": 2,
			"sweetness": 0,
			"purity": 0,
			"finish": 1
		}
	},
	"mushroom": {
		"display_name": "蘑菇",
		"icon": "res://assets/materials/mushroom_temp.png",
		"category": CATEGORY_FLAVOR,
		"brew_traits": {
			"aroma": 2,
			"body": 1,
			"sweetness": -1,
			"purity": -1,
			"finish": 2
		}
	}
}
```

**Required helper functions:**

```gdscript
static func get_category(material_id: String) -> String:
	if not MATERIALS.has(material_id):
		return ""
	return String(MATERIALS[material_id].get("category", ""))

static func is_category(material_id: String, category: String) -> bool:
	return get_category(material_id) == category

static func get_brew_traits(material_id: String) -> Dictionary:
	if not MATERIALS.has(material_id):
		return {}
	return MATERIALS[material_id].get("brew_traits", {})
```

**Acceptance criteria:**

- 测试能验证 `well_water` 是 `water`。
- 测试能验证 `rye` 是 `crop`。
- 测试能验证 `mushroom` 是 `flavor`。
- 未知 id 返回空分类，不导致崩溃。
- `get_brew_traits()` 对可酿造材料返回五维字段。

---

### Task 6: 升级 MaterialInventory 支持 metadata

**实现目标：** 让库存既能保存普通材料，也能保存每瓶属性不同的自酿酒。

**Files:**

- Modify: `D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
- Modify: `D:\godot_study\new_demo\scripts\ui\inventory\inventory_slot.gd`
- Test: `D:\godot_study\new_demo\tests\test_material_inventory_metadata.gd`

**Detailed goals:**

- 新格子结构统一使用：

```gdscript
{
	"item_id": "",
	"count": 0,
	"metadata": {}
}
```

- 为兼容现有 UI，可短期保留读取旧字段 `"id"` 的兼容逻辑，但写入新数据时只写 `"item_id"`。
- 普通材料添加时 `metadata = {}`。
- `metadata = {}` 且 `item_id` 相同的材料可以堆叠。
- `metadata` 非空的物品只和完全相同 metadata 的物品堆叠。
- 自酿酒默认 `count = 1`，不建议堆叠。
- 新增 `consume_items(requirements: Array) -> bool`，供酿造和 NPC 交互消耗材料。
- 新增 `count_item(item_id: String) -> int`，供 UI 判断玩家是否有需求物品。

**Required APIs:**

```gdscript
func add_item_to_container(container_name: String, item_id: String, amount: int, metadata := {}) -> int:
	# 返回未放入数量。
	return amount

func consume_items(container_name: String, requirements: Array) -> bool:
	# requirements example:
	# [{"item_id": "well_water", "count": 1}, {"item_id": "rye", "count": 2}]
	return false

func count_item(container_name: String, item_id: String) -> int:
	return 0

func can_stack(slot: Dictionary, item_id: String, metadata: Dictionary) -> bool:
	return String(slot.get("item_id", "")) == item_id and slot.get("metadata", {}) == metadata
```

**Acceptance criteria:**

- 旧的普通材料仍能显示在背包 UI。
- 添加两个 `well_water` 能堆叠。
- 添加两瓶 metadata 不同的 `custom_wine` 时，占用两个格子。
- 消耗材料时，如果数量足够，扣除对应数量并返回 `true`。
- 消耗材料时，如果数量不足，不改变库存并返回 `false`。

---

### Task 7: 实现 BrewingSystem 自定义酿造核心

**实现目标：** 玩家可以选择水、作物、0 到 3 种风味材料、酿造手法、酿造时长，系统校验输入并创建酿造批次。批次完成后生成一瓶未命名酒。

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\brewing_system.gd`
- Modify: `D:\godot_study\new_demo\project.godot`
- Test: `D:\godot_study\new_demo\tests\test_brewing_system.gd`

**Detailed goals:**

- 自定义酿造必须包含：
  - 1 种水材料。
  - 1 种作物材料。
  - 0 到 3 种风味材料。
  - 每种材料数量 1 到 5。
  - 1 种酿造手法。
  - 1 个酿造时长。
- 第一版只开放 `yeast` 酵母酿造。
- 酿造时长用“天”表示，第一版允许 1 到 5 天。
- 创建批次时立刻消耗材料。
- 批次保存 `finish_day`。
- 当当前天数达到 `finish_day`，玩家可以开箱获得 `custom_wine`。
- 产物 metadata 包含五维评分、隐藏相性分、原始材料、手法、时长。

**Public data shape:**

```gdscript
var active_batches: Array = []

# batch example:
{
	"batch_id": 1,
	"water": {"item_id": "well_water", "count": 1},
	"crop": {"item_id": "rye", "count": 2},
	"flavors": [
		{"item_id": "mushroom", "count": 1}
	],
	"method": "yeast",
	"duration_days": 2,
	"start_day": 1,
	"finish_day": 3,
	"opened": false
}
```

**Required APIs:**

```gdscript
signal batch_started(batch: Dictionary)
signal batch_opened(batch: Dictionary, wine_metadata: Dictionary)
signal brewing_failed(reason: String)

func start_custom_brew(water: Dictionary, crop: Dictionary, flavors: Array, method: String, duration_days: int) -> Dictionary:
	return {}

func get_ready_batches() -> Array:
	return []

func open_batch(batch_id: int) -> Dictionary:
	return {}
```

**Scoring algorithm, first version:**

- 从所有材料的 `brew_traits` 加权求和。
- 水材料权重为 `1.0`。
- 作物材料权重为 `1.2`。
- 风味材料权重为 `0.8 * count`。
- 酿造时长给少量修正：
  - 1 天：`purity -1`，`aroma +1`。
  - 2 到 3 天：无惩罚。
  - 4 到 5 天：`body +1`，`finish +1`，`sweetness -1`。
- 最终每项 clamp 到 0 到 10。
- 隐藏相性分第一版可以是五维总分，但不要直接展示给玩家。

**Acceptance criteria:**

- 没有水材料时，酿造失败。
- 没有作物材料时，酿造失败。
- 风味材料超过 3 种时，酿造失败。
- 任意材料数量超过 5 时，酿造失败。
- 未解锁的手法酿造失败。
- 成功开始酿造后背包材料减少。
- 到达完成日期后开箱，背包获得一瓶 `custom_wine`。
- 自酿酒 metadata 中有五维评分和原始批次信息。

---

### Task 8: 实现酿造 UI 第一版

**实现目标：** 玩家通过酿酒桶打开菜单，能选择“按配方酿造”或“自定义酿造”。第一版重点让自定义酿造能从现有背包材料中选择并调用 `BrewingSystem`。

**Files:**

- Modify: `D:\godot_study\new_demo\scenes\ui\menus\brewing\BrewingMenu.tscn`
- Modify: `D:\godot_study\new_demo\scripts\ui\menus\BrewingMenu.gd`
- Create: `D:\godot_study\new_demo\scenes\ui\menus\brewing\BrewingCraftMenu.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\menus\brewing\brewing_craft_menu.gd`
- Create: `D:\godot_study\new_demo\scenes\ui\menus\brewing\BatchListMenu.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\menus\brewing\batch_list_menu.gd`
- Modify: `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`

**Detailed goals:**

- 原有酿造菜单变成入口菜单：
  - `自定义酿造`
  - `按配方酿造`
  - `查看酿造箱`
  - `关闭`
- 自定义酿造菜单显示：
  - 可用水材料列表。
  - 可用作物材料列表。
  - 可用风味材料列表，最多选 3 种。
  - 每种材料数量选择 1 到 5。
  - 酿造手法选择，第一版只有酵母酿造。
  - 酿造时长选择 1 到 5 天。
  - 开始酿造按钮。
- 查看酿造箱菜单显示：
  - 正在酿造批次。
  - 已完成批次。
  - 已完成批次可以点击开箱。

**UI constraints:**

- UI 不直接计算评分。
- UI 不直接扣材料。
- UI 不直接生成酒。
- 所有酿造动作通过 `BrewingSystem`。

**Acceptance criteria:**

- 酿酒桶按 `E` 后能打开入口菜单。
- 点击自定义酿造能进入材料选择菜单。
- 材料选择只显示对应分类材料。
- 输入合法时点击开始，菜单关闭或显示成功信息。
- 输入非法时显示失败原因，不扣材料。
- 到达完成日期后，查看酿造箱能开箱获得酒。

---

### Task 9: 实现 RecipeBook 配方系统

**实现目标：** 支持解锁配方、按配方一键酿造、从高质量自酿酒记录配方。

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\recipe_book.gd`
- Create: `D:\godot_study\new_demo\scenes\ui\menus\brewing\RecipeBrewingMenu.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\menus\brewing\recipe_brewing_menu.gd`
- Modify: `D:\godot_study\new_demo\scripts\systems\activity_system.gd`
- Test: `D:\godot_study\new_demo\tests\test_recipe_book.gd`

**Detailed goals:**

- 配方有静态定义和解锁状态。
- 配方定义包括：
  - `recipe_id`
  - `display_name`
  - `required_items`
  - `method`
  - `duration_days`
  - `expected_scores`
- 第一版至少定义 2 个配方：
  - `plain_rye_wine`
  - `mushroom_rye_wine`
- 解锁来源支持：
  - `purchase`
  - `npc`
  - `battle`
  - `self_discovered`
- 战斗活动有概率或固定条件解锁一个配方。
- 自酿酒总评分达到阈值时，允许记录为 `self_discovered` 配方。

**Required APIs:**

```gdscript
signal recipe_unlocked(recipe_id: String, source: String)

func is_unlocked(recipe_id: String) -> bool:
	return false

func unlock_recipe(recipe_id: String, source: String) -> bool:
	return false

func get_unlocked_recipes() -> Array:
	return []

func can_brew_recipe(recipe_id: String) -> bool:
	return false

func start_recipe_brew(recipe_id: String) -> Dictionary:
	return {}

func record_recipe_from_wine(wine_metadata: Dictionary) -> Dictionary:
	return {}
```

**Acceptance criteria:**

- 未解锁配方不显示或显示为锁定。
- 解锁配方后，配方菜单可见。
- 材料足够时，按配方酿造成功创建批次。
- 材料不足时，按配方酿造失败且不扣材料。
- 自酿好酒能记录为新配方。

---

### Task 10: 实现夜晚入口和跳过夜晚菜单

**实现目标：** 当白天 3 个时间点耗尽后进入夜晚。夜晚出现就餐阶段，玩家可以处理 NPC，也可以通过菜单打烊进入下一天。

**Files:**

- Create: `D:\godot_study\new_demo\scenes\ui\menus\night\NightMenu.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\menus\night\night_menu.gd`
- Modify: `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`
- Modify: `D:\godot_study\new_demo\scenes\main.tscn`

**Detailed goals:**

- 夜晚菜单可以挂在床、桌子或一个单独的 `NightServiceDesk` 交互点上。
- 白天打开夜晚菜单时，显示“现在还不是夜晚”。
- 夜晚打开菜单时，显示：
  - 当前来访 NPC 列表。
  - `打烊休息` 按钮。
- 点击 `打烊休息` 调用 `TimeSystem.skip_night()`。
- 跳过夜晚后进入下一天白天 3 点。

**Acceptance criteria:**

- 白天时间点耗尽后，`TimeSystem.is_night()` 为 `true`。
- 夜晚菜单中可以点击打烊。
- 打烊后进入下一天白天。
- 夜晚不消耗时间点。

---

### Task 11: 实现 NPC 静态数据和夜晚来访

**实现目标：** 夜晚生成 NPC 来酒馆就餐，每个 NPC 有需求、偏好、好感度和基础反馈文本。

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\npc_database.gd`
- Create: `D:\godot_study\new_demo\scripts\systems\npc_system.gd`
- Modify: `D:\godot_study\new_demo\project.godot`
- Test: `D:\godot_study\new_demo\tests\test_npc_system.gd`

**Detailed goals:**

- 第一版至少定义 2 个 NPC。
- 每个 NPC 有：
  - `npc_id`
  - `display_name`
  - `favorite_food_tags`
  - `favorite_drink_profile`
  - `disliked_traits`
  - `base_request_pool`
  - `chat_lines_by_affection`
- `NpcSystem` 监听 `TimeSystem.night_started`。
- 每晚生成 1 到 2 个 NPC。
- 每个来访 NPC 生成一个需求：
  - 食物需求。
  - 酒水需求。
  - 或食物 + 酒水需求。
- 好感度存储在 `NpcSystem.affection` 中。

**NPC data example:**

```gdscript
const NPCS := {
	"miner_hao": {
		"display_name": "矿工阿豪",
		"favorite_food_tags": ["hearty", "salty"],
		"favorite_drink_profile": {
			"body": 3,
			"purity": -1,
			"finish": 2
		},
		"disliked_traits": ["too_sweet"],
		"base_request_pool": [
			{"food": "simple_meal", "drink": "custom_wine"}
		],
		"chat_lines_by_affection": {
			"low": ["我只是来吃点东西。"],
			"mid": ["今天矿洞里有些奇怪的痕迹。"],
			"high": ["下次我带些矿石给你试试酿酒。"]
		}
	}
}
```

**Acceptance criteria:**

- 进入夜晚时生成访客列表。
- 访客有明确需求。
- 连续不同夜晚可以生成不同访客或不同需求。
- 好感度默认存在，初始值为 0。

---

### Task 12: 实现 NPC 就餐交互菜单

**实现目标：** 玩家可以和夜晚 NPC 交互，查看 NPC 需求，提供需求物品或替代物品，也可以闲聊。

**Files:**

- Create: `D:\godot_study\new_demo\scenes\ui\menus\npc\NpcDiningMenu.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\menus\npc\npc_dining_menu.gd`
- Modify: `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`
- Modify: `D:\godot_study\new_demo\scripts\systems\npc_system.gd`

**Detailed goals:**

- 夜晚菜单中的 NPC 列表可以打开某个 NPC 的就餐菜单。
- NPC 就餐菜单显示：
  - NPC 名字。
  - 当前需求。
  - 玩家是否拥有需求食物。
  - 玩家是否拥有需求酒水。
  - `提交需求物品` 按钮。
  - `提供其他食物/酒水` 按钮。
  - `闲聊` 按钮。
  - `返回` 按钮。
- 满足需求：
  - 消耗对应物品。
  - 调用 `NpcSystem.serve_requested_items()`。
  - 提升好感。
  - 返回明确反馈文本。
- 提供替代品：
  - 允许玩家选择其他食物或酒水。
  - 调用 `AffinitySystem` 算相性。
  - 根据相性给反馈并调整好感。
- 闲聊：
  - 不消耗物品。
  - 根据当前好感度返回不同台词。

**Acceptance criteria:**

- NPC 菜单能显示需求。
- 背包有所需物品时，提交按钮可用。
- 提交需求物品后背包扣除物品。
- 替代品反馈会根据相性不同而不同。
- 闲聊文本会随好感度变化。

---

### Task 13: 实现 AffinitySystem 酒水和食物相性

**实现目标：** 用统一规则计算 NPC 对酒水/食物的满意程度，让“没有指定需求时提供其他物品”的反馈有玩法依据。

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\affinity_system.gd`
- Modify: `D:\godot_study\new_demo\project.godot`
- Modify: `D:\godot_study\new_demo\scripts\systems\npc_system.gd`
- Test: `D:\godot_study\new_demo\tests\test_affinity_system.gd`

**Detailed goals:**

- 酒水相性使用酒的五维评分和 NPC 的偏好权重。
- 食物相性第一版可以使用标签匹配。
- 输出标准化反馈等级：
  - `great`
  - `good`
  - `neutral`
  - `bad`
- 不直接向玩家显示隐藏分。
- `NpcSystem` 根据反馈等级调整好感度：
  - `great`: +3
  - `good`: +1
  - `neutral`: 0
  - `bad`: -1

**Required APIs:**

```gdscript
func rate_drink_for_npc(wine_metadata: Dictionary, npc_id: String) -> Dictionary:
	return {
		"score": 0,
		"rating": "neutral",
		"message": ""
	}

func rate_food_for_npc(food_item_id: String, npc_id: String) -> Dictionary:
	return {
		"score": 0,
		"rating": "neutral",
		"message": ""
	}
```

**Drink scoring first version:**

- NPC 的 `favorite_drink_profile` 是五维权重。
- 酒的 `scores` 是五维评分。
- 相性分 = 五维评分和偏好权重的点积。
- 如果 NPC 不喜欢甜，甜度过高额外扣分。
- 评分映射：
  - `score >= 18`: `great`
  - `score >= 10`: `good`
  - `score >= 3`: `neutral`
  - `score < 3`: `bad`

**Acceptance criteria:**

- 同一瓶酒对不同 NPC 可以得到不同反馈。
- 高匹配酒返回 `great` 或 `good`。
- 低匹配酒返回 `neutral` 或 `bad`。
- `NpcSystem` 使用相性结果调整好感。

---

### Task 14: 增加时间、活动、酿造、NPC 的 HUD/反馈文本

**实现目标：** 玩家执行行动后能看到当前天数、时间段、剩余时间点、获得奖励、NPC 反馈和酿造结果。

**Files:**

- Create: `D:\godot_study\new_demo\scenes\ui\hud\GameHud.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\hud\game_hud.gd`
- Modify: `D:\godot_study\new_demo\scenes\main.tscn`
- Modify: `D:\godot_study\new_demo\scripts\systems\activity_system.gd`
- Modify: `D:\godot_study\new_demo\scripts\systems\brewing_system.gd`
- Modify: `D:\godot_study\new_demo\scripts\systems\npc_system.gd`

**Detailed goals:**

- HUD 常驻主场景。
- 显示：
  - 第几天。
  - 当前是白天还是夜晚。
  - 白天剩余时间点。
  - 最近一条系统消息。
- 监听：
  - `TimeSystem.time_changed`
  - `ActivitySystem.activity_completed`
  - `ActivitySystem.activity_failed`
  - `BrewingSystem.batch_started`
  - `BrewingSystem.batch_opened`
  - `NpcSystem.npc_feedback`
- 系统消息只显示简短结果，不替代详细菜单。

**Acceptance criteria:**

- 消耗时间点后 HUD 更新。
- 进入夜晚后 HUD 显示夜晚。
- 战斗/采集后 HUD 显示奖励摘要。
- 开箱获得酒后 HUD 显示新酒摘要。
- NPC 反馈后 HUD 显示简短反馈。

---

### Task 15: 实现存档读档第一版

**实现目标：** 保存长期进度，避免玩家每次运行都丢失天数、库存、配方、NPC 好感、酿造批次。

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\save_system.gd`
- Modify: `D:\godot_study\new_demo\project.godot`
- Modify: `D:\godot_study\new_demo\scripts\systems\time_system.gd`
- Modify: `D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
- Modify: `D:\godot_study\new_demo\scripts\systems\brewing_system.gd`
- Modify: `D:\godot_study\new_demo\scripts\systems\recipe_book.gd`
- Modify: `D:\godot_study\new_demo\scripts\systems\npc_system.gd`
- Test: `D:\godot_study\new_demo\tests\test_save_system.gd`

**Detailed goals:**

- 使用 `user://savegame.json` 保存第一版进度。
- 每个系统提供：
  - `get_save_data() -> Dictionary`
  - `load_save_data(data: Dictionary) -> void`
- 保存内容：
  - 当前天数、阶段、剩余时间点。
  - 背包和仓库。
  - 酿造批次。
  - 已解锁配方。
  - NPC 好感度。
- 加载时缺字段不崩溃，使用默认值。
- 第一版可以在菜单或快捷键中手动保存，之后再加自动保存。

**Required APIs:**

```gdscript
func save_game() -> bool:
	return false

func load_game() -> bool:
	return false

func build_save_data() -> Dictionary:
	return {}

func apply_save_data(data: Dictionary) -> void:
	pass
```

**Acceptance criteria:**

- 修改库存后保存，重启项目再加载，库存保持。
- 消耗时间点后保存，加载后时间保持。
- 解锁配方后保存，加载后配方仍解锁。
- NPC 好感变化后保存，加载后好感保持。
- 没有存档文件时加载返回 `false`，不崩溃。

---

## 5. 阶段性里程碑

### Milestone 1: 白天出门循环

包含任务：

- Task 1: 稳定菜单和玩家输入基础。
- Task 2: 实现 TimeSystem。
- Task 3: 实现 OutsideMenu。
- Task 4: 实现 ActivitySystem。

完成后玩家能：

- 白天从大门出门。
- 选择战斗或收集素材。
- 每次行动消耗 1 个时间点。
- 3 次行动后进入夜晚。

### Milestone 2: 酿造材料和自定义酿造

包含任务：

- Task 5: 扩展材料数据库。
- Task 6: 升级库存 metadata。
- Task 7: 实现 BrewingSystem。
- Task 8: 实现酿造 UI。

完成后玩家能：

- 收集水、作物、风味材料。
- 使用材料自定义酿造。
- 等待到完成日期后开箱得到一瓶未命名酒。
- 酒拥有五维评分和隐藏相性数据。

### Milestone 3: 配方和长期酿造目标

包含任务：

- Task 9: 实现 RecipeBook。

完成后玩家能：

- 解锁配方。
- 按配方酿造。
- 将高质量自酿酒记录为配方。

### Milestone 4: 夜晚 NPC 就餐

包含任务：

- Task 10: 实现夜晚入口和跳过夜晚菜单。
- Task 11: 实现 NPC 静态数据和夜晚来访。
- Task 12: 实现 NPC 就餐交互菜单。
- Task 13: 实现 AffinitySystem。

完成后玩家能：

- 夜晚接待 NPC。
- 满足 NPC 的食物和酒水需求。
- 用替代食物/酒水获得基于相性的反馈。
- 根据好感度获得不同闲聊反馈。

### Milestone 5: 可玩性闭环

包含任务：

- Task 14: 增加 HUD/反馈文本。
- Task 15: 实现存档读档第一版。

完成后玩家能：

- 看懂时间、奖励、反馈和酿造结果。
- 保存并恢复长期进度。

---

## 6. 测试策略

### 6.1 单系统测试

每个系统脚本都应有对应测试：

- `test_time_system.gd`
- `test_activity_system.gd`
- `test_material_database.gd`
- `test_material_inventory_metadata.gd`
- `test_brewing_system.gd`
- `test_recipe_book.gd`
- `test_npc_system.gd`
- `test_affinity_system.gd`
- `test_save_system.gd`

测试重点不是 UI，而是规则：

- 时间能否正确切换。
- 活动是否正确消耗时间。
- 材料分类是否正确。
- 库存是否正确消耗和添加 metadata 物品。
- 酿造是否拒绝非法输入。
- 相性是否对不同 NPC 给出不同结果。

### 6.2 手动验收路径

每个里程碑完成后，至少手动跑一遍：

1. 启动主场景。
2. 打开背包确认基础库存显示。
3. 靠近大门按 `E`。
4. 选择收集素材。
5. 检查时间点减少和背包材料增加。
6. 重复行动直到夜晚。
7. 夜晚打开夜晚菜单。
8. 跳过夜晚后进入下一天。
9. 自定义酿造一批酒。
10. 到达完成日期后开箱。
11. 夜晚向 NPC 提供酒水并查看反馈。

---

## 7. 第一阶段建议提交拆分

为了避免一次改动太大，建议第一阶段按下面提交：

1. `feat: lock player input while interaction menus are open`
2. `feat: add day and night time system`
3. `feat: add outside activity menu`
4. `feat: add battle and gathering activity rewards`
5. `test: cover time and outside activity rules`

每个提交都应该能独立运行主场景，不能留下半接入的菜单 id 或缺失 autoload。

---

## 8. 当前范围外的内容

这些内容先不做，避免第一版系统过大：

- 真正的战斗场景。
- NPC 行走入座动画。
- 酒水命名 UI。
- 复杂菜谱系统。
- 商店购买配方。
- 多语言系统。
- 自动存档策略。
- 成就系统。

这些都可以在上述核心循环稳定后继续扩展。
