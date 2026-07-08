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
