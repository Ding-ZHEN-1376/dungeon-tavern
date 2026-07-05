# Task 5 + Task 6 Material Data Upgrade Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 扩展材料数据库，并把库存格子升级为支持 `metadata`，为后续自定义酿造、酒水评分、NPC 需求和酒水相性系统打基础。

**Architecture:** Task 5 只处理静态材料定义和查询接口；Task 6 只处理库存格子结构、堆叠、移动、统计和消耗。UI 继续通过 `InventorySlot` 读取库存，不直接理解酿造规则。

**Tech Stack:** Godot 4.7, GDScript, 当前 Autoload `MaterialInventory`, 当前 `MaterialDatabase` 静态查询脚本, Godot MCP 测试场景验证。

---

## 当前项目状态

当前项目已经有最小材料系统：

- `D:\godot_study\new_demo\scripts\systems\material_database.gd`
  - 目前只有 `low_grade_sugar`、`mushroom`、`wine`。
  - 每个材料只有 `display_name` 和 `icon`。
  - 只有 `get_display_name()`、`get_icon_path()` 两个查询函数。
- `D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
  - 格子结构是 `{ "id": "", "count": 0 }`。
  - 支持背包、仓库、添加、移动、交换、同类堆叠。
  - 还不能表达两瓶属性不同的自酿酒。
- `D:\godot_study\new_demo\scripts\ui\inventory\inventory_slot.gd`
  - UI 当前从格子的 `"id"` 字段读取材料 id。
  - 需要在 Task 6 后改为优先读取 `"item_id"`，兼容旧 `"id"`。
- `D:\godot_study\new_demo\scripts\systems\activity_system.gd`
  - 奖励数据已经使用 `{"item_id": "...", "count": ...}`。
  - 这和 Task 6 的新字段方向一致，不需要大改。

---

## 设计原则

1. 先做数据兼容，再做玩法扩展。
   - 旧 UI、旧测试、现有活动奖励不能因为字段改名立刻坏掉。
   - 过渡期允许读取旧字段 `"id"`，但新增或修改库存时统一写入 `"item_id"`。

2. `MaterialDatabase` 不保存玩家状态。
   - 它只回答“这个 id 是什么材料、属于什么分类、有什么酿造属性”。
   - 背包数量、酒的评分、是否命名、原始配方记录都属于 `MaterialInventory` 或后续 `BrewingSystem`。

3. `metadata` 是物品实例数据。
   - 普通材料：`metadata = {}`。
   - 自酿酒：`metadata` 保存五维评分、隐藏相性分、材料来源、手法、时长、是否命名。
   - 两瓶 `custom_wine` 即使 `item_id` 相同，只要 `metadata` 不同，就不能合并。

4. Task 5/6 不新增 UI 菜单。
   - 本阶段只让现有背包/仓库能显示新材料和移动 metadata 物品。
   - 不需要从“素材库”里新增 UI 素材。
   - 新材料图标第一版复用 `D:\godot_study\new_demo\assets\materials` 下现有临时图标。

---

## Task 5: 扩展 MaterialDatabase

### 实现目标

让材料系统可以区分：

- 风味材料：用于改变酒的香气、酒体、甜度、纯净度、余味。
- 基础水材料：酿酒必需材料之一。
- 基础作物材料：酿酒必需材料之一。
- 食物：供后续 NPC 就餐需求使用。
- 酒水：供后续 NPC 饮品需求和酒水相性使用。

Task 5 完成后，后续系统应该可以直接问：

- 某个材料是不是水？
- 某个材料是不是作物？
- 背包里哪些物品是风味材料？
- 某个材料是否可用于酿造？
- 某个可酿造材料的五维基础属性是什么？

### 修改文件

- 修改：`D:\godot_study\new_demo\scripts\systems\material_database.gd`
- 新增测试：`D:\godot_study\new_demo\tests\test_material_database.gd`
- 新增测试场景：`D:\godot_study\new_demo\tests\test_material_database.tscn`

### 数据结构

建议在 `MaterialDatabase` 中定义分类常量：

```gdscript
const CATEGORY_FLAVOR := "flavor"
const CATEGORY_WATER := "water"
const CATEGORY_CROP := "crop"
const CATEGORY_FOOD := "food"
const CATEGORY_DRINK := "drink"
```

每个材料统一使用这个结构：

```gdscript
"material_id": {
	"display_name": "显示名",
	"icon": "res://assets/materials/example.png",
	"category": CATEGORY_FLAVOR,
	"brew_traits": {
		"aroma": 0,
		"body": 0,
		"sweetness": 0,
		"purity": 0,
		"finish": 0
	}
}
```

`brew_traits` 只要求可酿造材料填写。食物和普通酒水模板可以没有 `brew_traits`。

### 第一版材料清单

第一版建议先定义这些物品，保证后续酿造系统和 NPC 系统有最小可用数据：

| id | 显示名 | category | icon | brew_traits |
|---|---|---|---|---|
| `low_grade_sugar` | 低级糖 | `flavor` | `honey.png` | 有 |
| `mushroom` | 蘑菇 | `flavor` | `mushroom_temp.png` | 有 |
| `well_water` | 井水 | `water` | 暂用 `wine_temp.png` | 有 |
| `dirty_water` | 污水 | `water` | 暂用 `wine_temp.png` | 有 |
| `rye` | 黑麦 | `crop` | 暂用 `honey.png` | 有 |
| `wheat` | 小麦 | `crop` | 暂用 `honey.png` | 有 |
| `simple_meal` | 简餐 | `food` | 暂用 `honey.png` | 无 |
| `wine` | 普通酒 | `drink` | `wine_temp.png` | 无 |
| `custom_wine` | 自酿酒 | `drink` | `wine_temp.png` | 无，评分放在库存 metadata |

### 第一版五维字段

五维字段固定为：

- `aroma`：香气
- `body`：酒体
- `sweetness`：甜度
- `purity`：纯净度
- `finish`：余味

建议第一版用小范围整数，后续 `BrewingSystem` 再统一 clamp 到 0 到 10。

```gdscript
const BREW_TRAIT_KEYS := ["aroma", "body", "sweetness", "purity", "finish"]
```

建议初始值：

```gdscript
"low_grade_sugar": {
	"aroma": 0,
	"body": 0,
	"sweetness": 3,
	"purity": -1,
	"finish": 0
}

