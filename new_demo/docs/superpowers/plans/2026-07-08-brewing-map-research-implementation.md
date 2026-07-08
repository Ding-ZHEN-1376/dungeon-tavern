# Brewing Map Research Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable version of the brewing map research minigame described in `new_demo/docs/superpowers/specs/2026-07-08-brewing-map-research-summary.md`.

**Architecture:** Keep gameplay rules out of `main.tscn` and out of scene-specific button handlers. Put recipe data in a small catalog object, put all route/state/success/failure rules in a pure `RefCounted` session object, and make the UI consume that session through clear methods. The first UI uses plain Godot controls and colors so art assets can be swapped later without changing the rules.

**Tech Stack:** Godot 4 GDScript, existing `MenuManager`, existing `BaseInteractionMenu`, existing `MaterialInventory` Autoload, existing `MaterialDatabase`.

## Global Constraints

- Do not implement the full long-term brewing system in this pass.
- Do not put brewing rules directly in `main.tscn`.
- Do not hardcode UI button behavior as the only source of gameplay truth.
- First version only supports the `dungeon_mushroom` recipe map.
- First version uses an 11x11 odd-sized map with start position `(5,5)`.
- First version has two 2x2 wine zones at `(1,1)` and `(8,8)`.
- First version supports at most 5 committed ingredient inputs.
- First version supports only water, rye, cave red mushroom, cave blue mushroom, grinder, and oven/dryer style processing.
- Advanced systems such as danger zones, special zones, optimal-cost scoring, shop purchase flow, permanent recipe persistence, and final production batching are out of scope.

---

## File Structure

Create these new gameplay files:

- `new_demo/scripts/systems/brewing/brewing_research_catalog.gd`
  - Static data for the first recipe map, allowed ingredients, tool-gated processing methods, and wine zones.
  - Later this can be replaced by `.tres` Resources or JSON without changing the session interface.

- `new_demo/scripts/systems/brewing/brewing_research_session.gd`
  - Pure state object for one research attempt.
  - Tracks map size, current position, used input count, revealed cells, committed path, selected recipe, discovered wine, and failure state.
  - Computes route previews and validates commits.

- `new_demo/scripts/systems/brewing/brewing_player_tools.gd`
  - Small temporary tool ownership object.
  - First version can return a fixed list of owned tools, then later connect to shop/player progression.

Create these new UI files:

- `new_demo/scenes/ui/menus/brewing/BrewingResearchMenu.tscn`
  - New full-screen research UI opened from the brewing barrel menu.
  - Contains map area, material/method controls, status text, route log, confirm button, finish button, and close button.

- `new_demo/scripts/ui/menus/brewing/BrewingResearchMenu.gd`
  - UI controller for the research menu.
  - Creates visible grid cells at runtime from session data.
  - Does not decide recipe rules by itself.

Modify these existing files:

- `new_demo/scripts/ui/MenuManager.gd`
  - Register `brewing_research` menu id.

- `new_demo/scripts/ui/menus/BrewingMenu.gd`
  - On start button, open `brewing_research` instead of emitting a dead-end action.

- `new_demo/scripts/systems/material_database.gd`
  - Add display names and placeholder icon paths for water, rye, cave red mushroom, cave blue mushroom, failed mushroom wine, and discovered wines.

- `new_demo/scripts/systems/material_inventory.gd`
  - Add first-version demo materials to the backpack.
  - Add a small helper for consuming one material stack from the backpack.

Optional developer-only verification file:

- `new_demo/scripts/dev/brewing_research_smoke_test.gd`
  - A small scene-tree script that instantiates `BrewingResearchSession` and verifies route preview, commit, success, and failure rules.

---

### Task 1: Add Research Data Catalog

**Files:**
- Create: `new_demo/scripts/systems/brewing/brewing_research_catalog.gd`

**Interfaces:**
- Produces:
  - `static func get_recipe(recipe_id: String) -> Dictionary`
  - `static func get_material(material_id: String) -> Dictionary`
  - `static func get_method(method_id: String) -> Dictionary`
  - `static func get_allowed_materials(recipe_id: String) -> Array[String]`
  - `static func get_allowed_methods(material_id: String) -> Array[String]`

- [ ] **Step 1: Create the catalog script**

Add `new_demo/scripts/systems/brewing/brewing_research_catalog.gd`:

