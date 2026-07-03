# Godot Study 阶段 2.5：三屋隔断和墙体碰撞教学方案

本文件说明如何在当前项目里先把酒馆空间隔成三个屋子，并让玩家不能穿过墙。

这一步适合放在第二阶段交互之后、第三阶段经营数据之前。原因是：你现在已经有玩家移动和基础交互，下一步把房间分区做好，可以让“酿酒桶、糖箱、蘑菇洞入口”有更清楚的位置归属。这样后续做酿酒、购买、采集时，场景会更像一个真正的酒馆。

## 1. 当前项目状态

当前主场景：

```text
D:\godot_study\新建游戏项目\scenes\main.tscn
```

当前已有主要节点：

```text
Main (Node2D)
  TileMapLayer
  Player_Main
  BrewBarrel
  SugarCrate
  MushroomCaveDoor
```

当前玩家场景：

```text
D:\godot_study\新建游戏项目\scenes\player_main.tscn
```

玩家节点结构：

```text
Player_Main (CharacterBody2D)
  Sprite2D
  CollisionShape2D
  Item
```

结论：

- 玩家已经有 `CollisionShape2D`，可以被墙挡住。
- 现在缺的是“墙体碰撞”。
- 墙体碰撞最简单做法是给主场景添加 `StaticBody2D + CollisionShape2D`。

## 2. 本阶段目标

完成后应该达到：

- 酒馆空间被隔成三个屋子。
- 玩家可以在三个屋子之间通过门口移动。
- 玩家不能穿过外墙。
- 玩家不能穿过隔断墙。
- 交互对象分别放在合适房间里。

推荐三屋布局：

```text
┌──────────────────────────────┐
│            酒馆大厅           │
│        BrewBarrel / 吧台      │
│──────────────  ──────────────│
│  仓库 / 糖箱    │   蘑菇洞入口 │
│  SugarCrate    │ MushroomDoor │
└──────────────────────────────┘
```

这个布局把房间分成：

| 房间 | 用途 |
|---|---|
| 酒馆大厅 | 玩家初始区域、酿酒桶、后续卖酒 |
| 仓库 | 糖箱、购买低级糖 |
| 蘑菇洞入口房 | 通往采集区域 |

## 3. 推荐实现方式

### 3.1 当前推荐：StaticBody2D 墙体

我建议你现在先用 `StaticBody2D` 做墙。

优点：

- 直观，新手容易理解。
- 不需要立刻研究 TileMap 碰撞层。
- 适合快速验证“玩家不能穿墙”。
- 墙体碰撞范围可以直接在编辑器里拖动调整。

缺点：

- 墙很多时，节点会变多。
- 后续正式地图更适合用 TileMap 碰撞。

但当前只有三个屋子，墙体数量不多，所以 `StaticBody2D` 是合适的。

### 3.2 后续升级：TileMap 碰撞

以后地图变复杂后，可以把墙画进 `TileMapLayer`，再给 TileSet 中的墙瓦片设置碰撞。

优点：

- 更适合大地图。
- 画地图和碰撞可以合在一起。

缺点：

- 对新手来说配置步骤更多。
- 现在容易把学习重点分散到 TileSet 编辑器。

结论：本阶段先用 `StaticBody2D`，等地图玩法稳定后再考虑 TileMap 碰撞。

## 4. 墙体节点应该怎么放

推荐在 `main.tscn` 里建立一个专门管理墙的节点：

```text
Main
  TileMapLayer
  Walls (Node2D)
    OuterWallTop (StaticBody2D)
      CollisionShape2D
    OuterWallBottom (StaticBody2D)
      CollisionShape2D
    OuterWallLeft (StaticBody2D)
      CollisionShape2D
    OuterWallRight (StaticBody2D)
      CollisionShape2D
    DividerWallHorizontalLeft (StaticBody2D)
      CollisionShape2D
    DividerWallHorizontalRight (StaticBody2D)
      CollisionShape2D
    DividerWallVertical (StaticBody2D)
      CollisionShape2D
  Player_Main
  BrewBarrel
  SugarCrate
  MushroomCaveDoor
```

为什么要加 `Walls (Node2D)`：

- 场景树更清楚。
- 以后想隐藏、移动或删除墙时更方便。
- 不会和交互对象混在一起。

## 5. 推荐三屋隔断方案

假设当前场景中心大约在玩家初始位置附近。你可以先做一个矩形酒馆，然后用两段隔断墙把下半部分分成两个小房间。

推荐结构：

