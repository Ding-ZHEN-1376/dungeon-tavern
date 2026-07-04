# Material Inventory Storage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在当前 Godot 项目中实现第一版材料系统：按 B 键打开或关闭右侧 3x5 背包，显示材料图标和数量，并允许在酿酒桶旁的仓库与背包之间拖动物品。

**Architecture:** 使用一个全局材料库存脚本保存“背包”和“仓库”的格子数据，UI 只负责显示和拖拽操作。背包 UI 作为常驻 CanvasLayer 控件接入主场景，仓库作为酿酒桶旁边的 Area2D 交互对象，通过现有 `interactable.gd` 和 `MenuManager` 打开仓库菜单。

**Tech Stack:** Godot 4.7、GDScript、Control 拖拽 API、Area2D 交互、CanvasLayer UI。

---

## 1. 本阶段范围

本阶段只做“材料、背包、仓库”的基础能力，不做时间系统和真正酿酒配方消耗。

需要完成：

- 按 `B` 键打开右侧背包。
- 再次按 `B` 键关闭背包。
- 背包固定为 `3 x 5`，一共 `15` 个格子。
- 背包格子显示当前拥有的材料、图标和数量。
- 单个格子的最多堆叠数量是 `64`。
- 在酿酒桶旁边放置一个“仓库”交互对象。
- 靠近仓库按 `E` 后打开仓库界面。
- 背包材料可以拖动到仓库里。
- 仓库也遵守单格最多 `64` 的堆叠规则。

暂不做：

- 右键拆分一半材料。
- Shift 快速转移。
- 材料拾取掉落。
- 存档读档。
- 配方、酿酒时间、酿酒结果。

这些功能后续可以在当前数据结构上继续扩展。

---

## 2. 当前项目接入点

当前项目已经有这些基础：

- 主场景：`D:\godot_study\new_demo\scenes\main.tscn`
- 玩家移动：`D:\godot_study\new_demo\scripts\player_main.gd`
- 交互对象脚本：`D:\godot_study\new_demo\scripts\interactable.gd`
- 菜单管理器：`D:\godot_study\new_demo\scripts\ui\MenuManager.gd`
- 已有菜单示例：`D:\godot_study\new_demo\scenes\ui\menus\brewing\BrewingMenu.tscn`

建议继续沿用当前交互结构：

- `interactable.gd` 负责靠近后显示提示，按 `E` 后打开菜单。
- `MenuManager.gd` 负责统一打开和关闭交互菜单。
- 新增仓库菜单时，只需要在 `menu_registry` 中加入 `"warehouse"`。

---

## 3. 素材方案

素材来源：

`D:\godot_study\素材库\Ninja Adventure - Asset Pack\Ninja Adventure - Asset Pack\Items\Food`

该目录中实际存在的糖素材文件名是：

- `Honey.png`

建议在项目内新建材料素材目录：

`D:\godot_study\new_demo\assets\materials`

复制并统一命名：

- `Honey.png` -> `D:\godot_study\new_demo\assets\materials\honey.png`
- 临时蘑菇图标：任选一个 Food 图片，例如 `SeedBig1.png` -> `D:\godot_study\new_demo\assets\materials\mushroom_temp.png`
- 临时酒图标：任选一个 Food 图片，例如 `FortuneCookie.png` -> `D:\godot_study\new_demo\assets\materials\wine_temp.png`

这样做的原因：

- 以后脚本只引用 `res://assets/materials/...`。
- 不直接依赖素材库路径，避免别人下载项目后找不到本地素材库。
- GitHub 上也能带着项目自己的材料图标走。

---

## 4. 数据设计

### 4.1 材料定义

新增材料定义文件：

`D:\godot_study\new_demo\scripts\systems\material_database.gd`

职责：

- 记录材料 id。
- 记录中文显示名。
- 记录图标路径。

第一版材料建议：