"mushroom": {
	"aroma": 2,
	"body": 1,
	"sweetness": -1,
	"purity": -1,
	"finish": 2
}

"well_water": {
	"aroma": 0,
	"body": 0,
	"sweetness": 0,
	"purity": 2,
	"finish": 0
}

"dirty_water": {
	"aroma": -1,
	"body": 1,
	"sweetness": 0,
	"purity": -3,
	"finish": -1
}

"rye": {
	"aroma": 1,
	"body": 2,
	"sweetness": 0,
	"purity": 0,
	"finish": 1
}

"wheat": {
	"aroma": 1,
	"body": 1,
	"sweetness": 1,
	"purity": 0,
	"finish": 0
}
```

### 需要新增的查询接口

```gdscript
static func has_material(material_id: String) -> bool

static func get_display_name(material_id: String) -> String

static func get_icon_path(material_id: String) -> String

static func get_category(material_id: String) -> String

static func is_category(material_id: String, category: String) -> bool

static func is_brewable(material_id: String) -> bool

static func get_brew_traits(material_id: String) -> Dictionary

static func get_material_ids_by_category(category: String) -> Array

static func get_brew_trait_keys() -> Array
```

### 兼容要求

- `get_display_name("unknown_id")` 继续返回 `"unknown_id"`，避免 UI 崩溃。
- `get_icon_path("unknown_id")` 继续返回 `""`。
- `get_category("unknown_id")` 返回 `""`。
- `get_brew_traits("simple_meal")` 返回 `{}`。
- `get_brew_traits()` 返回副本，不返回原始字典引用，避免调用方意外修改常量数据。

### 测试目标

新增 `test_material_database.gd`，至少覆盖：

- `well_water` 的分类是 `water`。
- `rye` 的分类是 `crop`。
- `mushroom` 的分类是 `flavor`。
- `simple_meal` 的分类是 `food`。
- `custom_wine` 的分类是 `drink`。
- 未知 id 的分类是空字符串。
- 可酿造材料的 `brew_traits` 包含五个字段。
- `simple_meal` 不是可酿造材料。
- `get_material_ids_by_category(CATEGORY_WATER)` 包含 `well_water` 和 `dirty_water`。

### 用户需要做什么

Task 5 不需要你手动操作 Godot 编辑器。你只需要确认两件事：

- 第一版材料名是否接受：井水、污水、黑麦、小麦、简餐、自酿酒。
- 临时图标是否接受复用当前 `assets/materials` 的图标；如果你希望更换图标，可以从 `D:\godot_study\素材库` 里指定图片文件名。

---

## Task 6: 升级 MaterialInventory metadata

### 实现目标

让库存可以同时表达两类物品：

1. 普通材料。
   - 例如 `mushroom x5`。
   - `metadata = {}`。
   - 相同 `item_id` 可以堆叠到 `MAX_STACK`。

2. 带实例数据的物品。
   - 例如一瓶自酿酒。
   - `item_id = "custom_wine"`。
   - `metadata` 记录这瓶酒的评分、相性分、原料和酿造信息。
   - `metadata` 不同的酒不能合并成一组。

### 修改文件

- 修改：`D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
- 修改：`D:\godot_study\new_demo\scripts\ui\inventory\inventory_slot.gd`
- 新增测试：`D:\godot_study\new_demo\tests\test_material_inventory_metadata.gd`
- 新增测试场景：`D:\godot_study\new_demo\tests\test_material_inventory_metadata.tscn`
- 保留并更新：`D:\godot_study\new_demo\tests\test_material_inventory.gd`