```gdscript
extends RefCounted
class_name BrewingResearchCatalog

const METHOD_NONE := "none"
const METHOD_GRIND := "grind"
const METHOD_BAKE := "bake"

const RECIPES := {
	"dungeon_mushroom": {
		"display_name": "地牢蘑菇酒谱",
		"map_size": Vector2i(11, 11),
		"start": Vector2i(5, 5),
		"max_inputs": 5,
		"allowed_materials": [
			"water",
			"rye",
			"cave_red_mushroom",
			"cave_blue_mushroom"
		],
		"wine_zones": [
			{
				"id": "glowing_mushroom_wine",
				"display_name": "发光蘑菇酒",
				"top_left": Vector2i(1, 1),
				"size": Vector2i(2, 2)
			},
			{
				"id": "deep_mushroom_wine",
				"display_name": "深层蘑菇酒",
				"top_left": Vector2i(8, 8),
				"size": Vector2i(2, 2)
			}
		]
	}
}

const MATERIALS := {
	"water": {
		"display_name": "水",
		"base_route": [],
		"methods": [METHOD_NONE]
	},
	"rye": {
		"display_name": "黑麦",
		"base_route": [],
		"methods": [METHOD_NONE]
	},
	"cave_red_mushroom": {
		"display_name": "洞穴红蘑菇",
		"base_route": [Vector2i(0, -1)],
		"methods": [METHOD_NONE, METHOD_GRIND, METHOD_BAKE]
	},
	"cave_blue_mushroom": {
		"display_name": "洞穴蓝蘑菇",
		"base_route": [Vector2i(-1, 0)],
		"methods": [METHOD_NONE, METHOD_GRIND, METHOD_BAKE]
	}
}

const METHODS := {
	METHOD_NONE: {
		"display_name": "不处理",
		"required_tool": "",
		"description": "保留材料原始路线。"
	},
	METHOD_GRIND: {
		"display_name": "研磨",
		"required_tool": "grinder",
		"description": "延伸材料路线。"
	},
	METHOD_BAKE: {
		"display_name": "烘烤",
		"required_tool": "oven",
		"description": "反转材料路线。"
	}
}

static func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {})

static func get_material(material_id: String) -> Dictionary:
	return MATERIALS.get(material_id, {})

static func get_method(method_id: String) -> Dictionary:
	return METHODS.get(method_id, {})

static func get_allowed_materials(recipe_id: String) -> Array[String]:
	var recipe := get_recipe(recipe_id)
	var result: Array[String] = []
	for material_id in recipe.get("allowed_materials", []):
		result.append(String(material_id))
	return result

static func get_allowed_methods(material_id: String) -> Array[String]:
	var material := get_material(material_id)
	var result: Array[String] = []
	for method_id in material.get("methods", []):
		result.append(String(method_id))
	return result

static func build_route(material_id: String, method_id: String) -> Array[Vector2i]:
	var material := get_material(material_id)
	var base_route: Array[Vector2i] = []
	for step in material.get("base_route", []):
		base_route.append(step)

	if method_id == METHOD_NONE:
		return base_route
	if method_id == METHOD_GRIND:
		return _extend_route(base_route)
	if method_id == METHOD_BAKE:
		return _reverse_route(base_route)
	return []

static func _extend_route(base_route: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for step in base_route:
		result.append(step)
		result.append(step)
	return result

static func _reverse_route(base_route: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for step in base_route:
		result.append(Vector2i(-step.x, -step.y))
	return result
```

- [ ] **Step 2: Check script loads in Godot**

Open Godot and confirm there are no parser errors for `BrewingResearchCatalog`.

Expected: the editor recognizes `BrewingResearchCatalog` as a global class.

---

### Task 2: Add Core Research Session Object

**Files:**
- Create: `new_demo/scripts/systems/brewing/brewing_research_session.gd`

**Interfaces:**
- Consumes:
  - `BrewingResearchCatalog.get_recipe(recipe_id: String) -> Dictionary`
  - `BrewingResearchCatalog.build_route(material_id: String, method_id: String) -> Array[Vector2i]`
- Produces:
  - `func setup(recipe_id: String) -> void`
  - `func preview_input(material_id: String, method_id: String, owned_tools: Array[String]) -> Dictionary`
  - `func commit_input(material_id: String, method_id: String, owned_tools: Array[String]) -> Dictionary`
  - `func finish() -> Dictionary`
  - `func get_cell_state(cell: Vector2i) -> Dictionary`
  - `func get_status() -> Dictionary`

- [ ] **Step 1: Create the session script**

Add `new_demo/scripts/systems/brewing/brewing_research_session.gd`:

