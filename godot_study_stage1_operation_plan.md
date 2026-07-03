# Godot Study 第一阶段操作方案：场景和角色移动

本文件基于 `godot_study.md` 的第一阶段目标编写。当前阶段只解决一件事：让你在 Godot 里能理解并搭出“玩家角色在酒馆场景中移动”的最小版本。

本方案不急着做酿酒、交互、背包和经营规则。先把角色显示、移动、碰撞和主场景跑通。

## 1. 官方文档核对结论

我查阅了 Godot 官方文档后，第一阶段仍建议使用 `CharacterBody2D`。

官方文档要点：

- `CharacterBody2D` 是 Godot 4 中用于脚本控制的 2D 物理角色节点，适合玩家角色、NPC、敌人这类需要移动和碰撞的对象。
- `CharacterBody2D` 通常配合脚本中的 `velocity` 和 `move_and_slide()` 使用。
- Godot 的游戏对象由节点组成，场景就是节点树；玩家角色一般会做成一个单独场景，再实例化到主场景里。

参考文档：

- Godot `CharacterBody2D` 类说明：<https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html>
- Godot 使用 `CharacterBody2D` 的 2D 移动教程：<https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html>
- Godot 节点和场景基础：<https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html>

## 2. CharacterBody2D 是什么

`CharacterBody2D` 可以理解为“专门给 2D 角色移动用的身体节点”。

它不是一张图片，也不是动画播放器，而是角色在 2D 世界中的物理主体。它负责让角色：

- 有位置。
- 能被脚本控制移动。
- 能和墙、桌子、吧台等碰撞体发生阻挡。
- 能使用 Godot 内置的移动函数处理滑动和碰撞。

一个完整玩家角色通常不是只有 `CharacterBody2D`，而是一个小节点树：

```text
Player (CharacterBody2D)
  Sprite2D
  CollisionShape2D
  Camera2D（可选，后续也可以放在主场景）
```

各节点作用：

| 节点 | 作用 |
|---|---|
| `CharacterBody2D` | 玩家角色的身体和移动主体 |
| `Sprite2D` | 显示角色图片 |
| `CollisionShape2D` | 定义玩家碰撞范围 |
| `Camera2D` | 让镜头跟随玩家，可后续再加 |

## 3. 你为什么没找到 CharacterBody2D

结合当前工程，最可能的原因有这些：

1. 你没有打开“创建新节点”的完整搜索窗口。
   - 在场景树里点 `+` 或右键选择 `Add Child Node`。
   - 在搜索框输入完整名称：`CharacterBody2D`。
   - 注意不要输入空格，例如不要写成 `Character Body 2D`。

2. 你可能正在看“快速创建根节点”的几个大按钮。
   - 新建场景时 Godot 可能只显示 `2D Scene`、`3D Scene`、`User Interface` 等快捷选项。
   - 这时可以先选 `2D Scene`，创建出 `Node2D`。
   - 然后在左侧场景树里添加子节点，再搜索 `CharacterBody2D`。

3. 你使用的教程可能是 Godot 3 的旧名称。
   - Godot 3 常见节点叫 `KinematicBody2D`。
   - Godot 4 中推荐使用 `CharacterBody2D`。
   - 你的项目配置里写着 Godot 4.7，所以应当找 `CharacterBody2D`。

4. 搜索框可能被大小写或过滤条件干扰。
   - 直接复制 `CharacterBody2D` 到节点搜索框。
   - 如果仍然搜不到，确认 Godot 编辑器版本是否真的是 4.x。

## 4. 第一阶段推荐方案

### 4.1 推荐方案：CharacterBody2D 玩家场景

这是我推荐采用的方案。

优点：

- 符合 Godot 4 官方推荐。
- 后续可以自然加入墙体碰撞、桌子阻挡、门口触发区。
- 适合我们这个俯视角地牢酒馆小游戏。
- 现在多学一点，后面少返工。

缺点：

- 比直接移动 `Sprite2D` 多两个概念：碰撞形状和物理移动。
- 第一次创建节点时容易找不到。

### 4.2 备选方案：Node2D + Sprite2D 直接移动

这种方案最简单，但只适合作为临时演示。

优点：

- 容易理解。
- 很快能看到图片移动。

缺点：

- 没有自然碰撞处理。
- 后续做墙、桌子、吧台阻挡时要重构。
- 不适合继续做完整小游戏。

### 4.3 备选方案：Area2D 玩家

`Area2D` 更适合检测进入范围、触发交互，不适合作为主要玩家移动身体。

优点：

- 适合做“靠近酒桶按 E 交互”。
- 后续交互对象会大量使用。

缺点：

- 不适合作为玩家主身体。
- 碰撞阻挡和移动处理不如 `CharacterBody2D` 直接。

结论：第一阶段玩家用 `CharacterBody2D`；第二阶段交互对象用 `Area2D`。

## 5. 第一阶段最终目标

完成后应该达到：

- 游戏可以运行进入主场景。
- 屏幕上能看到一个玩家角色或占位方块。
- 玩家可以用 WASD 或方向键移动。
- 玩家有碰撞范围。
- 场景里至少有一个简单酒馆地面或占位背景。
- 文件结构清楚，为第二阶段交互做准备。

## 6. 建议文件和目录

当前工程路径：

```text
D:\godot_study\新建游戏项目
```

建议建立：

```text
assets\
assets\sprites\
assets\tilesets\
assets\ui\
scenes\
scripts\
```

建议第一阶段文件：

```text
scenes\main.tscn
scenes\player.tscn
scripts\player.gd
```