### 新格子结构

库存格子统一改成：

```gdscript
{
	"item_id": "",
	"count": 0,
	"metadata": {}
}
```

旧字段兼容策略：

- 读取格子时，使用 helper 获取 id：

```gdscript
func _get_slot_item_id(slot: Dictionary) -> String:
	if slot.has("item_id"):
		return String(slot.get("item_id", ""))
	return String(slot.get("id", ""))
```

- 新建、添加、移动、交换、清空时，只写 `"item_id"`、`"count"`、`"metadata"`。
- 不再新写 `"id"`。

### metadata 推荐结构

后续 `BrewingSystem` 创建自酿酒时，建议写入：

```gdscript
{
	"display_name": "",
	"named": false,
	"scores": {
		"aroma": 6,
		"body": 5,
		"sweetness": 2,
		"purity": 7,
		"finish": 4
	},
	"affinity_score": 24,
	"source_batch": {
		"water": {"item_id": "well_water", "count": 1},
		"crop": {"item_id": "rye", "count": 2},
		"flavors": [{"item_id": "mushroom", "count": 1}],
		"method": "yeast",
		"duration_days": 2
	}
}
```

Task 6 不负责生成这些评分，只负责保存、移动、显示基础图标和防止错误堆叠。

### 需要修改的库存接口

#### `add_item_to_container`

签名改为：

```gdscript
func add_item_to_container(container_name: String, item_id: String, amount: int, metadata := {}) -> int:
```

行为：

- `item_id == ""` 或 `amount <= 0` 时直接返回原数量。
- 普通材料 `metadata = {}` 时，与同 `item_id`、空 metadata 的格子堆叠。
- metadata 非空时，只允许和完全相同 metadata 的同 `item_id` 堆叠。
- 如果选择更保守的酒水策略，`custom_wine` 且 metadata 非空时可以强制每瓶占 1 格；第一版建议先不强制，保持“metadata 完全相同才堆叠”的通用规则。
- 返回未能放入的数量。

#### `move_stack`

需要同时移动 `item_id/count/metadata`。

行为：

- 源格为空则不动。
- 目标格为空：完整移动三项数据。
- 目标格可堆叠：增加目标数量，减少源数量。
- 目标格不可堆叠：交换三项数据。
- 判断可堆叠时使用 `can_stack()`，不能只比较 id。

#### `set_slot`

签名建议改为：

```gdscript
func set_slot(container_name: String, slot_index: int, item_id: String, count: int, metadata := {}) -> void:
```

行为：

- 用于测试和调试。
- 写入新结构。
- `metadata` 必须复制一份再保存。

#### `count_item`