```gdscript
extends RefCounted
class_name BrewingResearchSession

const Catalog := preload("res://scripts/systems/brewing/brewing_research_catalog.gd")

var recipe_id: String = ""
var recipe: Dictionary = {}
var map_size: Vector2i = Vector2i.ZERO
var start_position: Vector2i = Vector2i.ZERO
var current_position: Vector2i = Vector2i.ZERO
var max_inputs: int = 0
var used_inputs: int = 0
var committed_inputs: Array[Dictionary] = []
var revealed_cells: Dictionary = {}
var discovered_wine_id: String = ""
var is_finished: bool = false
var failure_result_id: String = "failed_mushroom_wine"

func setup(new_recipe_id: String) -> void:
	recipe_id = new_recipe_id
	recipe = Catalog.get_recipe(recipe_id)
	map_size = recipe.get("map_size", Vector2i(11, 11))
	start_position = recipe.get("start", Vector2i(5, 5))
	current_position = start_position
	max_inputs = int(recipe.get("max_inputs", 5))
	used_inputs = 0
	committed_inputs.clear()
	revealed_cells.clear()
	discovered_wine_id = ""
	is_finished = false
	_reveal_area(current_position, 1)

func preview_input(material_id: String, method_id: String, owned_tools: Array[String]) -> Dictionary:
	if is_finished:
		return _make_result(false, "研发已经结束。", [], current_position, "")
	if used_inputs >= max_inputs:
		return _make_result(false, "投料次数已经用完。", [], current_position, "")
	if not _is_material_allowed(material_id):
		return _make_result(false, "当前酒谱不能使用这个材料。", [], current_position, "")
	if not _is_method_allowed(material_id, method_id):
		return _make_result(false, "这个材料不能使用该处理方法。", [], current_position, "")
	if not _has_required_tool(method_id, owned_tools):
		return _make_result(false, "缺少对应处理道具。", [], current_position, "")

	var route := Catalog.build_route(material_id, method_id)
	var path := _build_absolute_path(current_position, route)
	if not _is_path_inside_map(path):
		return _make_result(false, "路线会超出酒谱地图。", path, current_position, "")
	if not _is_route_inside_local_limit(route):
		return _make_result(false, "单次路线超出 5x5 限制。", path, current_position, "")

	var end_position := current_position
	if not path.is_empty():
		end_position = path[path.size() - 1]
	return _make_result(true, "", path, end_position, _find_wine_at(end_position))

func commit_input(material_id: String, method_id: String, owned_tools: Array[String]) -> Dictionary:
	var preview := preview_input(material_id, method_id, owned_tools)
	if not bool(preview.get("ok", false)):
		return preview

	var path: Array = preview.get("path", [])
	for cell in path:
		_reveal_area(cell, 0)
	current_position = preview.get("end_position", current_position)
	_reveal_area(current_position, 1)
	used_inputs += 1
	committed_inputs.append({
		"material_id": material_id,
		"method_id": method_id,
		"path": path,
		"end_position": current_position
	})

	var wine_id := String(preview.get("wine_id", ""))
	if wine_id != "":
		discovered_wine_id = wine_id
		is_finished = true
		return {
			"ok": true,
			"finished": true,
			"success": true,
			"wine_id": discovered_wine_id,
			"message": "发现了新的酒。"
		}

	if used_inputs >= max_inputs:
		return finish()

	return {
		"ok": true,
		"finished": false,
		"success": false,
		"wine_id": "",
		"message": "路线已确认。"
	}

func finish() -> Dictionary:
	if is_finished and discovered_wine_id != "":
		return {
			"ok": true,
			"finished": true,
			"success": true,
			"wine_id": discovered_wine_id,
			"message": "研发已经成功。"
		}
	is_finished = true
	return {
		"ok": true,
		"finished": true,
		"success": false,
		"wine_id": failure_result_id,
		"message": "研发失败，获得失败酒。"
	}

func get_status() -> Dictionary:
	return {
		"recipe_id": recipe_id,
		"display_name": recipe.get("display_name", recipe_id),
		"map_size": map_size,
		"current_position": current_position,
		"max_inputs": max_inputs,
		"used_inputs": used_inputs,
		"remaining_inputs": max_inputs - used_inputs,
		"is_finished": is_finished,
		"discovered_wine_id": discovered_wine_id,
		"committed_inputs": committed_inputs
	}

func get_cell_state(cell: Vector2i) -> Dictionary:
	var wine_id := _find_wine_at(cell)
	return {
		"revealed": revealed_cells.has(cell),
		"is_current": cell == current_position,
		"is_start": cell == start_position,
		"wine_id": wine_id
	}

func _make_result(ok: bool, message: String, path: Array, end_position: Vector2i, wine_id: String) -> Dictionary:
	return {
		"ok": ok,
		"message": message,
		"path": path,
		"end_position": end_position,
		"wine_id": wine_id
	}

func _is_material_allowed(material_id: String) -> bool:
	return Catalog.get_allowed_materials(recipe_id).has(material_id)

func _is_method_allowed(material_id: String, method_id: String) -> bool:
	return Catalog.get_allowed_methods(material_id).has(method_id)

func _has_required_tool(method_id: String, owned_tools: Array[String]) -> bool:
	var method := Catalog.get_method(method_id)
	var required_tool := String(method.get("required_tool", ""))
	return required_tool == "" or owned_tools.has(required_tool)

func _build_absolute_path(from_position: Vector2i, route: Array[Vector2i]) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var position := from_position
	for step in route:
		position += step
		path.append(position)
	return path

func _is_path_inside_map(path: Array) -> bool:
	for cell in path:
		if not _is_inside_map(cell):
			return false
	return true

func _is_inside_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y

func _is_route_inside_local_limit(route: Array[Vector2i]) -> bool:
	var offset := Vector2i.ZERO
	for step in route:
		offset += step
		if abs(offset.x) > 2 or abs(offset.y) > 2:
			return false
	return true

func _reveal_area(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if _is_inside_map(cell):
				revealed_cells[cell] = true

func _find_wine_at(cell: Vector2i) -> String:
	for zone in recipe.get("wine_zones", []):
		var top_left: Vector2i = zone.get("top_left", Vector2i.ZERO)
		var size: Vector2i = zone.get("size", Vector2i.ONE)
		var inside_x := cell.x >= top_left.x and cell.x < top_left.x + size.x
		var inside_y := cell.y >= top_left.y and cell.y < top_left.y + size.y
		if inside_x and inside_y:
			return String(zone.get("id", ""))
	return ""
```