```text
外墙：围住整个酒馆。
横向隔断：把上方大厅和下方两个小房间隔开，中间留门。
竖向隔断：把下方分成左侧仓库和右侧洞口房。
```

文字示意：

```text
上方：酒馆大厅
下方左：仓库
下方右：蘑菇洞入口房
```

门口建议：

- 大厅到下方区域留一个中间门口。
- 仓库和洞口房之间可以不留门，或者在竖墙上留一个门口。

第一版建议简单一点：

```text
大厅和下方区域之间留一个门。
仓库和洞口房之间不互通，需要从大厅分别进入。
```

这样动线更清楚：

```text
大厅 -> 仓库
大厅 -> 蘑菇洞入口房
```

## 6. 手动操作步骤

### 6.1 新建 Walls 管理节点

1. 打开 `main.tscn`。
2. 选中根节点 `Main`。
3. 添加子节点：

```text
Node2D
```

4. 命名为：

```text
Walls
```

建议把 `Walls` 放在 `TileMapLayer` 后面、`Player_Main` 前面。这样场景树更好读。

### 6.2 添加第一面墙

1. 选中 `Walls`。
2. 添加子节点：

```text
StaticBody2D
```

3. 命名为：

```text
OuterWallTop
```

4. 给 `OuterWallTop` 添加子节点：

```text
CollisionShape2D
```

5. 选中 `CollisionShape2D`。
6. 在 Inspector 中找到 `Shape`。
7. 新建：

```text
RectangleShape2D
```

8. 调整矩形大小，让它成为上方外墙的碰撞范围。

### 6.3 复制出其他墙

第一面墙做好后，可以复制它。

建议复制出：

```text
OuterWallBottom
OuterWallLeft
OuterWallRight
DividerWallHorizontalLeft
DividerWallHorizontalRight
DividerWallVertical
```

其中：

- `OuterWallTop`：上外墙。
- `OuterWallBottom`：下外墙。
- `OuterWallLeft`：左外墙。
- `OuterWallRight`：右外墙。
- `DividerWallHorizontalLeft`：大厅和下方房间之间的左半段隔断。
- `DividerWallHorizontalRight`：大厅和下方房间之间的右半段隔断。
- `DividerWallVertical`：下方仓库和蘑菇洞入口房之间的竖隔断。

为什么横向隔断要拆成左右两段：

```text
为了在中间留门。
```

如果你用一整段横墙，玩家就无法从大厅走到下方房间。

## 7. 墙体可视化怎么处理

`StaticBody2D + CollisionShape2D` 默认只提供碰撞，不一定有正式图片。

你有三种选择：

### 7.1 先只用碰撞调试显示

在 Godot 运行游戏后，可以打开：

```text
Debug -> Visible Collision Shapes
```

这样运行时可以看到蓝色或绿色碰撞框。

优点：

- 最快验证碰撞。
- 不用立刻找墙素材。

缺点：

- 游戏画面里看不到正式墙。
- 只适合开发阶段。

### 7.2 给墙加 Sprite2D 图片

每个墙体可以加：

```text
StaticBody2D
  Sprite2D
  CollisionShape2D
```

但长墙如果用单张图片拉伸，像素素材可能变形。

适合：

- 临时占位墙。
- 非像素风墙块。

### 7.3 用 TileMapLayer 画墙，StaticBody2D 做碰撞

这是当前最推荐的折中方案：

- 视觉上：用 `TileMapLayer` 画墙。
- 碰撞上：用 `StaticBody2D` 做阻挡。

优点：

- 看起来像地图。
- 碰撞逻辑仍然简单。
- 不需要马上学习 TileSet 碰撞配置。

缺点：

- 视觉墙和碰撞墙需要手动对齐。

当前阶段建议采用这个方法。

## 8. 如何让人不能碰到墙

玩家不能穿墙需要两个条件同时满足：

### 8.1 玩家有碰撞体

你的 `player_main.tscn` 里已经有：

```text
Player_Main (CharacterBody2D)
  CollisionShape2D
```

这说明玩家有碰撞体。

如果玩家仍然穿墙，需要检查：

- `CollisionShape2D` 是否有 `Shape`。
- `Shape` 是否太小。
- `CollisionShape2D` 是否被禁用。

### 8.2 墙也有碰撞体

每面墙需要：

```text
StaticBody2D
  CollisionShape2D
```

并且 `CollisionShape2D` 的 `Shape` 不能是空的。

推荐用：

```text
RectangleShape2D
```

原因：墙通常是长方形。