```gdscript
extends RefCounted
class_name MaterialDatabase

const MATERIALS := {
	"low_grade_sugar": {
		"display_name": "低级糖",
		"icon": "res://assets/materials/honey.png"
	},
	"mushroom": {
		"display_name": "蘑菇",
		"icon": "res://assets/materials/mushroom_temp.png"
	},
	"wine": {
		"display_name": "酒",
		"icon": "res://assets/materials/wine_temp.png"
	}
}

static func get_display_name(material_id: String) -> String:
	if not MATERIALS.has(material_id):
		return material_id
	return MATERIALS[material_id]["display_name"]

static func get_icon_path(material_id: String) -> String:
	if not MATERIALS.has(material_id):
		return ""
	return MATERIALS[material_id]["icon"]
```

### 4.2 格子数据

背包和仓库都使用相同的格子结构：

```gdscript
{
	"id": "low_grade_sugar",
	"count": 12
}
```

空格子使用：

```gdscript
{
	"id": "",
	"count": 0
}
```

固定规则：

- `MAX_STACK = 64`
- `BACKPACK_SLOT_COUNT = 15`
- `WAREHOUSE_SLOT_COUNT = 40`

仓库第一版按审核意见做成 `4 x 10`，一共 `40` 个格子。后续如果想让仓库更大，可以只改 `WAREHOUSE_SLOT_COUNT` 和 GridContainer 列数。

### 4.3 全局库存状态

新增自动加载脚本：

`D:\godot_study\new_demo\scripts\systems\material_inventory.gd`

建议在 `project.godot` 的 `[autoload]` 中注册为：

```ini
MaterialInventory="*res://scripts/systems/material_inventory.gd"
```

职责：

- 保存 `backpack_slots`。
- 保存 `warehouse_slots`。
- 提供添加、移除、移动、合并、交换材料的方法。
- 发出 `inventory_changed` 信号，让 UI 自动刷新。

核心接口建议：

```gdscript
extends Node

signal inventory_changed

const MAX_STACK := 64
const BACKPACK_SLOT_COUNT := 15
const WAREHOUSE_SLOT_COUNT := 40

var backpack_slots: Array[Dictionary] = []
var warehouse_slots: Array[Dictionary] = []

func _ready() -> void:
	_init_slots()
	add_item_to_container("backpack", "low_grade_sugar", 12)
	add_item_to_container("backpack", "mushroom", 5)
	add_item_to_container("backpack", "wine", 1)

func add_item_to_container(container_name: String, material_id: String, amount: int) -> int:
	# 返回没有放进去的剩余数量。
	return 0

func move_stack(from_container: String, from_index: int, to_container: String, to_index: int) -> void:
	# 支持空格移动、同类合并、不同材料交换。
	pass

func get_slots(container_name: String) -> Array[Dictionary]:
	if container_name == "warehouse":
		return warehouse_slots
	return backpack_slots
```

初始材料只是为了测试 UI：

- 低级糖 x12
- 蘑菇 x5
- 酒 x1

如果你希望游戏一开始背包为空，也可以改成空背包，然后后续通过采集或奖励加入材料。

---

## 5. UI 设计

### 5.1 背包面板

新增场景：

`D:\godot_study\new_demo\scenes\ui\inventory\InventoryPanel.tscn`

新增脚本：

`D:\godot_study\new_demo\scripts\ui\inventory\inventory_panel.gd`

节点建议：

```text
InventoryPanel (PanelContainer)
└── MarginContainer
    └── VBoxContainer
        ├── TitleLabel
        └── GridContainer
            ├── InventorySlot
            ├── InventorySlot
            └── ... 共 15 个
```

布局建议：

- 锚点贴右侧。
- 宽度约 `220` 到 `260`。
- 高度根据 15 个格子自动撑开。
- 初始 `visible = false`。
- `GridContainer.columns = 3`。

按键：

- 在 `project.godot` 中新增输入映射 `inventory`。
- 绑定键盘 `B`。
- 在主场景或背包 UI 脚本中监听 `Input.is_action_just_pressed("inventory")`。

### 5.2 背包格子

新增场景：

`D:\godot_study\new_demo\scenes\ui\inventory\InventorySlot.tscn`

新增脚本：

`D:\godot_study\new_demo\scripts\ui\inventory\inventory_slot.gd`

节点建议：