- [ ] **Step 2: Verify route behavior in editor**

Use the Godot editor script parser to confirm no errors.

Manual check with the debugger console:

```gdscript
var session := BrewingResearchSession.new()
session.setup("dungeon_mushroom")
print(session.preview_input("cave_red_mushroom", "grind", ["grinder", "oven"]))
```

Expected: preview path ends at `(5,3)`.

---

### Task 3: Add Temporary Tool Ownership Object

**Files:**
- Create: `new_demo/scripts/systems/brewing/brewing_player_tools.gd`

**Interfaces:**
- Produces:
  - `static func get_owned_tools() -> Array[String]`
  - `static func has_tool(tool_id: String) -> bool`

- [ ] **Step 1: Create tool helper**

Add `new_demo/scripts/systems/brewing/brewing_player_tools.gd`:

```gdscript
extends RefCounted
class_name BrewingPlayerTools

const OWNED_TOOLS := [
	"grinder",
	"oven"
]

static func get_owned_tools() -> Array[String]:
	var result: Array[String] = []
	for tool_id in OWNED_TOOLS:
		result.append(String(tool_id))
	return result

static func has_tool(tool_id: String) -> bool:
	return get_owned_tools().has(tool_id)
```

- [ ] **Step 2: Keep this object temporary**

Do not connect this to shop purchase yet. The first version assumes the player owns grinder and oven so the research UI can test both gated methods.

---

### Task 4: Expand Material Data and Inventory Helpers

**Files:**
- Modify: `new_demo/scripts/systems/material_database.gd`
- Modify: `new_demo/scripts/systems/material_inventory.gd`

**Interfaces:**
- Produces:
  - `MaterialInventory.get_item_count(container_name: String, material_id: String) -> int`
  - `MaterialInventory.consume_item_from_container(container_name: String, material_id: String, amount: int) -> bool`

- [ ] **Step 1: Add first-version material ids**

Modify `MaterialDatabase.MATERIALS` to include:

```gdscript
"water": {
	"display_name": "水",
	"icon": ""
},
"rye": {
	"display_name": "黑麦",
	"icon": ""
},
"cave_red_mushroom": {
	"display_name": "洞穴红蘑菇",
	"icon": "res://assets/materials/mushroom_temp.png"
},
"cave_blue_mushroom": {
	"display_name": "洞穴蓝蘑菇",
	"icon": "res://assets/materials/mushroom_temp.png"
},
"glowing_mushroom_wine": {
	"display_name": "发光蘑菇酒",
	"icon": "res://assets/materials/wine_temp.png"
},
"deep_mushroom_wine": {
	"display_name": "深层蘑菇酒",
	"icon": "res://assets/materials/wine_temp.png"
},
"failed_mushroom_wine": {
	"display_name": "浑浊蘑菇酒",
	"icon": "res://assets/materials/wine_temp.png"
}
```