## 9. 碰撞层和遮罩先不要复杂化

Godot 里有：

```text
Collision Layer
Collision Mask
```

它们决定“谁和谁发生碰撞”。

当前阶段建议先保持默认设置，不要改。

默认情况下：

- 玩家在默认 Layer 1。
- 墙也在默认 Layer 1。
- 玩家会检测默认 Layer 1。

这样通常已经可以碰撞。

只有当你发现“玩家有碰撞体、墙也有碰撞体，但仍然穿过去”时，再检查 Layer 和 Mask。

## 10. 推荐房间功能安排

隔成三个屋子后，可以这样放对象：

| 房间 | 放置对象 | 原因 |
|---|---|---|
| 酒馆大厅 | `BrewBarrel` | 酿酒和营业核心区域 |
| 仓库 | `SugarCrate` | 买糖和材料管理更合理 |
| 蘑菇洞入口房 | `MushroomCaveDoor` | 后续进入采集场景 |

建议位置：

```text
酒馆大厅：玩家初始点附近，空间最大。
仓库：左下角或右下角。
蘑菇洞入口房：另一个下方小房间。
```

如果现在三个交互对象位置和房间不匹配，可以先移动它们。

移动方法：

1. 选中交互对象，例如 `SugarCrate`。
2. 使用移动工具拖动。
3. 或在 Inspector 里修改 `Transform -> Position`。

## 11. 验收标准

完成后逐项检查：

- 主场景中有 `Walls` 节点。
- `Walls` 下有多面 `StaticBody2D` 墙。
- 每面墙下面都有 `CollisionShape2D`。
- 每个 `CollisionShape2D` 都设置了 `RectangleShape2D`。
- 玩家不能穿过外墙。
- 玩家不能穿过隔断墙。
- 玩家能从门口通过。
- 酒馆空间能看出三个房间。
- 三个交互对象分别位于合适房间。
- 靠近交互对象仍然能显示提示。
- 按 `interact` 仍然能触发反馈。

## 12. 常见问题

### 12.1 玩家还是能穿墙

检查：

- 墙是不是 `StaticBody2D`，不是普通 `Node2D`。
- 墙下面有没有 `CollisionShape2D`。
- `CollisionShape2D` 有没有设置 `RectangleShape2D`。
- 玩家自己的 `CollisionShape2D` 有没有设置形状。
- 玩家脚本是否仍然使用 `move_and_slide()`。
- 运行时是否真的碰到了墙的碰撞框。

### 12.2 墙挡住了门口

横向隔断不要用一整段。

应该拆成：

```text
DividerWallHorizontalLeft
DividerWallHorizontalRight
```

中间留空就是门。

### 12.3 视觉墙和碰撞墙对不上

如果你用 TileMap 画墙、StaticBody2D 做碰撞，二者需要手动对齐。

建议：

1. 运行时打开 `Debug -> Visible Collision Shapes`。
2. 看碰撞框是不是正好覆盖墙。
3. 如果偏了，调整 `StaticBody2D` 的位置或 `CollisionShape2D` 的尺寸。

### 12.4 玩家被卡住

可能原因：

- 门口太窄。
- 玩家碰撞框太大。
- 两段墙之间留的空隙不够。

建议：

- 门口至少留出比玩家碰撞框宽 `1.5` 倍的空间。
- 玩家碰撞框可以稍微小于角色图片，不一定覆盖整个人。

## 13. 我建议你先亲自做的部分

这一步非常适合你亲自做，因为它能帮助你理解 Godot 的碰撞系统。

建议你亲自操作：

- 新建 `Walls`。
- 新建 `StaticBody2D`。
- 给墙添加 `CollisionShape2D`。
- 调整 `RectangleShape2D` 尺寸。
- 打开可见碰撞形状进行测试。

我可以帮你做：

- 如果你完成后玩家仍然穿墙，我可以检查场景文件。
- 如果你想快速生成一版墙体，我可以直接帮你改 `main.tscn`。
- 如果你想把墙视觉和素材对齐，我可以帮你整理节点结构。

## 14. 下一步建议

建议执行顺序：

1. 先只做外墙。
2. 测试玩家不能走出酒馆。
3. 再做横向隔断，并留门。
4. 测试玩家能从门口进出。
5. 再做竖向隔断，形成三个屋子。
6. 把 `BrewBarrel`、`SugarCrate`、`MushroomCaveDoor` 移动到对应房间。
7. 测试移动、碰撞、交互是否都正常。

完成后，空间结构就能支撑第三阶段的经营数据系统了。