```text
InventorySlot (PanelContainer)
└── Control
    ├── IconTexture (TextureRect)
    └── CountLabel (Label)
```

显示规则：

- 空格子隐藏图标和数量。
- 有材料时显示图标。
- 数量为 `1` 时可以显示 `1`，也可以隐藏数量。第一版建议显示，方便学习和验证。
- 鼠标悬停可显示材料中文名。

---

## 6. 仓库设计

### 6.1 世界里的仓库对象

在主场景中，在酿酒桶旁边新增：

```text
Warehouse (Area2D)
├── Sprite2D
├── CollisionShape2D
└── PromptLabel
```

挂载：

`D:\godot_study\new_demo\scripts\interactable.gd`

导出变量建议：

```text
prompt_text = "按E：打开仓库"
action_text = "你打开了仓库"
opens_menu = true
menu_id = "warehouse"
```

### 6.2 仓库菜单

新增场景：

`D:\godot_study\new_demo\scenes\ui\menus\storage\WarehouseMenu.tscn`

新增脚本：

`D:\godot_study\new_demo\scripts\ui\menus\storage\warehouse_menu.gd`

菜单内容建议：

```text
WarehouseMenu (PanelContainer)
└── MarginContainer
    └── VBoxContainer
        ├── TitleLabel
        ├── GridContainer
        │   └── WarehouseSlot x 15
        └── CloseButton
```

仓库菜单打开时：

- 屏幕中间或偏右显示仓库格子。
- 背包面板也保持可见，方便从背包拖到仓库。
- 关闭仓库菜单时，不强制关闭背包。这样玩家可以继续查看背包。

在 `MenuManager.gd` 中增加：

```gdscript
var menu_registry := {
	"brewing_barrel": preload("res://scenes/ui/menus/brewing/BrewingMenu.tscn"),
	"warehouse": preload("res://scenes/ui/menus/storage/WarehouseMenu.tscn")
}
```

---

## 7. 拖拽规则

Godot 的 Control 节点支持三个拖拽方法：

```gdscript
func _get_drag_data(_at_position: Vector2) -> Variant:
	pass

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	pass
```

拖拽数据建议：

```gdscript
{
	"container": "backpack",
	"slot_index": 0,
	"material_id": "low_grade_sugar",
	"count": 12
}
```

第一版规则：

- 从空格子开始拖拽：不发生任何事。
- 拖到空格子：整组移动过去。
- 拖到同类材料格子：合并，最多合并到 `64`。
- 合并后还有剩余：剩余数量保留在原格子。
- 拖到不同材料格子：两个格子交换。
- 拖回原格子：不变化。

这套规则先满足“可以拖动到仓库、堆叠最多 64”。拆分堆叠可以后续再做。

---

## 8. 文件清单

### 新增文件

- `D:\godot_study\new_demo\assets\materials\honey.png`
- `D:\godot_study\new_demo\assets\materials\mushroom_temp.png`
- `D:\godot_study\new_demo\assets\materials\wine_temp.png`
- `D:\godot_study\new_demo\scripts\systems\material_database.gd`
- `D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
- `D:\godot_study\new_demo\scripts\ui\inventory\inventory_panel.gd`
- `D:\godot_study\new_demo\scripts\ui\inventory\inventory_slot.gd`
- `D:\godot_study\new_demo\scripts\ui\menus\storage\warehouse_menu.gd`
- `D:\godot_study\new_demo\scenes\ui\inventory\InventoryPanel.tscn`
- `D:\godot_study\new_demo\scenes\ui\inventory\InventorySlot.tscn`
- `D:\godot_study\new_demo\scenes\ui\menus\storage\WarehouseMenu.tscn`

### 修改文件

- `D:\godot_study\new_demo\project.godot`
  - 新增 `MaterialInventory` 自动加载。
  - 新增 `inventory` 输入映射，绑定 `B`。
- `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`
  - 注册 `"warehouse"` 菜单。
- `D:\godot_study\new_demo\scenes\main.tscn`
  - 添加背包 UI。
  - 在酿酒桶旁边添加 Warehouse 交互对象。

---

## 9. 分步实施任务

### Task 1: 准备材料图标

**Files:**

- Create: `D:\godot_study\new_demo\assets\materials\honey.png`
- Create: `D:\godot_study\new_demo\assets\materials\mushroom_temp.png`
- Create: `D:\godot_study\new_demo\assets\materials\wine_temp.png`

- [ ] **Step 1: 新建材料素材文件夹**

创建：

```text
D:\godot_study\new_demo\assets\materials
```

- [ ] **Step 2: 复制糖图标**

从素材库复制：

```text
D:\godot_study\素材库\Ninja Adventure - Asset Pack\Ninja Adventure - Asset Pack\Items\Food\Honey.png
```

复制到：

```text
D:\godot_study\new_demo\assets\materials\honey.png
```

- [ ] **Step 3: 复制两个临时图标**

建议：

```text
SeedBig1.png -> mushroom_temp.png
FortuneCookie.png -> wine_temp.png
```

- [ ] **Step 4: 打开 Godot 等待导入**

Godot 会自动生成 `.import` 文件。确认 FileSystem 面板中能看到三个图标。

### Task 2: 新增材料数据库

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\material_database.gd`