- [ ] **Step 2: Add demo starting items**

In `MaterialInventory.reset_inventory(include_demo_items := true)`, add:

```gdscript
add_item_to_container("backpack", "water", 8)
add_item_to_container("backpack", "rye", 8)
add_item_to_container("backpack", "cave_red_mushroom", 8)
add_item_to_container("backpack", "cave_blue_mushroom", 8)
```

Keep existing demo items unless they interfere with UI layout.

- [ ] **Step 3: Add count helper**

Add to `material_inventory.gd`:

```gdscript
func get_item_count(container_name: String, material_id: String) -> int:
	var total := 0
	for slot in get_slots(container_name):
		if String(slot.get("id", "")) == material_id:
			total += int(slot.get("count", 0))
	return total
```

- [ ] **Step 4: Add consume helper**

Add to `material_inventory.gd`:

```gdscript
func consume_item_from_container(container_name: String, material_id: String, amount: int) -> bool:
	if material_id == "" or amount <= 0:
		return false
	if get_item_count(container_name, material_id) < amount:
		return false

	var container := _get_container(container_name)
	if container == null:
		return false

	var remaining := amount
	var slots := container.get_slots()
	for index in range(slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[index]
		if String(slot.get("id", "")) != material_id:
			continue
		var slot_count := int(slot.get("count", 0))
		var used := min(slot_count, remaining)
		slot_count -= used
		remaining -= used
		if slot_count <= 0:
			container.set_slot(index, "", 0)
		else:
			container.set_slot(index, material_id, slot_count)

	inventory_changed.emit()
	return true
```

- [ ] **Step 5: Manual inventory verification**

Run the project. Open any existing inventory UI or use debugger:

```gdscript
print(MaterialInventory.get_item_count("backpack", "cave_red_mushroom"))
```

Expected: a positive count when demo items are included.

---

### Task 5: Create Research Menu UI Scene

**Files:**
- Create: `new_demo/scenes/ui/menus/brewing/BrewingResearchMenu.tscn`
- Create: `new_demo/scripts/ui/menus/brewing/BrewingResearchMenu.gd`

**Interfaces:**
- Consumes:
  - `BrewingResearchSession.setup(recipe_id)`
  - `BrewingResearchSession.preview_input(material_id, method_id, owned_tools)`
  - `BrewingResearchSession.commit_input(material_id, method_id, owned_tools)`
  - `BrewingResearchSession.finish()`
  - `BrewingResearchCatalog.get_allowed_materials(recipe_id)`
  - `BrewingResearchCatalog.get_allowed_methods(material_id)`
  - `BrewingPlayerTools.get_owned_tools()`
  - `MaterialInventory.consume_item_from_container("backpack", material_id, 1)`
- Produces:
  - A visible 11x11 research map.
  - Material and processing method selection in one interface.
  - Confirm button that commits the currently previewed route.

- [ ] **Step 1: Create the scene skeleton**

Create `BrewingResearchMenu.tscn` with this node tree:

```text
BrewingResearchMenu (Control)
  Overlay (ColorRect)
  RootPanel (PanelContainer)
    MarginContainer
      HBoxContainer
        LeftColumn (VBoxContainer)
          TitleLabel (Label)
          MapGrid (GridContainer)
          StatusLabel (Label)
        RightColumn (VBoxContainer)
          MaterialLabel (Label)
          MaterialList (VBoxContainer)
          MethodLabel (Label)
          MethodList (VBoxContainer)
          PreviewLabel (Label)
          ConfirmButton (Button)
          FinishButton (Button)
          CloseButton (Button)
          LogLabel (RichTextLabel)
```

Use plain `Button`, `Label`, `PanelContainer`, and `ColorRect` nodes. Do not use final art assets in this task.

- [ ] **Step 2: Attach `BrewingResearchMenu.gd`**

Add `new_demo/scripts/ui/menus/brewing/BrewingResearchMenu.gd`:

