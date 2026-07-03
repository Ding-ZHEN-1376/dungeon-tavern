# Godot Study 第二阶段记录：基础交互

本文件记录第二阶段“基础交互”的当前实现、学习重点、验证方式，以及如何把你的图片素材用到交互对象上。

第一阶段解决的是“角色能移动”。第二阶段解决的是“角色靠近对象后，能看到提示，并按交互键触发反馈”。目前还不接入真正的酿酒、购买、采集系统，只先把交互入口打通。

## 1. 当前阶段目标

第二阶段的目标是建立一套可复用的交互基础：

- 玩家靠近交互对象时，显示提示文字。
- 玩家离开交互对象时，隐藏提示文字。
- 玩家按 `interact` 时，触发当前交互对象。
- 不同交互对象可以有不同提示和不同反馈。
- 后续酿酒桶、糖箱、蘑菇洞入口都能复用同一套交互脚本。

当前已放入主场景的交互点：

| 节点名 | 当前用途 | 后续目标 |
|---|---|---|
| `BrewBarrel` | 查看酿酒桶 | 打开酿酒菜单 |
| `SugarCrate` | 查看糖箱 | 购买低级糖 |
| `MushroomCaveDoor` | 查看蘑菇洞入口 | 切换到采集场景 |

## 2. 当前涉及文件

```text
D:\godot_study\新建游戏项目\scripts\player_main.gd
D:\godot_study\新建游戏项目\scripts\interactable.gd
D:\godot_study\新建游戏项目\scenes\main.tscn
```

### 2.1 player_main.gd

`player_main.gd` 现在负责两件事：

1. 控制玩家移动。
2. 记录当前靠近的交互对象，并在按下 `interact` 时调用它。

核心变量：

```gdscript
var current_interactable: Node = null
```

它表示“玩家当前能互动的对象”。如果玩家没有靠近任何交互对象，这个值就是 `null`。

核心函数：

```gdscript
func set_interactable(interactable: Node) -> void:
	current_interactable = interactable

func clear_interactable(interactable: Node) -> void:
	if current_interactable == interactable:
		current_interactable = null
```

这两个函数给交互对象调用：

- 玩家进入范围时，交互对象调用 `set_interactable(self)`。
- 玩家离开范围时，交互对象调用 `clear_interactable(self)`。

### 2.2 interactable.gd

`interactable.gd` 是通用交互脚本。它挂在 `Area2D` 上。

它提供两个可在 Inspector 里修改的文本：

```gdscript
@export var prompt_text: String = "按 E 互动"
@export var action_text: String = "互动成功"
```

含义：

| 字段 | 用途 |
|---|---|
| `prompt_text` | 玩家靠近时显示的提示 |
| `action_text` | 玩家按交互键后输出的反馈 |

当前的 `interact()` 只会打印文本：

```gdscript
func interact() -> void:
	print(action_text)
```

这只是占位逻辑。第三阶段开始做库存、金币、酿酒时，这里会逐步改成调用真实功能。

### 2.3 main.tscn

`main.tscn` 里已有三个 `Area2D` 交互点：

```text
Main
  BrewBarrel (Area2D)
    CollisionShape2D
    PromptLabel
  SugarCrate (Area2D)
    CollisionShape2D
    PromptLabel
  MushroomCaveDoor (Area2D)
    CollisionShape2D
    PromptLabel
```

当前它们还没有专属图片，只是逻辑交互点。下一步可以给每个对象加图片素材。

## 3. Area2D 在这里的作用

`Area2D` 可以理解为“检测范围”。

它不负责玩家移动，也不负责阻挡玩家。它负责检测：

- 有没有玩家进入范围。
- 有没有玩家离开范围。

第二阶段里：

- 玩家本体是 `CharacterBody2D`。
- 交互对象是 `Area2D`。
- `Area2D` 发现玩家进入范围后，把自己告诉玩家。
- 玩家按 `interact` 时，再调用这个 `Area2D` 的 `interact()`。

这种分工很重要：

```text
CharacterBody2D：玩家移动。
Area2D：交互检测。
CollisionShape2D：定义范围大小。
Sprite2D：显示图片。
Label：显示提示文字。
```

## 4. 交互对象的推荐节点结构