新增：

```gdscript
func count_item(container_name: String, item_id: String, metadata := null) -> int:
```

行为：

- `metadata == null`：统计该 `item_id` 的所有数量，不关心 metadata。
- `metadata is Dictionary`：只统计 metadata 完全相同的数量。
- 后续 NPC 判断“有没有酒水”时可先不传 metadata。
- 后续配方精确消耗材料时可传 `{}`。

#### `consume_items`

新增：

```gdscript
func consume_items(container_name: String, requirements: Array) -> bool:
```

输入例子：

```gdscript
[
	{"item_id": "well_water", "count": 1},
	{"item_id": "rye", "count": 2},
	{"item_id": "mushroom", "count": 1}
]
```

行为：

- 先检查所有需求是否足够。
- 如果任意需求不足，返回 `false`，库存完全不变。
- 如果全部足够，再逐项扣除。
- 扣到 0 的格子清空为 `{ "item_id": "", "count": 0, "metadata": {} }`。
- 第一版需求默认消耗 `metadata = {}` 的普通材料，避免酿造系统误消耗玩家已经酿好的酒。

#### `can_stack`

新增：

```gdscript
func can_stack(slot: Dictionary, item_id: String, metadata: Dictionary) -> bool:
```

行为：

- 空格不算可堆叠；空格由添加逻辑单独处理。
- 同 `item_id`。
- `slot.metadata` 与传入 `metadata` 完全相等。
- `slot.count < MAX_STACK`。

### 需要修改的 UI

`inventory_slot.gd` 当前读取：

```gdscript
var material_id := String(slot.get("id", ""))
```

Task 6 后改为：

```gdscript
var item_id := String(slot.get("item_id", slot.get("id", "")))
```

UI 第一版仍然只显示：

- 图标。
- 数量。
- tooltip 显示 `MaterialDatabase.get_display_name(item_id)`。

后续可以再把自酿酒 tooltip 扩展为显示名字、五维评分和原料，但不放在 Task 6 做。

### 需要注意的现有调用点

这些调用应保持可用：

- `MaterialInventory.add_item_to_container("backpack", "low_grade_sugar", 12)`
- `MaterialInventory.add_item_to_container("backpack", "mushroom", 5)`
- `MaterialInventory.add_item_to_container("backpack", "wine", 1)`
- `ActivitySystem._apply_rewards()` 中的奖励添加。
- 背包和仓库的拖拽移动。

因此 `add_item_to_container()` 的第 4 个参数必须有默认值 `{}`，不能要求所有旧调用都传 metadata。

### 测试目标

新增 `test_material_inventory_metadata.gd`，至少覆盖：

- 新建空格子时有 `item_id/count/metadata`。
- 添加两个 `well_water` 后能堆叠到同一格。
- 添加 `custom_wine`，metadata A 和 metadata B 不同，占两个格子。
- metadata 相同的普通特殊物品可以按规则堆叠。
- 移动 metadata 物品到仓库后，metadata 不丢失。
- 两个不同 metadata 的 `custom_wine` 互相拖拽时交换，不合并。
- `count_item("backpack", "well_water")` 返回正确数量。
- `consume_items()` 在材料足够时扣除并返回 `true`。
- `consume_items()` 在材料不足时返回 `false`，且库存数量保持不变。
- 原来的 `test_material_inventory.gd` 仍然通过，确认旧普通材料流程未破坏。

### 用户需要做什么

Task 6 不需要你手动操作 Godot 编辑器。你只需要在实现后测试两类手感：

- 打开背包和仓库，确认旧材料还能显示图标和数量。
- 拖拽普通材料时，合并和交换行为是否符合预期。

如果你希望自酿酒在背包里显示更详细的 tooltip，比如“未命名酒：香气 6 / 酒体 5”，这应该放在后续 UI 任务，不建议塞进 Task 6。

---

## 推荐执行顺序

### Task 5.1: 写 MaterialDatabase 测试

- [ ] 新建 `test_material_database.gd`。
- [ ] 验证分类常量、材料分类、未知 id、五维字段。
- [ ] 用 Godot MCP 跑测试场景，确认当前代码失败，因为接口还不存在。

### Task 5.2: 扩展 MaterialDatabase