```gdscript
extends BaseInteractionMenu

const Catalog := preload("res://scripts/systems/brewing/brewing_research_catalog.gd")
const SessionScript := preload("res://scripts/systems/brewing/brewing_research_session.gd")
const Tools := preload("res://scripts/systems/brewing/brewing_player_tools.gd")

@onready var title_label: Label = %TitleLabel
@onready var map_grid: GridContainer = %MapGrid
@onready var status_label: Label = %StatusLabel
@onready var material_list: VBoxContainer = %MaterialList
@onready var method_list: VBoxContainer = %MethodList
@onready var preview_label: Label = %PreviewLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var finish_button: Button = %FinishButton
@onready var close_button: Button = %CloseButton
@onready var log_label: RichTextLabel = %LogLabel

var session: BrewingResearchSession
var selected_material_id: String = ""
var selected_method_id: String = Catalog.METHOD_NONE
var preview_result: Dictionary = {}
var cell_buttons: Dictionary = {}

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	close_button.pressed.connect(_on_close_pressed)

func setup(id: String, menu_context := {}) -> void:
	super.setup(id, menu_context)
	var recipe_id := String(menu_context.get("recipe_id", "dungeon_mushroom"))
	session = SessionScript.new()
	session.setup(recipe_id)
	_build_map_grid()
	_build_material_buttons()
	_refresh_all()

func _build_map_grid() -> void:
	for child in map_grid.get_children():
		child.queue_free()
	cell_buttons.clear()
	var status := session.get_status()
	var size: Vector2i = status["map_size"]
	map_grid.columns = size.x
	for y in range(size.y):
		for x in range(size.x):
			var cell := Vector2i(x, y)
			var button := Button.new()
			button.custom_minimum_size = Vector2(32, 32)
			button.disabled = true
			map_grid.add_child(button)
			cell_buttons[cell] = button

func _build_material_buttons() -> void:
	for child in material_list.get_children():
		child.queue_free()
	var recipe_id := String(session.get_status()["recipe_id"])
	for material_id in Catalog.get_allowed_materials(recipe_id):
		var button := Button.new()
		button.text = MaterialDatabase.get_display_name(material_id) + " x" + str(MaterialInventory.get_item_count("backpack", material_id))
		button.pressed.connect(_select_material.bind(material_id))
		material_list.add_child(button)

func _build_method_buttons() -> void:
	for child in method_list.get_children():
		child.queue_free()
	if selected_material_id == "":
		return
	var owned_tools := Tools.get_owned_tools()
	for method_id in Catalog.get_allowed_methods(selected_material_id):
		var method := Catalog.get_method(method_id)
		var required_tool := String(method.get("required_tool", ""))
		var button := Button.new()
		button.text = String(method.get("display_name", method_id))
		button.disabled = required_tool != "" and not owned_tools.has(required_tool)
		button.pressed.connect(_select_method.bind(method_id))
		method_list.add_child(button)

func _select_material(material_id: String) -> void:
	selected_material_id = material_id
	selected_method_id = Catalog.METHOD_NONE
	_build_method_buttons()
	_update_preview()

func _select_method(method_id: String) -> void:
	selected_method_id = method_id
	_update_preview()

func _update_preview() -> void:
	if selected_material_id == "":
		preview_result = {}
		preview_label.text = "请选择材料。"
		confirm_button.disabled = true
		_refresh_map()
		return
	preview_result = session.preview_input(selected_material_id, selected_method_id, Tools.get_owned_tools())
	preview_label.text = _format_preview(preview_result)
	confirm_button.disabled = not bool(preview_result.get("ok", false))
	_refresh_map()

func _on_confirm_pressed() -> void:
	if selected_material_id == "":
		return
	if not MaterialInventory.consume_item_from_container("backpack", selected_material_id, 1):
		preview_label.text = "背包中没有足够材料。"
		return
	var result := session.commit_input(selected_material_id, selected_method_id, Tools.get_owned_tools())
	_append_log(result.get("message", ""))
	selected_material_id = ""
	selected_method_id = Catalog.METHOD_NONE
	_build_material_buttons()
	_build_method_buttons()
	_refresh_all()
	if bool(result.get("finished", false)):
		_on_research_finished(result)

func _on_finish_pressed() -> void:
	var result := session.finish()
	_on_research_finished(result)

func _on_close_pressed() -> void:
	close_menu()

func _on_research_finished(result: Dictionary) -> void:
	confirm_button.disabled = true
	finish_button.disabled = true
	if bool(result.get("success", false)):
		MaterialInventory.add_item_to_container("backpack", String(result.get("wine_id", "")), 1)
	else:
		MaterialInventory.add_item_to_container("backpack", "failed_mushroom_wine", 1)
	_append_log(result.get("message", ""))
	_refresh_all()

func _refresh_all() -> void:
	var status := session.get_status()
	title_label.text = String(status.get("display_name", "酿酒研发"))
	status_label.text = "位置 %s / 投料 %d/%d" % [
		str(status["current_position"]),
		int(status["used_inputs"]),
		int(status["max_inputs"])
	]
	_update_preview()
	_refresh_map()

func _refresh_map() -> void:
	var preview_path: Array = preview_result.get("path", [])
	var preview_cells := {}
	for cell in preview_path:
		preview_cells[cell] = true
	for cell in cell_buttons.keys():
		var button: Button = cell_buttons[cell]
		var state := session.get_cell_state(cell)
		if bool(state["is_current"]):
			button.text = "●"
		elif preview_cells.has(cell):
			button.text = "+"
		elif bool(state["revealed"]):
			button.text = "."
		else:
			button.text = "?"
```