- [ ] **Step 1: 创建脚本目录**

创建：

```text
D:\godot_study\new_demo\scripts\systems
```

- [ ] **Step 2: 写入材料定义**

使用第 4.1 节中的 `MaterialDatabase` 代码。

- [ ] **Step 3: 在 Godot 中打开脚本检查报错**

预期：

```text
没有红色脚本错误。
```

### Task 3: 新增全局库存状态

**Files:**

- Create: `D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
- Modify: `D:\godot_study\new_demo\project.godot`

- [ ] **Step 1: 创建 `material_inventory.gd`**

脚本包含：

- `MAX_STACK`
- `backpack_slots`
- `warehouse_slots`
- `add_item_to_container`
- `move_stack`
- `get_slots`
- `inventory_changed` 信号

- [ ] **Step 2: 注册 Autoload**

在 Godot 中操作：

1. 打开 `Project`。
2. 打开 `Project Settings`。
3. 进入 `Globals` 或 `Autoload`。
4. Path 选择 `res://scripts/systems/material_inventory.gd`。
5. Node Name 填 `MaterialInventory`。
6. 点击 Add。

完成后 `project.godot` 中应出现：

```ini
[autoload]

MenuManager="*res://scenes/ui/MenuManager.tscn"
MaterialInventory="*res://scripts/systems/material_inventory.gd"
```

### Task 4: 新增背包 UI

**Files:**

- Create: `D:\godot_study\new_demo\scenes\ui\inventory\InventorySlot.tscn`
- Create: `D:\godot_study\new_demo\scenes\ui\inventory\InventoryPanel.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\inventory\inventory_slot.gd`
- Create: `D:\godot_study\new_demo\scripts\ui\inventory\inventory_panel.gd`
- Modify: `D:\godot_study\new_demo\project.godot`
- Modify: `D:\godot_study\new_demo\scenes\main.tscn`

- [ ] **Step 1: 新增输入映射**

Godot 操作：

1. 打开 `Project Settings`。
2. 进入 `Input Map`。
3. 新增 action：`inventory`。
4. 给 `inventory` 添加按键 `B`。

- [ ] **Step 2: 创建单个格子场景**

`InventorySlot` 负责显示一个格子的图标和数量，并处理拖拽。

- [ ] **Step 3: 创建背包面板场景**

`InventoryPanel` 负责创建 15 个 `InventorySlot`，排列为 3 列 5 行。

- [ ] **Step 4: 接入主场景**

把 `InventoryPanel.tscn` 实例化到 `main.tscn` 中。

预期表现：

- 运行游戏时背包默认隐藏。
- 按 `B` 后右侧显示 15 个格子。
- 再按 `B` 后隐藏。
- 初始测试材料显示在背包中。

### Task 5: 新增仓库交互对象

**Files:**

- Modify: `D:\godot_study\new_demo\scenes\main.tscn`

- [ ] **Step 1: 在酿酒桶旁边创建 `Warehouse`**

节点结构：