每个可交互对象建议使用这个结构：

```text
ObjectName (Area2D)
  Sprite2D
  CollisionShape2D
  PromptLabel (Label)
```

例如酿酒桶：

```text
BrewBarrel (Area2D)
  Sprite2D
  CollisionShape2D
  PromptLabel
```

各节点职责：

| 节点 | 作用 |
|---|---|
| `Area2D` | 交互对象主体，挂 `interactable.gd` |
| `Sprite2D` | 显示图片素材 |
| `CollisionShape2D` | 决定玩家靠多近才算进入交互范围 |
| `PromptLabel` | 显示“按 E：...”提示 |

注意：`Sprite2D` 只是视觉，不影响能不能交互；真正决定范围的是 `CollisionShape2D`。

## 5. 如何把图片素材用到交互对象上

下面以 `BrewBarrel` 为例。`SugarCrate` 和 `MushroomCaveDoor` 同理。

### 5.1 把图片放进 Godot 工程

不要直接引用 `D:\godot_study\素材库` 里的原始文件。建议复制一份到 Godot 工程内。

推荐放置路径：

```text
D:\godot_study\新建游戏项目\assets\sprites\interactables\
```

例如：

```text
D:\godot_study\新建游戏项目\assets\sprites\interactables\barrel.png
D:\godot_study\新建游戏项目\assets\sprites\interactables\sugar_crate.png
D:\godot_study\新建游戏项目\assets\sprites\interactables\cave_door.png
```

在 Godot 里会显示为：

```text
res://assets/sprites/interactables/barrel.png
res://assets/sprites/interactables/sugar_crate.png
res://assets/sprites/interactables/cave_door.png
```

如果你用的是素材表，也就是一张大图里有很多小图标，路径也可以放这里：

```text
res://assets/sprites/interactables/objects_sheet.png
```

### 5.2 给交互对象添加 Sprite2D

1. 打开 `main.tscn`。
2. 在场景树里找到 `BrewBarrel`。
3. 右键 `BrewBarrel`。
4. 选择 `Add Child Node`。
5. 搜索并添加：

```text
Sprite2D
```

6. 建议把 `Sprite2D` 放在 `CollisionShape2D` 和 `PromptLabel` 前面，结构变成：

```text
BrewBarrel (Area2D)
  Sprite2D
  CollisionShape2D
  PromptLabel
```

节点顺序不是功能必需，但这样更好读。

### 5.3 给 Sprite2D 设置图片

1. 选中 `BrewBarrel` 下的 `Sprite2D`。
2. 在右侧 Inspector 找到 `Texture`。
3. 把图片从 FileSystem 面板拖到 `Texture`。
4. 或点击 `Texture` 后手动选择图片文件。

如果图片太大或太小，可以调：

```text
Transform -> Scale
```

例如：

```text
Scale = (1.5, 1.5)
```

如果图片位置不对，可以调：

```text
Transform -> Position
```

通常让图片中心和 `Area2D` 的中心对齐即可。

### 5.4 如果图片来自大素材表

有些素材包会把很多小物件放在一张大图里。此时有两种做法。

第一种：先用整张图临时显示。

- 简单，但会显示整张素材表。
- 不适合最终使用，只适合确认素材是否导入成功。

第二种：使用 `AtlasTexture` 截取其中一个小图。

操作思路：

1. 选中 `Sprite2D`。
2. 在 `Texture` 里新建 `AtlasTexture`。
3. 给 `AtlasTexture` 的 `Atlas` 选择那张素材表。
4. 调整 `Region`，截取你要的桶、箱子或洞口图块。