Continue the same script:

```gdscript
		var wine_id := String(state.get("wine_id", ""))
		if bool(state["revealed"]) and wine_id != "":
			button.modulate = Color(0.9, 0.75, 0.25)
		elif bool(state["is_current"]):
			button.modulate = Color(0.35, 0.9, 0.9)
		elif preview_cells.has(cell):
			button.modulate = Color(0.45, 0.7, 1.0)
		elif bool(state["revealed"]):
			button.modulate = Color(0.7, 0.7, 0.7)
		else:
			button.modulate = Color(0.2, 0.2, 0.2)

func _format_preview(result: Dictionary) -> String:
	if selected_material_id == "":
		return "请选择材料。"
	var material_name := MaterialDatabase.get_display_name(selected_material_id)
	var method_name := String(Catalog.get_method(selected_method_id).get("display_name", selected_method_id))
	if not bool(result.get("ok", false)):
		return "%s + %s：%s" % [material_name, method_name, String(result.get("message", ""))]
	return "%s + %s：终点 %s" % [material_name, method_name, str(result.get("end_position", Vector2i.ZERO))]

func _append_log(text: String) -> void:
	if text == "":
		return
	log_label.append_text(text + "\n")
```

- [ ] **Step 3: Build the `.tscn` with unique names**

In Godot editor, mark these nodes as unique names:

```text
TitleLabel
MapGrid
StatusLabel
MaterialList
MethodList
PreviewLabel
ConfirmButton
FinishButton
CloseButton
LogLabel
```

- [ ] **Step 4: Manual UI verification**

Open `BrewingResearchMenu.tscn` in Godot.

Expected:
- Scene opens without missing node errors.
- Grid area can fit 11 columns.
- Buttons can be resized later without changing session code.

---

### Task 6: Register and Open the Research Menu

**Files:**
- Modify: `new_demo/scripts/ui/MenuManager.gd`
- Modify: `new_demo/scripts/ui/menus/BrewingMenu.gd`

**Interfaces:**
- Consumes:
  - `MenuManager.open_menu(menu_id: String, context := {}) -> Control`
- Produces:
  - Brewing barrel start button opens research menu with `recipe_id = "dungeon_mushroom"`.

- [ ] **Step 1: Register new menu id**

Modify `MenuManager.menu_registry`:

```gdscript
var menu_registry := {
	"brewing_barrel": preload("res://scenes/ui/menus/brewing/BrewingMenu.tscn"),
	"brewing_research": preload("res://scenes/ui/menus/brewing/BrewingResearchMenu.tscn"),
	"warehouse": preload("res://scenes/ui/menus/storage/WarehouseMenu.tscn"),
	"task_confirm": preload("res://scenes/ui/menus/task_confirm/TaskConfirmMenu.tscn")
}
```

- [ ] **Step 2: Open research from brewing menu**

Modify `BrewingMenu._on_start_button_pressed()`:

```gdscript
func _on_start_button_pressed() -> void:
	MenuManager.open_menu("brewing_research", {
		"recipe_id": "dungeon_mushroom"
	})
```

- [ ] **Step 3: Keep recipe button simple**

Leave `_on_recipe_button_pressed()` as an emitted action for now, or change it to a status message later. Do not implement full recipe book in this pass.

- [ ] **Step 4: Manual integration verification**

Run the project, interact with the brewing barrel, click start.

Expected:
- Old brewing menu closes.
- New research menu opens.
- Map starts at `(5,5)`.
- Selecting a material shows a path preview.

---

### Task 7: Add First Version Result Handling

**Files:**
- Modify: `new_demo/scripts/ui/menus/brewing/BrewingResearchMenu.gd`

**Interfaces:**
- Consumes:
  - `session.commit_input(...) -> Dictionary`
  - `session.finish() -> Dictionary`
  - `MaterialInventory.add_item_to_container(...)`