## 7. 手动操作步骤

### 7.1 建立主场景

1. 打开 Godot。
2. 打开项目：`D:\godot_study\新建游戏项目`。
3. 新建场景。
4. 选择 `2D Scene`。
5. 把根节点改名为 `Main`。
6. 保存为：

```text
res://scenes/main.tscn
```

如果还没有 `scenes` 文件夹，就先在 Godot 文件系统面板里新建。

### 7.2 建立玩家场景

1. 新建一个场景。
2. 不要只点快捷的 `2D Scene` 后结束；需要创建玩家根节点。
3. 在创建节点窗口里搜索：

```text
CharacterBody2D
```

4. 选择 `CharacterBody2D`。
5. 把根节点改名为 `Player`。
6. 给 `Player` 添加子节点：

```text
Sprite2D
CollisionShape2D
```

7. 保存为：

```text
res://scenes/player.tscn
```

### 7.3 如果还是找不到 CharacterBody2D

按这个顺序排查：

1. 确认搜索词是 `CharacterBody2D`，不是 `Character Body 2D`。
2. 确认你是在 `Add Child Node` 或“创建新节点”的搜索框里找。
3. 确认 Godot 版本是 4.x。
4. 如果你看到的是 `KinematicBody2D`，说明你打开的可能是 Godot 3.x 教程或旧编辑器。
5. 如果确实搜不到，先告诉我你 Godot 左上角或标题栏显示的版本号，我会根据版本调整方案。

### 7.4 给玩家显示图片

第一阶段可以先不用正式素材，优先保证移动跑通。

可选做法：

1. 临时使用 `icon.svg` 作为 `Sprite2D` 的 Texture。
2. 或从素材库复制一个角色图片到：

```text
res://assets/sprites/
```

第一阶段不建议一开始就花太多时间挑素材。角色先能动更重要。

### 7.5 给玩家添加碰撞形状

1. 选中 `CollisionShape2D`。
2. 在右侧 Inspector 里找到 `Shape`。
3. 新建一个 `RectangleShape2D` 或 `CircleShape2D`。
4. 调整大小，让碰撞框大致覆盖玩家脚下或身体。

俯视角像素游戏里，碰撞框不一定要覆盖整个人。通常覆盖脚下区域会更舒服，但第一阶段可以先覆盖整个占位图。

### 7.6 编写玩家移动脚本

把脚本挂到 `Player (CharacterBody2D)` 上。

脚本路径：

```text
res://scripts/player.gd
```

移动逻辑建议：

```gdscript
extends CharacterBody2D

@export var speed: float = 120.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
```

这个脚本的意思：

- `extends CharacterBody2D`：说明这个脚本挂在玩家身体节点上。
- `speed`：玩家移动速度。
- `Input.get_vector(...)`：读取左右上下输入。
- `velocity`：当前移动速度方向。
- `move_and_slide()`：让 Godot 按物理规则移动角色。

### 7.7 设置输入映射

打开：

```text
Project -> Project Settings -> Input Map
```

新增这些动作：

```text
move_left
move_right
move_up
move_down
interact
```

建议绑定：

| 动作 | 按键 |
|---|---|
| `move_left` | A、Left |
| `move_right` | D、Right |
| `move_up` | W、Up |
| `move_down` | S、Down |
| `interact` | E |

`interact` 第一阶段可以先建好，第二阶段交互时再使用。

### 7.8 把玩家放进主场景

1. 打开 `main.tscn`。
2. 把 `player.tscn` 拖进 `Main` 场景。
3. 调整玩家位置，让它出现在屏幕中央附近。
4. 可以先给主场景加一个简单背景：
   - `ColorRect` 作为纯色背景；或
   - `Sprite2D` 显示临时地板图；或
   - 后续再做 TileMap。

第一阶段不建议立刻做完整 TileMap。先用简单背景确认移动没有问题。

### 7.9 设置主场景为启动场景

打开：

```text
Project -> Project Settings -> Application -> Run -> Main Scene
```

选择：

```text
res://scenes/main.tscn
```

之后按运行按钮，游戏应该进入主场景。

## 8. 第一阶段最低验收标准

完成后逐项检查：

- 运行项目能进入 `main.tscn`。
- 屏幕上能看到玩家。
- WASD 可以移动。
- 方向键可以移动。
- 玩家移动速度不太快也不太慢。
- 关闭游戏再重新打开项目，场景和脚本仍然存在。

如果以上都满足，第一阶段的“移动最小版本”就通过。

## 9. 我建议我代写的部分

为了不让你卡在文件结构和脚本细节上，我建议由我代写：

- `scripts/player.gd`
- 基础 `main.tscn`
- 基础 `player.tscn`
- 项目输入映射配置
- 启动场景配置

你更适合亲自操作和观察的部分：

- 在 Godot 里找到并认识 `CharacterBody2D`。
- 观察场景树结构。
- 调整玩家速度。
- 调整 `Sprite2D` 图片。
- 调整 `CollisionShape2D` 大小。

这样你能学到 Godot 的核心操作，同时不被重复配置拖慢。

## 10. 第一阶段完成后的下一步

第一阶段跑通后，再进入第二阶段：基础交互。

第二阶段会新增：

- `Area2D` 交互检测。
- 靠近酒桶显示“按 E 互动”。
- 按 E 输出日志或弹出提示。
- 后续把酒桶、商人、蘑菇洞入口接到真实玩法。

也就是说：

```text
CharacterBody2D 负责玩家移动。
Area2D 负责交互范围检测。
```

这两个节点分工清楚，后续扩展会更稳。