- [ ] 添加分类常量和五维字段常量。
- [ ] 补全第一版材料清单。
- [ ] 添加 `has_material()`、`get_category()`、`is_category()`、`is_brewable()`、`get_brew_traits()`、`get_material_ids_by_category()`、`get_brew_trait_keys()`。
- [ ] 确认旧 `get_display_name()` 和 `get_icon_path()` 行为不变。
- [ ] 跑 `test_material_database.tscn`。

### Task 6.1: 写 MaterialInventory metadata 测试

- [ ] 新建 `test_material_inventory_metadata.gd`。
- [ ] 覆盖普通材料堆叠、metadata 分离、移动保留 metadata、消耗成功、消耗失败不改变库存。
- [ ] 用 Godot MCP 跑测试场景，确认当前代码失败，因为格子还没有 metadata。

### Task 6.2: 升级 MaterialInventory 格子结构

- [ ] `_make_empty_slot()` 改为返回 `item_id/count/metadata`。
- [ ] `_clear_slot()` 同步清空三项。
- [ ] 添加 `_get_slot_item_id()` 兼容旧 `"id"`。
- [ ] `set_slot()` 支持 metadata 参数。
- [ ] `add_item_to_container()` 写入新结构并按 metadata 堆叠。
- [ ] `move_stack()` 移动和交换 metadata。
- [ ] 添加 `can_stack()`、`count_item()`、`consume_items()`。

### Task 6.3: 升级 InventorySlot UI 读取字段

- [ ] `refresh()` 优先读取 `item_id`，兼容旧 `id`。
- [ ] `_get_drag_data()` 的空格判断同步改为读取 `item_id/id`。
- [ ] tooltip 继续使用 `MaterialDatabase.get_display_name()`。

### Task 6.4: 回归验证

- [ ] 跑 `test_material_database.tscn`。
- [ ] 跑 `test_material_inventory_metadata.tscn`。
- [ ] 跑旧 `test_material_inventory.gd` 对应测试场景。
- [ ] 跑 `test_activity_system.tscn`，确认活动奖励仍能加进背包。
- [ ] 用 Godot MCP 启动主项目，确认没有 parser/runtime error。
- [ ] 手动打开背包和仓库，确认普通材料显示、拖拽、合并、交换仍正常。

---

## 风险和处理方式

### 风险 1: 字段从 `id` 改成 `item_id` 破坏 UI

处理方式：

- 所有读取逻辑短期兼容 `"id"`。
- 所有写入逻辑统一写 `"item_id"`。
- `inventory_slot.gd` 先用 `slot.get("item_id", slot.get("id", ""))`。

### 风险 2: metadata 字典被引用后意外修改

处理方式：

- 写入库存时使用 `metadata.duplicate(true)`。
- 移动和交换时保留原 metadata 对象也可以，但从外部传入时必须深拷贝。

### 风险 3: 消耗失败时库存已经被部分扣除

处理方式：

- `consume_items()` 必须分两段：先检查，再扣除。
- 不允许边检查边扣。

### 风险 4: 自酿酒堆叠规则以后需要变化

处理方式：

- 第一版只做通用规则：相同 `item_id` + 完全相同 `metadata` 才可堆叠。
- 如果你希望“所有自酿酒永远一瓶一格”，后续只需要在 `can_stack()` 中为 `custom_wine` 加一条特例。

---

## 这次不做的内容

- 不实现真正酿造流程。
- 不实现酿酒 UI。
- 不实现 NPC 点餐。
- 不实现酒水相性计算。
- 不新增配方系统。
- 不新增存档。
- 不新增材料图标绘制。

这些内容都应该建立在 Task 5/6 之后。

---

## 我建议的确认点

在开始真正实现前，我建议你确认：

1. 是否接受第一版材料清单中的名字和分类。
2. 是否接受第一版临时图标复用现有 `assets/materials` 图片。
3. 是否希望 `custom_wine` 永远不堆叠。

我的默认建议是：

- 材料清单先按本文执行。
- 图标先复用现有图片。
- `custom_wine` 第一版遵守通用 metadata 规则；metadata 不同一定不堆叠，metadata 完全相同才允许堆叠。