- Produces:
  - Success adds discovered wine to backpack.
  - Failure adds `failed_mushroom_wine` to backpack.
  - UI prevents further input after result.

- [ ] **Step 1: Confirm success route**

Use this route to reach upper-left wine zone:

```text
Start: (5,5)
cave_red_mushroom + grind -> (5,3)
cave_blue_mushroom + grind -> (3,3)
cave_red_mushroom + none -> (3,2)
cave_blue_mushroom + none -> (2,2)
```

Expected: session returns success with `glowing_mushroom_wine`.

- [ ] **Step 2: Confirm lower-right route**

Use this route to reach lower-right wine zone:

```text
Start: (5,5)
cave_red_mushroom + bake -> (5,6)
cave_red_mushroom + bake -> (5,7)
cave_red_mushroom + bake -> (5,8)
cave_blue_mushroom + bake -> (6,8)
cave_blue_mushroom + grind + bake is not supported in first version
```

If lower-right is not reachable in 5 commits with current methods, make one of these scoped adjustments:

```text
Option A: temporarily allow bake to reverse and extend to two steps.
Option B: add a second method id bake_strong requiring oven.
Option C: move lower-right wine zone to (7,8) for the first version.
```

Use Option A for first implementation because it stays closest to the current design. Implement bake as a two-step reverse route for first version:

```gdscript
static func _reverse_route(base_route: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for step in base_route:
		var reversed := Vector2i(-step.x, -step.y)
		result.append(reversed)
		result.append(reversed)
	return result
```

- [ ] **Step 3: Confirm failure route**

Use five `water + none` commits or finish immediately.

Expected:
- Result is `failed_mushroom_wine`.
- UI disables confirm and finish buttons.
- Backpack receives one failed wine item.

---

### Task 8: Keep UI Asset-Swappable

**Files:**
- Modify: `new_demo/scenes/ui/menus/brewing/BrewingResearchMenu.tscn`
- Modify: `new_demo/scripts/ui/menus/brewing/BrewingResearchMenu.gd`

**Interfaces:**
- Produces:
  - UI logic uses node references and status states, not final art.
  - Later art replacement can be done by replacing Button themes, icons, or cell scenes.

- [ ] **Step 1: Use semantic colors only**

Keep first-version cell state colors limited to:

```text
Unknown: dark gray
Revealed: gray
Preview path: blue
Current position: cyan
Revealed wine zone: gold
```

- [ ] **Step 2: Avoid texture dependencies**

Do not require material icons for this pass. If `MaterialDatabase.get_icon_path()` returns empty, show text-only buttons.

- [ ] **Step 3: Make map cell replacement easy**

Keep all cell rendering inside `_refresh_map()`. Do not spread cell color/text logic across material button handlers.

- [ ] **Step 4: Manual resize check**

Run at default window size. Confirm:

- 11x11 grid is visible.
- Right-side material and method lists are visible.
- Confirm and finish buttons are visible.
- Log text does not cover the map.

---

## Out of Scope for First Version

- Shop purchase flow for grinder and oven.
- Permanent discovered recipe save data.
- Multiple recipe maps.
- 90-degree rotation processing.
- Danger zones and special zones.
- Optimal recipe cost scoring.
- Final customer/order integration.
- Polished art assets.
- Animation for indicator movement. First version can update position instantly.

## Final Manual Test Script

After all tasks are implemented, verify this flow in the Godot editor:

1. Run the project.
2. Open the brewing barrel menu.
3. Click start brewing.
4. Confirm the research menu opens.
5. Select cave red mushroom and grind.
6. Confirm input.
7. Confirm the current position moves upward and revealed cells update.
8. Select cave blue mushroom and grind.
9. Confirm input.
10. Continue toward the upper-left 2x2 wine zone.
11. Confirm success adds one discovered wine to backpack.
12. Restart research and click finish immediately.
13. Confirm failure adds one failed mushroom wine to backpack.

## Self-Review

- Spec coverage: The plan covers object creation, object responsibilities, first-version UI, map size, start position, wine zones, material restrictions, processing methods, tool gates, route preview, commit flow, success, and failure.
- Scope control: Advanced systems are explicitly out of scope and are not required for first implementation.
- Type consistency: Catalog methods, session methods, and UI calls use the same method names and ids across tasks.
- Implementation risk: The lower-right wine zone needs bake to move two cells per commit or it may not be reachable within five commits. The plan resolves this by making first-version bake a two-step reverse route.