如果你还不熟悉 `AtlasTexture`，更建议先把需要的小图单独裁出来，再放进 `assets\sprites\interactables\`。这样学习成本低，后面再研究素材表切图。

## 6. 如何调整交互范围

交互对象能不能被触发，不由图片大小决定，而由 `CollisionShape2D` 决定。

以 `BrewBarrel` 为例：

1. 选中：

```text
BrewBarrel -> CollisionShape2D
```

2. 在 Inspector 里找到 `Shape`。
3. 如果是 `CircleShape2D`，调整 `Radius`。
4. 如果是 `RectangleShape2D`，调整矩形尺寸。

建议：

- 酒桶、糖箱：交互范围可以比图片大一点，方便玩家触发。
- 洞口：交互范围可以更大一点，让玩家站到门口附近就能触发。
- 不要过大，否则玩家离很远也会出现提示。

当前第二阶段临时范围使用的是圆形检测，半径约为 `36`。

## 7. 如何修改提示文字和反馈文字

选中交互对象，例如：

```text
BrewBarrel
```

右侧 Inspector 会显示脚本导出的变量：

```text
prompt_text
action_text
```

你可以直接改：

```text
prompt_text = 按 E：查看酿酒桶
action_text = 你查看了酿酒桶。下一阶段这里会打开酿酒菜单。
```

建议命名：

| 对象 | prompt_text | action_text |
|---|---|---|
| 酿酒桶 | 按 E：查看酿酒桶 | 你查看了酿酒桶。 |
| 糖箱 | 按 E：查看糖箱 | 你查看了糖箱。 |
| 蘑菇洞入口 | 按 E：进入蘑菇洞 | 你站在蘑菇洞入口前。 |

后续真正接功能时，`action_text` 会逐步变成真实行为，不只是打印文字。

## 8. 推荐素材对应关系

你有图片素材时，可以先按这个方向选择：

| 交互对象 | 推荐图片 |
|---|---|
| `BrewBarrel` | 酒桶、木桶、酿造台、酒坛 |
| `SugarCrate` | 箱子、袋子、糖罐、材料箱 |
| `MushroomCaveDoor` | 洞口、门、楼梯、地下入口 |

如果只有一张通用物品图，也可以先复用。当前阶段重点是“能看见对象并能互动”，不是最终美术。

## 9. 第二阶段验收标准

完成第二阶段后，用这个清单检查：

- 玩家能正常移动。
- 靠近 `BrewBarrel` 时出现提示。
- 靠近 `SugarCrate` 时出现提示。
- 靠近 `MushroomCaveDoor` 时出现提示。
- 离开对象后提示消失。
- 在对象附近按 `interact`，Godot 输出面板出现对应反馈。
- 不在对象附近按 `interact`，输出“附近没有可以互动的对象”。
- 给对象添加 `Sprite2D` 后，图片能显示在场景中。
- 调整图片不会影响交互范围。
- 调整 `CollisionShape2D` 会影响交互范围。

## 10. 常见问题

### 10.1 图片显示了，但不能交互

检查：

- `Area2D` 上是否挂了 `interactable.gd`。
- `Area2D` 下是否有 `CollisionShape2D`。
- `CollisionShape2D` 是否设置了 `Shape`。
- 玩家是否进入了碰撞范围。

### 10.2 能交互，但看不到图片

检查：

- `Sprite2D` 是否是交互对象的子节点。
- `Sprite2D` 的 `Texture` 是否设置了图片。
- 图片是不是太小、太大或位置偏到屏幕外。
- `Sprite2D` 的 `Visible` 是否开启。

### 10.3 提示文字没有显示

检查：

- `PromptLabel` 名字是否完全叫 `PromptLabel`。
- `PromptLabel` 是否是 `Area2D` 的子节点。
- `interactable.gd` 里使用的是 `$PromptLabel`，名字不一致会找不到。
- `PromptLabel` 位置是否太远或被背景遮住。

### 10.4 靠近多个对象时提示混乱

当前版本只记录一个 `current_interactable`。如果多个交互范围重叠，最后进入的对象会覆盖前一个对象。

这是第二阶段可以接受的简化。后续如果需要更稳定，可以升级为“交互对象列表”，自动选择最近的对象。

## 11. 下一步建议

第二阶段完成后，下一阶段建议做“时间、库存和金币”的最小数据模型。

但是在进入第三阶段前，可以先做一个小打磨：

1. 给 `BrewBarrel`、`SugarCrate`、`MushroomCaveDoor` 添加图片。
2. 调整三个对象的位置，让它们看起来像酒馆内的可用设施。
3. 调整提示文字位置，避免遮挡角色。
4. 手动测试三处交互是否都稳定。

等这些确认后，再把交互行为接到真实功能：

```text
酿酒桶 -> 打开配方酿酒入口
糖箱 -> 购买低级糖
蘑菇洞入口 -> 进入采集场景
```

