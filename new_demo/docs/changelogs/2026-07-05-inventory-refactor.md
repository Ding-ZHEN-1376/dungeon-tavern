# 2026-07-05 Inventory Refactor Changelog

## 本次更新

- 将原本集中在 `MaterialInventory` 中的背包、仓库和物品转移职责拆开。
- 新增通用库存组件 `InventoryContainer`，可挂载到玩家、仓库、NPC 或其他拥有物品栏的节点上。
- 新增通用转移逻辑 `InventoryTransfer`，支持任意两个库存容器之间进行格子移动、同类堆叠和不同物品交换。
- 背包 UI 和仓库菜单改为直接绑定库存容器节点，不再通过 `"backpack"` / `"warehouse"` 字符串访问旧双容器数据。
- 活动奖励现在优先发放到 `player_inventory` 分组里的玩家库存容器。
- `MaterialInventory` 暂时保留为兼容层，旧 API 会尽量转发到新的库存容器，降低旧模块被突然破坏的风险。
- 仓库菜单现在支持从打开菜单的交互源节点下自动查找 `InventoryContainer`，即使没有手动设置 group，也能找到挂在 `Warehouse` 下的库存。
- `InventoryContainer` 会根据父节点名称自动加入常见分组：
  - 父节点名包含 `player` 时加入 `player_inventory`
  - 父节点名包含 `warehouse` 时加入 `warehouse_inventory`
- 新增测试覆盖库存容器、物品转移、活动奖励进入玩家背包，以及仓库菜单从交互源解析库存容器。

## 当前约定

- 玩家背包默认分组名：`player_inventory`
- 仓库库存默认分组名：`warehouse_inventory`
- 普通物品格子结构继续使用：

```gdscript
{
	"id": "",
	"count": 0
}
```

- 当前配置方式仍偏硬编码，脚本中还存在类似：

```gdscript
get_tree().get_first_node_in_group("player_inventory")
get_tree().get_first_node_in_group("warehouse_inventory")
```

这些 group 名目前相当于库存系统的临时公共接口。

## 下一步目标：库存引用配置化

目标：减少硬编码 group 字符串，让玩家背包、仓库、NPC 背包、商人库存、宝箱库存等都能用同一套方式注册和查找。

推荐分三步推进。

### Step 1：集中常量和查询入口

- 新增 `InventoryRegistry` 或 `InventoryResolver` Autoload。
- 把 `player_inventory`、`warehouse_inventory` 等字符串集中到一个地方。
- UI、活动系统、菜单不再直接调用 `get_first_node_in_group(...)`，统一改为：

```gdscript
InventoryRegistry.get_inventory("player")
InventoryRegistry.get_inventory("warehouse")
```

- `InventoryContainer` 在 `_ready()` 时向 registry 注册自己：

```gdscript
InventoryRegistry.register_inventory(container_id, self)
```

- 好处：先不引入复杂配置，但立刻消除多文件硬编码。

### Step 2：把容器 ID 暴露给编辑器

- 继续使用 `InventoryContainer.container_id`，例如：
  - `player`
  - `warehouse`
  - `npc_blacksmith`
  - `merchant_general`
  - `chest_tavern_backroom`
- `InventoryContainer` 根据 `container_id` 自动注册，而不是依赖父节点名推断。
- 编辑器里添加一个库存节点时，只需要设置：
  - `Container ID`
  - `Slot Count`
  - `Max Stack`
- 好处：新增 NPC 背包或宝箱时，不需要改 UI 查找逻辑。

### Step 3：引入数据配置表

Godot 可以使用几种原生友好的配置方式：

- `Resource` / `.tres`：最推荐。可以自定义 `InventoryDefinition` Resource，在 Inspector 里编辑，类型安全，适合 Godot 项目长期维护。
- `JSON`：适合外部工具生成或策划批量编辑，但 Godot Inspector 中不如 Resource 直观。
- `CSV`：Godot 可读取文本 CSV，但需要自己解析，适合非常表格化的数据，不适合复杂字段。

推荐路线：

- v1 使用自定义 `Resource`：

```gdscript
class_name InventoryDefinition
extends Resource

@export var inventory_id: String
@export var display_name: String
@export var slot_count: int = 15
@export var max_stack: int = 64
@export var group_name: String = ""
```

- `InventoryContainer` 暴露：

```gdscript
@export var definition: InventoryDefinition
```

- 如果设置了 `definition`，容器从 definition 读取 ID、格子数量和堆叠上限。
- `InventoryRegistry` 使用 `definition.inventory_id` 注册容器。

### 推荐优先级

1. 先做 `InventoryRegistry`，把查找入口统一。
2. 再让 `InventoryContainer.container_id` 成为主要注册 ID。
3. 最后引入 `InventoryDefinition.tres`，把库存配置变成可在编辑器中创建和复用的资源。

这样可以保持每一步都能运行，不需要一次性重写 UI、活动系统和交互菜单。