```text
Warehouse (Area2D)
├── Sprite2D
├── CollisionShape2D
└── PromptLabel
```

- [ ] **Step 2: 挂载现有交互脚本**

脚本：

```text
res://scripts/interactable.gd
```

导出变量：

```text
prompt_text = "按E：打开仓库"
action_text = "你打开了仓库"
opens_menu = true
menu_id = "warehouse"
```

- [ ] **Step 3: 设置碰撞范围**

`CollisionShape2D` 可以先用 `RectangleShape2D`。范围不需要太大，玩家贴近仓库时能触发即可。

### Task 6: 新增仓库菜单

**Files:**

- Create: `D:\godot_study\new_demo\scenes\ui\menus\storage\WarehouseMenu.tscn`
- Create: `D:\godot_study\new_demo\scripts\ui\menus\storage\warehouse_menu.gd`
- Modify: `D:\godot_study\new_demo\scripts\ui\MenuManager.gd`

- [ ] **Step 1: 创建仓库菜单场景**

仓库菜单显示 40 个仓库格子，排列为 4 列 10 行。

- [ ] **Step 2: 复用 `InventorySlot`**

同一个格子场景可以同时服务背包和仓库，只需要传入：

```gdscript
container_name = "warehouse"
slot_index = 0
```

- [ ] **Step 3: 注册仓库菜单**

修改 `MenuManager.gd`：

```gdscript
var menu_registry := {
	"brewing_barrel": preload("res://scenes/ui/menus/brewing/BrewingMenu.tscn"),
	"warehouse": preload("res://scenes/ui/menus/storage/WarehouseMenu.tscn")
}
```

### Task 7: 实现背包和仓库之间拖拽

**Files:**

- Modify: `D:\godot_study\new_demo\scripts\systems\material_inventory.gd`
- Modify: `D:\godot_study\new_demo\scripts\ui\inventory\inventory_slot.gd`

- [ ] **Step 1: 在格子中生成拖拽数据**

拖拽数据必须包含：

```gdscript
{
	"container": container_name,
	"slot_index": slot_index
}
```

- [ ] **Step 2: 在目标格子中接收拖拽**

调用：

```gdscript
MaterialInventory.move_stack(
	data["container"],
	data["slot_index"],
	container_name,
	slot_index
)
```

- [ ] **Step 3: 库存状态处理移动规则**

`move_stack` 中实现：

- 空格移动。
- 同类合并，最多 `64`。
- 不同材料交换。
- 操作完成后发出 `inventory_changed`。

### Task 8: 手动验证

**Files:**

- Test manually in Godot editor.

- [ ] **Step 1: 验证 B 键**

运行主场景：

```text
按 B，右侧背包出现。
再按 B，右侧背包隐藏。
```

- [ ] **Step 2: 验证背包显示**

预期：

```text
背包是 3 列 5 行。
低级糖、蘑菇、酒显示图标和数量。
```

- [ ] **Step 3: 验证仓库交互**

预期：

```text
玩家靠近仓库，显示“按E：打开仓库”。
按 E，仓库菜单打开。
```

- [ ] **Step 4: 验证拖拽**

预期：

```text
从背包拖低级糖到仓库空格，糖移动到仓库。
把糖拖到已有糖的仓库格子，数量合并。
合并后单格数量不会超过 64。
拖到不同材料格子时，两个格子交换。
```

- [ ] **Step 5: 验证关闭后数据保留**

预期：

```text
关闭仓库，再打开仓库，刚才移动过的材料还在仓库里。
关闭背包，再打开背包，背包数量保持正确。
```

---

## 10. 需要你审核的决定

我建议默认采用下面这些决定：

1. 仓库大小第一版做 `4 x 10`。
2. 拖拽时移动整组材料，不做拆分。
3. 糖使用 `Honey.png`，复制到项目内后改名为 `honey.png`。
4. 蘑菇和酒先用临时 Food 图标代替。
5. 背包初始放入少量测试材料，方便确认 UI 和拖拽功能。
6. 材料状态暂时只在本次运行中保存，不做存档。

如果这些决定可以接受，下一步就可以开始按这个计划实现代码和场景。
